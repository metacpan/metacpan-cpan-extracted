package Pcore::Dist::Build::Docker;

use Pcore -class, -ansi;
use Pcore::API::DockerHub;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

around new => sub ( $orig, $self, $args ) {
    return if !$args->{dist}->docker;

    return $self->$orig($args);
};

sub run ( $self, $args ) {
    return $self->update_from_tag( $args->{from} ) if $args->{from};

    my $dockerhub_api = Pcore::API::DockerHub->new( { namespace => $self->dist->docker->{namespace} } );

    my $dockerhub_repo = $dockerhub_api->get_repo( $self->dist->docker->{repo_name} );

    $self->create_build_tag( $dockerhub_repo, $args->{create} ) if $args->{create};

    $self->remove_tag( $dockerhub_repo, $args->{remove} ) if $args->{remove};

    $self->trigger_build( $dockerhub_repo, $args->{trigger} ) if $args->{trigger};

    $self->report($dockerhub_repo);

    return;
}

sub report ( $self, $dockerhub_repo ) {
    my $cv = AE::cv;

    my ( $tags, $build_history, $build_settings );

    $cv->begin;
    $dockerhub_repo->tags(
        cb => sub ($res) {
            $tags = $res;

            $cv->end;

            return;
        }
    );

    $cv->begin;
    $dockerhub_repo->build_history(
        cb => sub ($res) {
            $build_history = $res;

            $cv->end;

            return;
        }
    );

    $cv->begin;
    $dockerhub_repo->build_settings(
        cb => sub ($res) {
            $build_settings = $res;

            $cv->end;

            return;
        }
    );

    $cv->recv;

    my $tbl = P->text->table(
        cols => [
            tag => {
                title => 'TAG NAME',
                width => 15,
            },
            is_build_tag => {
                title  => "BUILD\nTAG",
                width  => 7,
                align  => 1,
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
            build_status => {
                title  => 'LATEST BUILD STATUS',
                width  => 15,
                format => sub ( $val, $id, $row ) {
                    return $val || q[-];
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
        $report->{ $tag->name } = {
            size         => $tag->full_size,
            last_updated => $tag->last_updated,
        };
    }

    # index build tags
    for my $build_tag ( values $build_settings->{data}->{build_tags}->%* ) {
        $report->{ $build_tag->name }->{is_build_tag} = 1 if $build_tag->name ne '{sourceref}';
    }

    # index builds
    for my $build ( $build_history->{data}->@* ) {
        if ( !exists $report->{ $build->dockertag_name }->{build_status} ) {
            if ( $build->build_status_name eq 'Error' ) {
                $report->{ $build->dockertag_name }->{build_status} = $BOLD . $WHITE . $ON_RED;
            }
            elsif ( $build->build_status_name eq 'Success' ) {
                $report->{ $build->dockertag_name }->{build_status} = $BLACK . $ON_GREEN;
            }
            else {
                $report->{ $build->dockertag_name }->{build_status} = $BLACK . $ON_WHITE;
            }

            $report->{ $build->dockertag_name }->{build_status} .= q[ ] . $build->build_status_name . q[ ] . $RESET;

            $report->{ $build->dockertag_name }->{build_status_updated} = $build->last_updated;
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

sub update_from_tag ( $self, $tag ) {
    my $dockerfile = P->file->read_bin( $self->dist->root . 'Dockerfile' );

    if ( $dockerfile->$* =~ s/^FROM\s+([^:]+)(.*?)$/FROM $1:$tag/sm ) {
        if ( "$1$2" eq "$1:$tag" ) {
            say qq[Docker base image wasn't changed];
        }
        else {
            P->file->write_bin( $self->dist->root . 'Dockerfile', $dockerfile );

            {
                # cd to repo root
                my $chdir_guard = P->file->chdir( $self->dist->root );

                my $res = $self->dist->scm->scm_commit( qq[Docker base image changed from "$1$2" to "$1:$tag"], 'Dockerfile' );

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

sub create_build_tag ( $self, $dockerhub_repo, $tag ) {
    print qq[Creating build tag "$tag" ... ];

    my $build_settings = $dockerhub_repo->build_settings;

    if ( !$build_settings ) {
        say $build_settings->reason;
    }
    else {
        for ( values $build_settings->{data}->{build_tags}->%* ) {
            if ( $_->name eq $tag || $_->source_name eq $tag ) {
                say q[tag already exists];

                return 1;
            }
        }
    }

    my $res = $dockerhub_repo->create_build_tag( name => $tag, source_name => $tag );

    if ( $res->status ) {
        say 'OK';

        return 1;
    }
    else {
        say $res->reason;

        return 0;
    }
}

sub trigger_build ( $self, $dockerhub_repo, $tag ) {
    print qq[Triggering build for tag "$tag" ... ];

    my $res = $dockerhub_repo->trigger_build($tag);

    if ( $res->is_success ) {
        say 'OK';

        return 1;
    }
    else {
        say $res->reason;

        return 0;
    }
}

sub remove_tag ( $self, $dockerhub_repo, $tag ) {
    print qq[Removing tag "$tag" ... ];

    my $tags = $dockerhub_repo->tags;

    if ( !$tags->{data}->{$tag} ) {
        say 'Tag does not exists';
    }
    else {
        my $res = $tags->{data}->{$tag}->remove;

        say $res->status ? 'OK' : $res->reason;
    }

    # remove build tag
    print qq[Removing build tag "$tag" ... ];

    my $build_settings = $dockerhub_repo->build_settings;

    if ( !$build_settings ) {
        say $build_settings->reason;
    }
    else {
        my $build_tag;

        for ( values $build_settings->{data}->{build_tags}->%* ) {
            if ( $_->name eq $tag ) {
                $build_tag = $_;

                last;
            }
        }

        if ( !$build_tag ) {
            say 'Tag does not exists';
        }
        else {
            my $res1 = $build_tag->remove;

            say $res1->status ? 'OK' : $res1->reason;
        }
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 32                   | Subroutines::ProhibitExcessComplexity - Subroutine "report" with high complexity score (23)                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 209                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
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
