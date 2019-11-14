package Pcore::Dist::Build::Docker;

use Pcore -class, -ansi, -res;
use Pcore::Lib::Scalar qw[is_plain_arrayref];

has dist => ();                                     # InstanceOf ['Pcore::Dist']
has api  => ( is => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::API::Docker::Hub']

sub _build_api($self) {
    require Pcore::API::Docker::Hub;

    return Pcore::API::Docker::Hub->new;
}

sub init ( $self, $args ) {
    if ( $self->{dist}->docker ) {
        say qq[Docker profile is already created "$self->{dist}->{docker}->{repo_id}".];

        exit 3;
    }

    my $git_upstream = $self->{dist}->git ? $self->{dist}->git->upstream : undef;

    if ( !$git_upstream ) {
        say 'Dist has no upstream repository.';

        exit 3;
    }

    my $repo_namespace = $args->{namespace} || $ENV->user_cfg->{DOCKERHUB}->{default_namespace} || $ENV->user_cfg->{DOCKERHUB}->{username};

    if ( !$repo_namespace ) {
        say 'DockerHub repo namespace is not defined.';

        exit 3;
    }

    my $repo_name = $args->{name} || lc $self->{dist}->name;

    my $repo_id = "$repo_namespace/$repo_name";

    # my $confirm = P->term->prompt( qq[Create DockerHub repository "$repo_id"?], [qw[yes no cancel]], enter => 1 );

    # if ( $confirm eq 'cancel' ) {
    #     exit 3;
    # }
    # elsif ( $confirm eq 'yes' ) {
    #     my $api = $self->api;

    #     print q[Creating DockerHub repository ... ];

    #     my $res = $api->create_repo(
    #         $repo_id,
    #         desc      => $self->{dist}->module->abstract || $self->{dist}->name,
    #         full_desc => $EMPTY,
    #         private   => 0,
    #     );

    #     say $res->{reason};

    #     exit 3 if !$res->is_success;
    # }

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

    say qq[Docker profile created "$repo_namespace/$repo_name".];

    return;
}

sub set_from_tag ( $self, $tag ) {
    my $path = "$self->{dist}->{root}/Dockerfile";

    if ( !-f $path ) {
        say q[Dockerfile is not exists.];

        exit 1;
    }

    my $dockerfile = P->file->read_bin($path);

    if ( !defined $tag ) {
        $dockerfile =~ /^FROM\s+([[:alnum:]\/_-]+)(?::([[:alnum:]._-]+))?\s*$/sm;

        say qq[Docker base image is "$1:@{[ $2 // $EMPTY ]}"];
    }
    elsif ( $dockerfile =~ s/^FROM\s+([[:alnum:]\/_-]+)(?::([[:alnum:]._-]+))?\s*$/FROM $1:$tag\n/sm ) {
        if ( "$1:$2" eq "$1:$tag" ) {
            say q[Docker base image wasn't changed];
        }
        else {
            P->file->write_bin( $path, $dockerfile );

            {
                # cd to repo root
                my $chdir_guard = P->file->chdir( $self->{dist}->{root} );

                my $res = $self->{dist}->git->git_run(qq[commit -m"Docker base image changed from \\"$1:$2\\" to \\"$1:$tag\\"" Dockerfile]);

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
    require Pcore::API::Git;
    require Pcore::API::Docker::Engine;

    my $res;

    my $dist = $self->{dist};

    if ( !$dist->docker ) {
        $res = res [ 400, 'Docker profile was not found.' ];
        say $res;
        return $res;
    }

    if ( !$dist->id->{hash} ) {
        $res = res [ 500, 'Unable to identify current changeset.' ];
        say $res;
        return $res;
    }

    my ( $clone_root, $repo );

    if ( defined $tag ) {
        print 'Cloning ... ';

        $clone_root = P->file1->tempdir;

        # my $res = Pcore::API::Git->git_run( [ 'clone', $dist->git->upstream->get_clone_url, $clone_root ], undef );
        $res = Pcore::API::Git->git_run( [ 'clone', '--quiet', $dist->{root}, $clone_root, '--branch', $tag ], undef );
        say $res;
        return $res if !$res;

        $repo = Pcore::Dist->new($clone_root);
    }
    else {
        $repo = $dist;
    }

    # create build tags
    my $id      = $repo->id;
    my $repo_id = $dist->docker->{repo_id};

    my @tags;
    my $is_dirty = $id->{is_dirty} ? '.dirty' : $EMPTY;
    @tags = map {"$repo_id:${_}${is_dirty}"} grep {defined} $id->{branch}, $id->{tags}->@* if defined $tag;
    push @tags, "$repo_id:$id->{hash_short}${is_dirty}" if !@tags;

    for my $tag (@tags) {
        say "Tag: $tag";
    }

    my $dockerignore = $self->_build_dockerignore("$repo->{root}/.dockerignore");

    print 'Comressing image source ... ';
    my $tar = do {
        require Archive::Tar;

        my $_tar = Archive::Tar->new;

        for my $path ( $repo->{root}->read_dir( max_depth => 0, is_dir => 0 )->@* ) {
            next if $dockerignore->($path);

            my $mode;

            if ( $path =~ m[\A(script|t)/]sm ) {
                $mode = P->file->calc_chmod('rwxr-xr-x');
            }
            else {
                $mode = P->file->calc_chmod('rw-r--r--');
            }

            $_tar->add_data( "$path", P->file->read_bin("$repo->{root}/$path"), { mode => $mode } );
        }

        # add dist-id.yaml
        $_tar->add_data( 'share/dist-id.yaml', P->data->to_yaml($id), { mode => P->file->calc_chmod('rw-r--r--') } );

        $_tar->write;
    };
    say 'done';

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

    # remove by image id
    if ( $args->{remove} ) {
        print qq[Removing image "$res->{data}" ... ];
        $res = $docker->image_remove( $res->{data}, 1 );
        say $res;

    }

    return res 200;
}

sub _build_dockerignore ( $self, $path ) {
    my ( $exclude, $include );

    # https://docs.docker.com/engine/reference/builder/#dockerignore-file
    if ( -f $path ) {
        my ( @exclude, @include );

        for my $line ( P->file->read_lines($path)->@* ) {

            # trim spaces
            $line =~ s/(?:\A\s+|\s+\z)//smg;

            # remove leading "/"
            $line =~ s[\A/][]sm;

            # skip empty line
            next if $line eq $EMPTY;

            # skip comments
            next if $line =~ /\A#/sm;

            my $pattern = quotemeta $line;

            # "**" = zero or more number of directories
            $pattern =~ s[\\[*]\\[*]][.*]smg;

            # "?" = any character, excluding "/"
            $pattern =~ s[\\[?]][[^/]]smg;

            # "*" = any substring, excluding "/"
            $pattern =~ s[\\[*]][[^/]*]smg;

            # if pattern started with "!" - this is "including" pattern
            if ( substr( $line, 0, 2 ) eq '\!' ) {
                substr $line, 0, 2, $EMPTY;

                push @include, $pattern;
            }

            # otherwise this is "excluding" pattern
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
