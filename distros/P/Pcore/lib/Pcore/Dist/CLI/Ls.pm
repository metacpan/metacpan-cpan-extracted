package Pcore::Dist::CLI::Ls;

use Pcore -class, -ansi;

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'list installed distributions' };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dists;

    for my $dir ( P->file->read_dir( $ENV{PCORE_LIB}, full_path => 1 )->@* ) {
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
                release => {
                    title => "CURRENT\nRELEASE",
                    width => 14,
                    align => 1,
                },
                unreleased => {
                    title => "UNRELEASED\nCHANGES",
                    width => 12,
                    align => 1,
                },
                uncommited => {
                    width => 14,
                    align => 1,
                },
                pushed => {
                    width => 14,
                    align => 1,
                },
            ],
        );

        print $tbl->render_header;

        for my $dist ( sort { $a->name cmp $b->name } $dists->@* ) {
            my @row;

            push @row, $dist->name;

            if ( $dist->id->{release} eq 'v0.0.0' ) {
                push @row, WHITE . ON_RED . ' unreleased ' . RESET;
            }
            else {
                push @row, $dist->id->{release};
            }

            if ( $dist->id->{release_distance} ) {
                push @row, WHITE . ON_RED . sprintf( ' %3s ', $dist->id->{release_distance} ) . RESET;
            }
            else {
                push @row, q[ - ];
            }

            if ( !$dist->is_commited ) {
                push @row, WHITE . ON_RED . ' uncommited ' . RESET;
            }
            else {
                push @row, q[ - ];
            }

            if ( $dist->id->{phase} ) {
                if ( lc $dist->id->{phase} eq 'public' ) {
                    push @row, q[ - ];
                }
                else {
                    push @row, WHITE . ON_RED . q[ ] . $dist->id->{phase} . q[ ] . RESET;
                }
            }
            else {
                push @row, q[ - ];
            }

            print $tbl->render_row( \@row );
        }

        print $tbl->finish;
    }

    return;
}

sub run ( $self ) {
    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Ls - list installed ditributions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
