package Pcore::Dist::Build::Docker;

use Pcore -class, -ansi, -res;
use Pcore::Lib::Scalar qw[is_plain_arrayref];

has dist => ();                                     # InstanceOf ['Pcore::Dist']
has api  => ( is => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::API::Docker::Cloud']

sub _build_api($self) {
    require Pcore::API::Docker::Cloud;

    return Pcore::API::Docker::Cloud->new;
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

    my $repo_namespace = $args->{namespace} || $ENV->user_cfg->{DOCKER}->{default_namespace} || $ENV->user_cfg->{DOCKER}->{username};

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
        my $api = $self->api;

        print q[Creating DockerHub repository ... ];

        my $res = $api->create_repo(
            $repo_id,
            desc      => $self->{dist}->module->abstract || $self->{dist}->name,
            full_desc => $EMPTY,
            private   => 0,
        );

        say $res->{reason};

        exit 3 if !$res->is_success;
    }

    require Pcore::Lib::File::Tree;

    # copy files
    my $files = Pcore::Lib::File::Tree->new;

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
        $dockerfile =~ /^FROM\s+([[:alnum:]\/_-]+)(?::([[:alnum:]._-]+))?\s*$/sm;

        say qq[Docker base image is "$1:@{[ $2 // $EMPTY ]}"];
    }
    elsif ( $dockerfile =~ s/^FROM\s+([[:alnum:]\/_-]+)(?::([[:alnum:]._-]+))?\s*$/FROM $1:$tag\n/sm ) {
        if ( "$1:$2" eq "$1:$tag" ) {
            say q[Docker base image wasn't changed];
        }
        else {
            P->file->write_bin( "$self->{dist}->{root}/Dockerfile", $dockerfile );

            {
                # cd to repo root
                my $chdir_guard = P->file->chdir( $self->{dist}->{root} );

                my $res = $self->{dist}->scm->scm_commit( qq[Docker base image changed from "$1:$2" to "$1:$tag"], ['Dockerfile'] );

                die "$res" if !$res;
            }

            delete $self->{dist}->{docker};

            say qq[Docker base image changed from "$1:$2" to "$1:$tag"];
        }
    }
    else {
        say 'Error updating docker base image';
    }

    return;
}

sub ls ( $self ) {
    my $tags;

    my $cv = P->cv->begin;

    $cv->begin;
    $self->api->get_tags(
        $self->{dist}->docker->{repo_id},
        sub ($res) {
            $tags = $res;

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

            # is_autobuild_tag => {
            #     title  => "AUTOBUILD\nTAG",
            #     width  => 11,
            #     align  => -1,
            #     format => sub ( $val, $id, $row ) {
            #         if ( !$val ) {
            #             return $BOLD . $WHITE . $ON_RED . ' no ' . $RESET;
            #         }
            #         else {
            #             return $BLACK . $ON_GREEN . q[ yes ] . $RESET;
            #         }
            #     }
            # },
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

sub remove_tag ( $self, $keep, $tags ) {
    my $remove = sub ($tags) {
        my $results;

        my $cv = P->cv->begin;

        for my $tag ( is_plain_arrayref $tags ? $tags->@* : $tags ) {
            $cv->begin;

            $self->api->delete_tag(
                $self->{dist}->docker->{repo_id},
                $tag,
                sub($res) {
                    say qq[Removing tag "$tag" ... $res];

                    $results->{$tag} = $res;

                    $cv->end;

                    return;
                }
            );
        }

        $cv->end->recv;

        return $results;
    };

    if ( !defined $tags ) {
        print q[Get docker tags ... ];

        $tags = $self->api->get_tags(
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
            $res = $docker->image_remove( $tag, 1 );
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
