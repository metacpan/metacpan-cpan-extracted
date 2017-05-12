package Music::Harmonics;

use warnings;
use strict;
use MIDI::Pitch qw(name2freq freq2name);

=head1 NAME

Music::Harmonics - Calculate harmonics for stringed instruments

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Music::Harmonics;
  
  my $h = Music::Harmonics->new();
  foreach (2..5) {
      my %harm = $h->GetStringHarmonic(name => 'E2', harmonic => $_);
      printf("Grab fret %i to play the harmonic #%i. It'll be a %s.\n",
          $harm{frets}->[0], $_, uc $harm{name});
  }    

=head1 DESCRIPTION

This module calculates the note names and positions of harmonics and overtones.
So far, it is limited to stringed instruments.

Note that the first harmonic is the foundational pitch, the second harmonic
is the first overtone, and so on.

The pitch names used in this module are the sames as used by L<MIDI::Pitch>.

=head1 CONSTRUCTOR

=head2 new

  my $h = Music::Harmonics->new(frets_per_octave => 12);

Creates a new C<Music::Harmonics> object. The C<frets_per_octave> parameter
is optional and defaults to 12.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};

    $self->{frets_per_octave} = $args{frets_per_octave} || 12;

    bless $self, $class;
}

=head1 FUNCTIONS

=head2 GetFret

    my $f = $h->GetFret($position);

Given a position on the fingerboard between 0 and 1 (0 being directly at the nut,
1 being at the other end of the string at the bridge), returns the fret number
as a float (assuming even intonation). For example, C<0.5> refers to the
middle of the string, so that C<GetFret(0.5)> on an 
instrument with 12 frets per octave returns 12.

=cut

sub GetFret {
    my ($self, $pos) = @_;

    if ($pos != 1) {
        return log(-1 / ($pos - 1)) / log(2) * $self->{frets_per_octave};
    } else {
        return 0;
    }
}

=head2 GetStringHarmonic

    %harm = $h->GetStringHarmonic(name => 'E2', harmonic => 2,
        minfret => 0, maxfret => 12);

Returns the positions where a certain harmonic can be played. C<minfret> and
C<maxfret> are optional, their default values are 0 and 12 respectively.

The result is a hash. C<name> gives the name of the harmonic, C<frequency> the
frequency and C<frets> is a list of fret positions.

=cut

sub _gcd {
    my ($n, $m) = @_;
    while ($m) {
        my $k = $n % $m;
        ($n, $m) = ($m, $k);
    }
    return $n;
}

sub GetStringHarmonic {
    my $self     = shift;
    my %params   = @_;
    my %defaults = (harmonic => 2, minfret => 0, maxfret => 24);
    foreach (keys %defaults) {
        $params{$_} = $defaults{$_} unless defined $params{$_};
    }

    return undef
      unless $params{name}
      && (my $basefreq = name2freq($params{name}));

    my @frets = ();

    # loop over fractions: 1/n, 2/n, 3/n, ...
    foreach my $i (1 .. $params{harmonic}) {
        next if _gcd($i, $params{harmonic}) > 1;

        my $fret = $self->GetFret($i / $params{harmonic});
        push @frets, $fret
          if ($fret >= $params{minfret} && $fret <= $params{maxfret});
    }

    my $freq = $basefreq * $params{harmonic};

    return (
        frequency => $freq,
        name      => freq2name($freq),
        frets     => [@frets]);
}

=head2 GetStringHarmonics 

    $h->GetStringHarmonics(name => 'E2', minharmonic => 2, maxharmonic => 6);

Retrieves a list of harmonics from C<minharmonic> to C<maxharmonic>.

=cut

sub GetStringHarmonics {
    my $self     = shift;
    my %params   = @_;
    my %defaults = (minharmonic => 2, maxharmonic => 6);
    foreach (keys %defaults) {
        $params{$_} = $defaults{$_} unless defined $params{$_};
    }

    return unless defined $params{name};
    return
      map { { $self->GetStringHarmonic(harmonic => $_, %params) } }
      $params{minharmonic} .. $params{maxharmonic};
}

=head1 SEE ALSO

L<MIDI::Pitch>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-music-harmonics@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Harmonics>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Christian Renz E<lt>crenz @ web42.comE<gt>, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

42;
