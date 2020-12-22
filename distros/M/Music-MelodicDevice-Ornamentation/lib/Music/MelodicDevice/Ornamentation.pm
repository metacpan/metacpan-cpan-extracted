package Music::MelodicDevice::Ornamentation;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Chromatic and diatonic melodic ornamentation

our $VERSION = '0.0400';

use Data::Dumper::Compact qw(ddc);
use List::SomeUtils qw(first_index);
use MIDI::Simple ();
use Music::Duration;
use Music::Scales qw(get_scale_notes is_scale);
use Moo;
use strictures 2;
use namespace::clean;

use constant TICKS => 96;


has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);


has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid scale name" unless is_scale($_[0]) },
    default => sub { 'chromatic' },
);

has _scale => (
    is        => 'lazy',
    init_args => undef,
);

sub _build__scale {
    my ($self) = @_;

    my @scale = get_scale_notes($self->scale_note, $self->scale_name);
    print 'Scale: ', ddc(\@scale) if $self->verbose;

    my @with_octaves = map { my $o = $_; map { $_ . $o } @scale } 0 .. 10;
    print 'With octaves: ', ddc(\@with_octaves) if $self->verbose;

    return \@with_octaves;
}

has _enharmonics => (
    is        => 'lazy',
    init_args => undef,
);

sub _build__enharmonics {
  my ($self) = @_;
  my %enharmonics = (
      'C#' => 'Db',
      'D#' => 'Eb',
      'E#' => 'F',
      'F#' => 'Gb',
      'G#' => 'Ab',
      'A#' => 'Bb',
      'B#' => 'C',
  );
  return { %enharmonics, reverse %enharmonics }
}


has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);



sub grace_note {
    my ($self, $duration, $pitch, $offset) = @_;

    $offset //= 1;

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $grace_note = $self->_scale->[ $i + $offset ];

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $y = $MIDI::Simple::Length{yn} * TICKS; # Thirty-second note
    my $z = sprintf '%0.f', $x - $y;
    print "Durations: $x, $y, $z\n" if $self->verbose;
    $y = 'd' . $y;
    $z = 'd' . $z;

    my @grace_note = ([$y, $grace_note], [$z, $pitch]);
    print 'Grace note: ', ddc(\@grace_note) if $self->verbose;

    return \@grace_note;
}


sub turn {
    my ($self, $duration, $pitch, $offset) = @_;

    my $number = 4;
    $offset //= 1;

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $above = $self->_scale->[ $i + $offset ];
    my $below = $self->_scale->[ $i - $offset ];

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', $x / $number;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @turn = ([$z, $above], [$z, $pitch], [$z, $below], [$z, $pitch]);;
    print 'Turn: ', ddc(\@turn) if $self->verbose;

    return \@turn;
}


sub trill {
    my ($self, $duration, $pitch, $number, $offset) = @_;

    $number ||= 2;
    $offset //= 1;

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $alt = $self->_scale->[ $i + $offset ];

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', ($x / $number / 2);
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @trill;

    push @trill, [$z, $pitch], [$z, $alt] for 1 .. $number;

    return \@trill;
}


sub mordent {
    my ($self, $duration, $pitch, $offset) = @_;

    my $number = 4;
    $offset //= 1;

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $alt = $self->_scale->[ $i + $offset ];

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $y = sprintf '%0.f', $x / $number;
    my $z = sprintf '%0.f', $x - (2 * $y);
    print "Durations: $x, $y, $z\n" if $self->verbose;
    $y = 'd' . $y;
    $z = 'd' . $z;

    my @mordent;

    push @mordent, [$y, $pitch], [$y, $alt], [$z, $pitch];
    print 'Mordent: ', ddc(\@mordent) if $self->verbose;

    return \@mordent;
}

sub _find_pitch {
    my ($self, $pitch) = @_;
    my $i = first_index { $_ eq $pitch } @{ $self->_scale };
    if ($i == -1) {
        my $enharmonics = $self->_enharmonics;
        $pitch =~ s/^([A-G][#b]?)(\d+)$/$enharmonics->{$1}$2/;
        $i = first_index { $_ eq $pitch } @{ $self->_scale };
    }
    return $i, $pitch;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::MelodicDevice::Ornamentation - Chromatic and diatonic melodic ornamentation

=head1 VERSION

version 0.0400

=head1 SYNOPSIS

  use Music::MelodicDevice::Ornamentation;

  my $md = Music::MelodicDevice::Ornamentation->new; # chromatic

  $md = Music::MelodicDevice::Ornamentation->new( # diatonic
    scale_note => 'C',
    scale_name => 'major',
    verbose => 1,
  );

  my $spec = $md->grace_note('qn', 'D5', -1);
  $spec = $md->turn('qn', 'D5', 1);
  $spec = $md->trill('qn', 'D5', 2, 1);
  $spec = $md->mordent('qn', 'D5', 1);

=head1 DESCRIPTION

C<Music::MelodicDevice::Ornamentation> provides chromatic and diatonic
musical melodic ornamentation methods.

=head1 ATTRIBUTES

=head2 scale_note

Default: C<C>

=head2 scale_name

Default: C<chromatic>

For the chromatic scale, enharmonic notes are listed as sharps.  For a
scale with flats, a diatonic B<scale_name> must be used with a flat
B<scale_note>.

Please see L<Music::Scales/SCALES> for a list of valid scale names.

=head2 verbose

Default: C<0>

Show the progress of the methods.

=head1 METHODS

=head2 new

  $x = Music::MelodicDevice::Ornamentation->new(
    scale_note => $scale_note,
    scale_name => $scale_name,
    verbose => $verbose,
  );

Create a new C<Music::MelodicDevice::Ornamentation> object.

=head2 grace_note

  $spec = $md->grace_note($duration, $pitch, $offset);

Default offset: C<1>

"Appoggiatura" means emphasis on the grace note.  "Acciaccatura" means
emphasis on the main note.  This module doesn't accent notes.  You'll
have to do that bit.

=head2 turn

  $spec = $md->turn($duration, $pitch, $offset);

The note Above, the Principle note (the B<pitch>), the note Below, the
Principle note again.

The default B<offset> is C<1>, but if given as C<-1>, the turn is
"inverted" and goes: Below, Principle, Above, Principle.

=head2 trill

  $spec = $md->trill($duration, $pitch, $number, $offset);

A trill is a B<number> of pairs of notes spread over a given
B<duration>.  The first of the pair being the given B<pitch> and the
second one given by the B<offset>.

Default number: C<2>

Default offset: C<1>

=head2 mordent

  $spec = $md->mordent($duration, $pitch, $offset);

"A rapid alternation between an indicated note [the B<pitch>], the
note above or below, and the indicated note again."

An B<offset> of C<1> (the default) returns an upper mordent one pitch
away.  An B<offset> of C<-1> returns a lower mordent.

So if the B<pitch> is C<D5>, a diatonic upper mordent would be
C<D5 E5 D5>.  A chromatic lower mordent would be C<D5 C#5 D5>.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution

L<Data::Dumper::Compact>

L<List::SomeUtils>

L<MIDI::Simple>

L<Moo>

L<Music::Duration>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Ornament_(music)>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
