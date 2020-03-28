package Pcore::Dist::CLI::Ls;

use Pcore -class, -ansi, -res;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'list installed distributions' };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dists;

    for my $dir ( P->file->read_dir( $ENV{WORKSPACE}, full_path => 1 )->@* ) {
        if ( my $dist = Pcore::Dist->new($dir) ) {
            push $dists->@*, $dist;
        }
    }

    if ($dists) {
        my $tbl = P->text->table(
            style => 'compact',
            width => 120,
            cols  => [
                name => {
                    title => 'DIST NAME',
                    width => 35,
                    align => -1,
                },
                branch => {
                    width => 10,
                    align => 1,
                },
                is_dirty => {
                    title => 'IS DIRTY',
                    width => 10,
                    align => 1,
                },
                pushed => {
                    width => 14,
                    align => 1,
                },
                current_release => {
                    title => "CURRENT\nRELEASE",
                    width => 14,
                    align => 1,
                },
                latest_release => {
                    title => "LATEST\nRELEASE",
                    width => 14,
                    align => 1,
                },
                release_distance => {
                    title => "UNRELEASED\nCHANGES",
                    width => 12,
                    align => 1,
                },
            ],
        );

        print $tbl->render_header;

        my $order = [ map { $_->name } sort { lc $a->name cmp lc $b->name } $dists->@* ];

        my $dist_data;

        my $cv = P->cv->begin;

        my $dist_done = sub {
            if ( defined $order->[0] && exists $dist_data->{ $order->[0] } ) {
                my $res = delete $dist_data->{ shift $order->@* };

                $self->_render_dist( $tbl, $res->@* );

                __SUB__->();

                $cv->end;
            }

            return;
        };

        for my $dist ( $dists->@* ) {
            $cv->begin;

            $self->_get_dist_info(
                $dist,
                sub($data) {
                    $dist_data->{ $dist->name } = [ $dist, $data ];

                    $dist_done->();

                    return;
                }
            );
        }

        $cv->end->recv;

        print $tbl->finish;
    }

    return;
}

sub _get_dist_info ( $self, $dist, $cb ) {
    my $data;

    my $cv = P->cv->begin( sub ($cv) {
        $cb->($data);

        return;
    } );

    # dist id
    $cv->begin;
    Coro::async {
        $data->{id} = $dist->id;

        $cv->end;

        return;
    };

    # dist is pushed
    $cv->begin;
    Coro::async {
        $data->{is_pushed} = $dist->is_pushed;

        $cv->end;

        return;
    };

    # dist releases
    $cv->begin;
    Coro::async {
        $data->{releases} = $dist->releases;

        $cv->end;

        return;
    };

    $cv->end;

    return;
}

sub _render_dist ( $self, $tbl, $dist, $data ) {
    my @row;

    # dist name
    push @row, $dist->name;

    my $dist_id = $data->{id};

    # branch
    if ( defined $dist_id->{branch} ) {
        if ( $dist_id->{branch} eq 'master' ) {
            push @row, $dist_id->{branch};
        }
        else {
            push @row, $WHITE . $ON_RED . " $dist_id->{branch} " . $RESET;
        }
    }
    else {
        push @row, ' - ';
    }

    # is dirty
    push @row, !$dist_id->{is_dirty} ? ' - ' : $WHITE . $ON_RED . ' dirty ' . $RESET;

    # is pushed
    my $is_pushed = $data->{is_pushed};

    if ( !$is_pushed ) {
        push @row, q[ ERROR ];
    }
    else {
        my @has_not_pushed;

        for my $branch ( sort keys $is_pushed->%* ) {
            my $ahead = $is_pushed->{$branch};

            if ($ahead) {
                push @has_not_pushed, $WHITE . $ON_RED . $SPACE . "$branch ($ahead)" . $SPACE . $RESET;
            }
        }

        if (@has_not_pushed) {
            push @row, join "\n", @has_not_pushed;
        }
        else {
            push @row, q[ - ];
        }
    }

    # latest release
    my $latest_release = $data->{releases} ? $data->{releases}->[-1] : undef;

    # current release
    if ( defined $dist_id->{release} ) {
        if ( $dist_id->{release} eq $latest_release ) {
            push @row, $dist_id->{release};
        }
        else {
            push @row, $WHITE . $ON_RED . " $dist_id->{release} " . $RESET;
        }
    }
    else {
        push @row, $WHITE . $ON_RED . ' v0.0.0 ' . $RESET;
    }

    if ($latest_release) {
        push @row, $latest_release;
    }
    else {
        push @row, $WHITE . $ON_RED . ' v0.0.0 ' . $RESET;
    }

    # parent release distance
    push @row, !$dist_id->{release_distance} ? ' - ' : $WHITE . $ON_RED . sprintf( ' %3s ', $dist_id->{release_distance} ) . $RESET;

    print $tbl->render_row( \@row );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Ls - list installed distributions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
