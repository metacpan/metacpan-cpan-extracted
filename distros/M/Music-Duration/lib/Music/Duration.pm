package Music::Duration;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Add 32nd, 64th and tuple durations to MIDI-Perl

our $VERSION = '0.0602';
use strict;
use warnings;

use MIDI::Simple;


{
    # Set the initial duration to one below 32nd,
    my $last = 's'; # ..which is a sixteenth.

    # Add 32nd and 64th as y and x.
    for my $duration ( qw( y x ) ) {
        # Create a MIDI::Simple format note identifier.
        my $n = $duration . 'n';

        # Compute the note duration.
        $MIDI::Simple::Length{$n} = $duration eq $last
            ? 4 : $MIDI::Simple::Length{ $last . 'n' } / 2;

        # Compute the dotted duration.
        $MIDI::Simple::Length{ 'd'  . $n } = $MIDI::Simple::Length{$n}
            + $MIDI::Simple::Length{$n} / 2;

        # Compute the double-dotted duration.
        $MIDI::Simple::Length{ 'dd' . $n } = $MIDI::Simple::Length{'d' . $n}
            + $MIDI::Simple::Length{$n} / 4;

        # Compute triplet duration.
        $MIDI::Simple::Length{ 't'  . $n } = $MIDI::Simple::Length{$n} / 3 * 2;

        # Increment the last duration seen.
        $last = $duration;
    }
}


sub tuple {
    my ( $duration, $name, $factor ) = @_;
    $MIDI::Simple::Length{ $name . $duration } = $MIDI::Simple::Length{$duration} / $factor
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Duration - Add 32nd, 64th and tuple durations to MIDI-Perl

=head1 VERSION

version 0.0602

=head1 SYNOPSIS

  # Compare:
  # perl -MMIDI::Simple -MData::Dumper -e'$Data::Dumper::Sortkeys=1; print Dumper \%MIDI::Simple::Length'
  # perl -MMusic::Duration -MData::Dumper -e'$Data::Dumper::Sortkeys=1; print Dumper \%MIDI::Simple::Length'

  # In a program:
  use MIDI::Simple;
  use Music::Duration;

  Music::Duration::tuple( 'ten', 'z', 5 );

  my $black_page = MIDI::Simple->new_score();
  # ...
  n( 'zten', 'n38' ) for 1 .. 5; # 5 snares in place of an eighth note triplet

=head1 DESCRIPTION

This module adds thirty-second and sixty-fourth note divisions to
L<MIDI::Simple>.  It also adds fractional note divisions with the B<tuple()>
function.

32nd durations added:

  yn dyn ddyn tyn

64th durations added:

  xn dxn ddxn txn

=head1 FUNCTION

=head2 tuple()

  Music::Duration::tuple( 'qn', 'z', 5 );
  # $score->n( 'zqn', ... );
  Music::Duration::tuple( 'wn', 'z', 5 );
  # $score->n( 'zwn', ... );

Add a fractional division to the L<MIDI::Simple> C<Length> hash for a given
B<name> and B<duration>.

Musically, this creates a "cluster" of notes in place of the given B<duration>.

A triplet is a 3-tuple.

So in the first example, instead of a quarter note, we instead play 5 beats - a
5-tuple.  In the second, instead of a whole note (of four beats), we instead
play 5 beats.

=head1 SEE ALSO

The C<Length> hash in L<MIDI::Simple>

The code in the C<t/> directory

L<https://www.scribd.com/doc/26974069/Frank-Zappa-The-Black-Page-1-Melody-Score>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
