package Pcore::Dist::Build::Docker;

use Pcore -class, -ansi, -res;
use Pcore::Util::Scalar qw[is_plain_arrayref];

has dist          => ();                                     # InstanceOf ['Pcore::Dist']
has dockerhub_api => ( is => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::API::Docker::Hub']

sub _build_dockerhub_api($self) {
    return Pcore::API::Docker::Hub->new;
}

sub init ( $self, $args ) {
    if ( $self->{dist}->docker ) {
        say qq[Dist is already linked to "$self->{dist}->{docker}->{repo_id}"];

        exit 3;
    }

    my $scm_upstream = $self->{dist}->scm ? $self->{dist}->scm->upstream : undef;

    if ( !$scm_upstream ) {
        say q[Dist has no upstream repository];

        exit 3;
    }

    my $repo_namespace = $args->{namespace} || $ENV->user_cfg->{DOCKERHUB}->{default_namespace} || $ENV->user_cfg->{DOCKERHUB}->{username};

    if ( !$repo_namespace ) {
        say 'DockerHub repo namespace is not defined';

        exit 3;
    }

    my $repo_name = $args->{name} || lc $self->{dist}->name;

    my $repo_id = "$repo_namespace/$repo_name";

    my $confirm = P->term->prompt( qq[Create DockerHub repository "$repo_id"?], [qw[yes no cancel]], enter => 1 );

    if ( $confirm eq 'cancel' ) {
        exit 3;
    }
    elsif ( $confirm eq 'yes' ) {
        my $api = $self->dockerhub_api;

        print q[Creating DockerHub repository ... ];

        my $res = $api->create_autobuild(
            $repo_id,
            $scm_upstream->{hosting},
            $scm_upstream->{repo_id},
            $self->{dist}->module->abstract || $self->{dist}->name,
            private => 0,
            active  => 1
        );

        say $res->{reason};

        exit 3 if !$res->is_success;
    }

    require Pcore::Util::File::Tree;

    # copy files
    my $files = Pcore::Util::File::Tree->new;

    $files->add_dir( $ENV->{share}->get_location('/Pcore/dist-tmpl') . '/docker/' );

    # do not overwrite Dockerfile
    $files->remove_file('Dockerfile') if -f "$self->{dist}->{root}/Dockerfile";

    $files->move_tree( '__dist_name__', lc $self->{dist}->name );

    $files->render_tmpl( {
        author                        => $self->{dist}->cfg->{author},
        dist_path                     => lc $self->{dist}->name,
        dockerhub_dist_repo_namespace => $repo_namespace,
        dockerhub_dist_repo_name      => $repo_name,
        dockerhub_pcore_repo_id       => $ENV->{pcore}->docker->{repo_id},
    } );

    $files->write_to( $self->{dist}->{root} );

    return;
}

sub set_from_tag ( $self, $tag ) {
    my $dockerfile = P->file->read_bin("$self->{dist}->{root}/Dockerfile");

    if ( !defined $tag ) {
        $dockerfile =~ /^FROM\s+([^:]+)(.*?)$/sm;

        say qq[Docker base image is "$1$2"];
    }
    elsif ( $dockerfile =~ s/^FROM\s+([^:]+)(.*?)$/FROM $1:$tag/sm ) {
        if ( "$1$2" eq "$1:$tag" ) {
            say q[Docker base image wasn't changed];
        }
        else {
            P->file->write_bin( "$self->{dist}->{root}/Dockerfile", $dockerfile );

            {
                # cd to repo root
                my $chdir_guard = P->file->chdir( $self->{dist}->{root} );

                my $res = $self->{dist}->scm->scm_commit( qq[Docker base image changed from "$1$2" to "$1:$tag"], ['Dockerfile'] );

                die "$res" if !$res;
            }

            delete $self->{dist}->{docker};

            say qq[Docker base image changed from "$1$2" to "$1:$tag"];
        }
    }
    else {
        say 'Error updating docker base image';
    }

    return;
}

sub status ( $self ) {
    my ( $tags, $build_history, $build_settings );

    my $cv = P->cv->begin;

    $cv->begin;
    $self->dockerhub_api->get_tags(
        $self->{dist}->docker->{repo_id},
        sub ($res) {
            $tags = $res;

            $cv->end;

            return;
        }
    );

    $cv->begin;
    $self->dockerhub_api->get_build_history(
        $self->{dist}->docker->{repo_id},
        sub ($res) {
            $build_history = $res;

            $cv->end;

            return;
        }
    );

    $cv->begin;
    $self->dockerhub_api->get_autobuild_settings(
        $self->{dist}->docker->{repo_id},
        sub ($res) {
            $build_settings = $res;

            $cv->end;

            return;
        }
    );

    $cv->end->recv;

    my $tbl = P->text->table(
        cols => [
            tag => {
                title => 'TAG NAME',
                width => 15,
            },
            is_autobuild_tag => {
                title  => "AUTOBUILD\nTAG",
                width  => 11,
                align  => -1,
                format => sub ( $val, $id, $row ) {
                    if ( !$val ) {
                        return $BOLD . $WHITE . $ON_RED . ' no ' . $RESET;
                    }
                    else {
                        return $BLACK . $ON_GREEN . q[ yes ] . $RESET;
                    }
                }
            },
            size => {
                title  => 'IMAGE SIZE',
                width  => 15,
                align  => 1,
                format => sub ( $val, $id, $row ) {
                    return $val ? P->text->add_num_sep($val) : q[-];
                }
            },
            last_updated => {
                title  => 'IMAGE LAST UPDATED',
                width  => 35,
                align  => 1,
                format => sub ( $val, $id, $row ) {
                    return $val ? P->date->from_string($val)->to_http_date : q[-];
                }
            },
            status_text => {
                title  => 'LATEST BUILD STATUS',
                width  => 15,
                format => sub ( $val, $id, $row ) {
                    return if !defined $val;

                    if ( $val eq 'error' || $val eq 'cancelled' ) {
                        $val = $BOLD . $WHITE . $ON_RED . " $val " . $RESET;
                    }
                    elsif ( $val eq 'success' ) {
                        $val = $BLACK . $ON_GREEN . " $val " . $RESET;
                    }
                    elsif ( $val eq 'queued' ) {
                        $val = $BLACK . $ON_YELLOW . " $val " . $RESET;
                    }
                    else {
                        $val = $BLACK . $ON_WHITE . " $val " . $RESET;
                    }

                    return $val;
                }
            },
            build_status_updated => {
                title  => 'BUILD STATUS UPDATED',
                width  => 35,
                align  => 1,
                format => sub ( $val, $id, $row ) {
                    return q[-] if !$val;

                    my $duration = P->date->duration( P->date->from_string($val), P->date->now_utc );

                    if ( $duration->days ) {
                        return sprintf '%d days %d hours %d minutes ago', $duration->dhm->@*;
                    }
                    elsif ( $duration->hours ) {
                        return sprintf '%d hours %d minutes ago', $duration->hm->@*;
                    }
                    else {
                        return sprintf '%d minutes ago', $duration->minutes;
                    }
                }
            },
        ],
    );

    my $report;

    # index tags
    for my $tag ( values $tags->{data}->%* ) {
        $report->{ $tag->{name} } = {
            size         => $tag->{full_size},
            last_updated => $tag->{last_updated},
        };
    }

    # index autobuild tags
    for my $autobuild_tag ( $build_settings->{data}->{build_tags}->@* ) {
        $report->{ $autobuild_tag->{name} }->{is_autobuild_tag} = 1 if $autobuild_tag->{name} ne '{sourceref}';
    }

    # index builds
    for my $build ( reverse sort { $a->{id} <=> $b->{id} } values $build_history->{data}->%* ) {

        # skip build if it was completed successfully, and tag was removed
        next if $build->{status_text} eq 'success' && !exists $report->{ $build->{dockertag_name} };

        # collect only last tag build status
        if ( !exists $report->{ $build->{dockertag_name} }->{status_text} ) {
            $report->{ $build->{dockertag_name} }->{status_text} = $build->{status_text};

            $report->{ $build->{dockertag_name} }->{build_status_updated} = $build->{last_updated};
        }
    }

    if ( keys $report->%* ) {
        my $version_tags = [];

        my $named_tags = [];

        for ( keys $report->%* ) {
            $report->{$_}->{tag} = $_;

            if    (/\Av\d+[.]\d+[.]\d+\z/sm) { push $version_tags->@*, $_ }
            elsif ( $_ ne 'latest' )         { push $named_tags->@*,   $_ }
        }

        print $tbl->render_all( [ map { $report->{$_} } ( sort $version_tags->@* ), $report->{latest} ? 'latest' : (), ( sort $named_tags->@* ) ] );
    }
    else {
        say q[No docker tags were found.];
    }

    return;
}

sub build_status ( $self ) {
    my $orgs = $self->dockerhub_api->get_user_orgs;

    my $namespaces = [ $self->dockerhub_api->{username} ];

    push $namespaces->@*, keys $orgs->{data}->%* if $orgs && $orgs->{data};

    my $repos;

    my $cv = P->cv->begin;

    for my $namespace ( $namespaces->@* ) {
        $cv->begin;

        $self->dockerhub_api->get_all_repos(
            $namespace,
            sub ($res) {
                if ( $res && $res->{data} ) {
                    push $repos->@*, keys $res->{data}->%*;
                }

                $cv->end;

                return;
            }
        );
    }

    $cv->end->recv;

    return if !$repos;

    my ( $build_history, $autobuild_tags );

    $cv = P->cv->begin;

    for my $repo_id ( $repos->@* ) {
        $cv->begin;
        $self->dockerhub_api->get_build_history(
            $repo_id,
            sub ($res) {
                if ( $res && $res->{data} ) {
                    for my $autobuild ( reverse sort { $a->{id} <=> $b->{id} } values $res->{data}->%* ) {
                        my $build_id = "$repo_id:$autobuild->{dockertag_name}";

                        if ( !exists $build_history->{$build_id} ) {
                            $build_history->{$build_id} = $autobuild;

                            $autobuild->{build_id} = $build_id;
                            $autobuild->{repo_id}  = $repo_id;
                        }
                    }
                }

                $cv->end;

                return;
            }
        );

        $cv->begin;
        $self->dockerhub_api->get_autobuild_tags(
            $repo_id,
            sub ($res) {
                if ( $res && $res->{data} ) {
                    for my $autobuild_tag ( values $res->{data}->%* ) {
                        $autobuild_tags->{"$repo_id:$autobuild_tag->{name}"} = undef;
                    }
                }

                $cv->end;

                return;
            }
        );
    }

    $cv->end->recv;

    for my $repo_tag ( keys $build_history->%* ) {
        delete $build_history->{$repo_tag} if !exists $autobuild_tags->{$repo_tag};
    }

    my $tbl = P->text->table(
        cols => [
            repo_id => {
                title => 'REPO ID',
                width => 50,
            },
            dockertag_name => {
                title  => 'BUILD TAG',
                width  => 15,
                format => sub ( $val, $id, $row ) {
                    if ( $val =~ /\Av[\d.]+\z/sm ) {
                        $val = $BLACK . $ON_CYAN . " $val " . $RESET;
                    }
                    else {
                        $val = $BLACK . $ON_GREEN . " $val " . $RESET;
                    }

                    return $val;
                }
            },
            status_text => {
                title  => 'LATEST BUILD STATUS',
                width  => 15,
                format => sub ( $val, $id, $row ) {
                    if ( $val eq 'error' || $val eq 'cancelled' ) {
                        $val = $BOLD . $WHITE . $ON_RED . " $val " . $RESET;
                    }
                    elsif ( $val eq 'success' ) {
                        $val = $BLACK . $ON_GREEN . " $val " . $RESET;
                    }
                    elsif ( $val eq 'queued' ) {
                        $val = $BLACK . $ON_YELLOW . " $val " . $RESET;
                    }
                    else {
                        $val = $BLACK . $ON_WHITE . " $val " . $RESET;
                    }

                    return $val;
                }
            },
            created_date => {
                title  => 'CREATED DATE',
                width  => 35,
                align  => 1,
                format => sub ( $val, $id, $row ) {
                    return q[-] if !$val;

                    my $now = P->date->now_utc;

                    my $date = P->date->from_string($val);

                    my $delta_minutes = $date->delta_minutes($now);

                    my $minutes = $delta_minutes % 60;

                    my $delta_hours = int( $delta_minutes / 60 );

                    my $hours = $delta_hours % 24;

                    my $days = int( $delta_hours / 24 );

                    my $res = $EMPTY;

                    $res .= "$days days " if $days;

                    $res .= "$hours hours " if $hours;

                    return "${res}$minutes minutes ago";
                }
            },
        ],
    );

    my ( $report1, $report2, $report3 ) = ( [], [], [] );

    for my $build ( sort { $a->{created_date} cmp $b->{created_date} } values $build_history->%* ) {
        if ( $build->{status_text} eq 'building' ) {
            push $report3->@*, $build;
        }
        elsif ( $build->{status_text} eq 'queued' ) {
            push $report2->@*, $build;
        }
        else {
            push $report1->@*, $build;
        }
    }

    $report2 = [ reverse sort { $a->{created_date} cmp $b->{created_date} } $report2->@* ];

    print $tbl->render_all( [ $report1->@*, $report2->@*, $report3->@* ] );

    return;
}

sub create_tag ( $self, $tag_name, $source_name, $source_type, $dockerfile_location ) {
    print qq[Creating autobuild tag "$tag_name" ... ];

    my $autobuild_tags = $self->dockerhub_api->get_autobuild_tags( $self->{dist}->docker->{repo_id} );

    if ( !$autobuild_tags ) {
        say $autobuild_tags->{reason};
    }
    else {
        for my $autobuild_tag ( values $autobuild_tags->{data}->%* ) {
            if ( $autobuild_tag->{name} eq $tag_name ) {
                say q[tag already exists];

                return $autobuild_tag;
            }
        }
    }

    my $res = $self->dockerhub_api->create_autobuild_tag( $self->{dist}->docker->{repo_id}, $tag_name, $source_name, $source_type, $dockerfile_location );

    say $res;

    return $res;
}

sub remove_tag ( $self, $keep, $tags ) {
    my $remove = sub ($tags) {
        my $results;

        for my $tag ( is_plain_arrayref $tags ? $tags->@* : $tags ) {
            print qq[Removing tag "$tag" ... ];

            my $res = $self->dockerhub_api->unlink_tag( $self->{dist}->docker->{repo_id}, $tag );

            $results->{$tag} = $res;

            say $res;
        }

        return $results;
    };

    if ( !defined $tags ) {
        print q[Get docker tags ... ];

        $tags = $self->dockerhub_api->get_tags(
            $self->{dist}->docker->{repo_id},
            sub ($res) {
                say $res;

                if ($res) {
                    my @vers;

                    for my $tag ( values $res->{data}->%* ) {
                        push @vers, $tag->{name} if $tag->{name} =~ /v\d+[.]\d+[.]\d+/sm;
                    }

                    my $tags = [ map {"$_"} reverse sort map { version->new($_) } @vers ];

                    # keep last releases
                    splice $tags->@*, 0, $keep, ();

                    return $tags;
                }
                else {
                    return [];
                }
            }
        );
    }

    return $remove->($tags);
}

sub trigger_build ( $self, $tag ) {
    print qq[Triggering build for tag "$tag" ... ];

    my $res = $self->dockerhub_api->trigger_autobuild_by_tag_name( $self->{dist}->docker->{repo_id}, $tag );

    say $res;

    return $res;
}

sub build_local ( $self, $tag, $args ) {
    require Pcore::API::SCM;
    require Pcore::API::Docker::Engine;

    my $dist = $self->{dist};

    print 'Cloning ... ';

    # my $res = Pcore::API::SCM->scm_clone( $dist->scm->upstream->get_clone_url );
    my $res = Pcore::API::SCM->scm_clone( $dist->{root} );
    say $res;
    return $res if !$res;

    my $root = $res->{root};

    my $repo = Pcore::Dist->new($root);

    print 'Checking out ... ';
    $res = $repo->scm->scm_update($tag);
    say $res;
    return $res if !$res;

    # create duild tags
    my $id      = $repo->id;
    my $repo_id = $repo->docker->{repo_id};

    my @tags;

    for ( $id->{bookmark}->@*, $id->{tags}->@* ) {
        push @tags, "$repo_id:$_";
    }

    # add dist-id.yaml
    P->cfg->write( "$repo->{root}/share/dist-id.yaml", $id );

    my $dockerignore = $self->_build_dockerignore("$root/.dockerignore");

    my $tar = do {
        require Archive::Tar;

        my $_tar = Archive::Tar->new;

        for my $path ( $root->read_dir( max_depth => 0, is_dir => 0 )->@* ) {
            next if $dockerignore->($path);

            my $mode;

            if ( $path =~ m[\A(script|t)/]sm ) {
                $mode = P->file->calc_chmod('rwxr-xr-x');
            }
            else {
                $mode = P->file->calc_chmod('rw-r--r--');
            }

            $_tar->add_data( "$path", P->file->read_bin("$root/$path"), { mode => $mode } );
        }

        $_tar->write;
    };

    my $docker = Pcore::API::Docker::Engine->new;

    print 'Building image ... ';
    $res = $docker->image_build( $tar, \@tags );
    say $res;

    # docker image build error
    if ( !$res ) {

        # store build log
        if ( defined $res->{log} ) {
            my $logdir = "$dist->{root}/data/.build";

            P->file->mkpath($logdir) if !-d $logdir;

            P->file->write_text( "$logdir/docker-build.log", $res->{log} );
        }

        return $res;
    }

    # push images
    if ( $args->{push} ) {
        for my $tag (@tags) {
            print qq[Pushing image "$tag" ... ];
            $res = $docker->image_push($tag);
            say $res;
        }
    }

    if ( $args->{remove} ) {
        for my $tag (@tags) {
            print qq[Removing image "$tag" ... ];
            $res = $docker->image_remove($tag);
            say $res;
        }
    }

    return res 200;
}

sub _build_dockerignore ( $self, $path ) {
    my ( $exclude, $include );

    # https://docs.docker.com/engine/reference/builder/#dockerignore-file
    if ( -f $path ) {
        my ( @exclude, @include );

        for my $line ( P->file->read_lines($path)->@* ) {

            # skip comments
            next if $line =~ /\A\s*#/sm;

            my $pattern = quotemeta $line;

            $pattern =~ s[\\[?]][[^/]]smg;

            $pattern =~ s[\\[*]][[^/]*]smg;

            if ( substr( $line, 0, 2 ) eq '\!' ) {
                substr $line, 0, 2, $EMPTY;

                push @include, $pattern;
            }
            else {
                push @exclude, $pattern;
            }
        }

        if (@exclude) {
            my $pattern = join '|', @exclude;

            $exclude = qr/\A(?:$pattern)/sm;
        }

        if (@include) {
            my $pattern = join '|', @include;

            $include = qr/\A(?:$pattern)/sm;
        }
    }

    my $sub = sub ($path) {
        if ( defined $exclude && $path =~ $exclude ) {
            return 1 if !defined $include || $path !~ $include;
        }

        return;
    };

    return $sub;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 125                  | * Subroutine "status" with high complexity score (28)                                                          |
## |      | 298                  | * Subroutine "build_status" with high complexity score (31)                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 475                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Docker

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
