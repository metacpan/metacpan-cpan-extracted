package Pcore::Dist::Build::Docker;

use Pcore -class, -ansi;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'] );
has dockerhub_api => ( is => 'lazy', isa => InstanceOf ['Pcore::API::DockerHub'], init_arg => undef );

sub _build_dockerhub_api($self) {
    return Pcore::API::DockerHub->new;
}

sub init ( $self, $args ) {
    if ( $self->{dist}->docker ) {
        say qq[Dist is already linked to "$self->{dist}->{docker}->{repo_id}"];

        exit 3;
    }

    my $scm_upstream = $self->dist->scm ? $self->dist->scm->upstream : undef;

    if ( !$scm_upstream ) {
        say qq[Dist has no upstream repository"];

        exit 3;
    }

    my $repo_namespace = $args->{namespace} || $ENV->user_cfg->{DOCKERHUB}->{default_namespace} || $ENV->user_cfg->{DOCKERHUB}->{username};

    if ( !$repo_namespace ) {
        say 'DockerHub repo namespace is not defined';

        exit 3;
    }

    my $repo_name = $args->{name} || lc $self->dist->name;

    my $repo_id = "$repo_namespace/$repo_name";

    my $confirm = P->term->prompt( qq[Create DockerHub repository "$repo_id"?], [qw[yes no]], enter => 1 );

    if ( $confirm eq 'no' ) {
        exit 3;
    }

    my $api = $self->dockerhub_api;

    print q[Creating DockerHub repository ... ];

    my $res = $api->create_autobuild(
        $repo_id,
        $scm_upstream->{hosting},
        $scm_upstream->{repo_id},
        $self->dist->module->abstract || $self->dist->name,
        private => 0,
        active  => 1
    );

    say $res->reason;

    if ( !$res->is_success ) {
        exit 3;
    }
    else {
        require Pcore::Util::File::Tree;

        # copy files
        my $files = Pcore::Util::File::Tree->new;

        $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/docker/' );

        $files->render_tmpl(
            {   author                        => $self->dist->cfg->{author},
                dist_path                     => lc $self->dist->name,
                dockerhub_dist_repo_namespace => $repo_namespace,
                dockerhub_dist_repo_name      => $repo_name,
                dockerhub_pcore_repo_id       => $ENV->pcore->docker->{repo_id},
            }
        );

        $files->write_to( $self->dist->root );
    }

    return;
}

sub set_from_tag ( $self, $tag ) {
    my $dockerfile = P->file->read_bin( $self->dist->root . 'Dockerfile' );

    if ( $dockerfile->$* =~ s/^FROM\s+([^:]+)(.*?)$/FROM $1:$tag/sm ) {
        if ( "$1$2" eq "$1:$tag" ) {
            say q[Docker base image wasn't changed];
        }
        else {
            P->file->write_bin( $self->dist->root . 'Dockerfile', $dockerfile );

            {
                # cd to repo root
                my $chdir_guard = P->file->chdir( $self->dist->root );

                my $res = $self->dist->scm->scm_commit( qq[Docker base image changed from "$1$2" to "$1:$tag"], ['Dockerfile'] );

                die "$res" if !$res;
            }

            $self->dist->clear_docker;

            say qq[Docker base image changed from "$1$2" to "$1:$tag"];
        }
    }
    else {
        say q[Error updating docker base image];
    }

    return;
}

sub status ( $self ) {
    my ( $tags, $build_history, $build_settings );

    my $cv = AE::cv;

    $cv->begin;

    $cv->begin;
    $self->dockerhub_api->get_tags(
        $self->dist->docker->{repo_id},
        sub ($res) {
            $tags = $res;

            $cv->end;

            return;
        }
    );

    $cv->begin;
    $self->dockerhub_api->get_build_history(
        $self->dist->docker->{repo_id},
        sub ($res) {
            $build_history = $res;

            $cv->end;

            return;
        }
    );

    $cv->begin;
    $self->dockerhub_api->get_autobuild_settings(
        $self->dist->docker->{repo_id},
        sub ($res) {
            $build_settings = $res;

            $cv->end;

            return;
        }
    );

    $cv->end;

    $cv->recv;

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

                    my $now = P->date->now_utc;

                    my $date = P->date->from_string($val);

                    my $delta_minutes = $date->delta_minutes($now);

                    my $minutes = $delta_minutes % 60;

                    my $delta_hours = int( $delta_minutes / 60 );

                    my $hours = $delta_hours % 24;

                    my $days = int( $delta_hours / 24 );

                    my $res = q[];

                    $res .= "$days days " if $days;

                    $res .= "$hours hours " if $hours;

                    return "${res}$minutes minutes ago";
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
    for my $build ( sort { $b->{id} <=> $a->{id} } values $build_history->{data}->%* ) {
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

        say 'NOTE: if build tag is not set - repository will not be builded automatically, when build link will be updated';
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

    my $cv = AE::cv;

    $cv->begin;

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

    $cv->end;

    $cv->recv;

    return if !$repos;

    my ( $build_history, $autobuild_tags );

    $cv = AE::cv;

    $cv->begin;

    for my $repo_id ( $repos->@* ) {
        $cv->begin;
        $self->dockerhub_api->get_build_history(
            $repo_id,
            sub ($res) {
                if ( $res && $res->{data} ) {
                    for my $autobuild ( sort { $b->{id} <=> $a->{id} } values $res->{data}->%* ) {
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

    $cv->end;

    $cv->recv;

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

                    my $res = q[];

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

    $report2 = [ sort { $b->{created_date} cmp $a->{created_date} } $report2->@* ];

    print $tbl->render_all( [ $report1->@*, $report2->@*, $report3->@* ] );

    return;
}

sub create_tag ( $self, $tag_name, $source_name, $source_type, $dockerfile_location ) {
    print qq[Creating autobuild tag "$tag_name" ... ];

    my $autobuild_tags = $self->dockerhub_api->get_autobuild_tags( $self->dist->docker->{repo_id} );

    if ( !$autobuild_tags ) {
        say $autobuild_tags->reason;
    }
    else {
        for my $autobuild_tag ( values $autobuild_tags->{data}->%* ) {
            if ( $autobuild_tag->{name} eq $tag_name ) {
                say q[tag already exists];

                return $autobuild_tag;
            }
        }
    }

    my $res = $self->dockerhub_api->create_autobuild_tag( $self->dist->docker->{repo_id}, $tag_name, $source_name, $source_type, $dockerfile_location );

    say $res;

    return $res;
}

sub remove_tag ( $self, $tag ) {
    print qq[Removing tag "$tag" ... ];

    my $res = $self->dockerhub_api->unlink_tag( $self->dist->docker->{repo_id}, $tag );

    say $res;

    return $res;
}

sub trigger_build ( $self, $tag ) {
    print qq[Triggering build for tag "$tag" ... ];

    my $res = $self->dockerhub_api->trigger_autobuild_by_tag_name( $self->dist->docker->{repo_id}, $tag );

    say $res;

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 22                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 117                  | * Subroutine "status" with high complexity score (25)                                                          |
## |      | 301                  | * Subroutine "build_status" with high complexity score (31)                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 486                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 270, 349, 479        | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
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
