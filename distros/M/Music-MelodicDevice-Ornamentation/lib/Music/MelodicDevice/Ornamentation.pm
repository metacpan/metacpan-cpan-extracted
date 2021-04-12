package Music::MelodicDevice::Ornamentation;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Chromatic and diatonic melodic ornamentation

our $VERSION = '0.0602';

use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use List::SomeUtils qw(first_index);
use MIDI::Simple ();
use Music::Duration;
use Music::Note;
use Music::Scales qw(get_scale_MIDI is_scale);
use Moo;
use strictures 2;
use namespace::clean;

use constant TICKS => 96;
use constant OCTAVES => 10;


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

    my @scale = map { get_scale_MIDI($self->scale_note, $_, $self->scale_name) } -1 .. OCTAVES - 1;
    print 'Scale: ', ddc(\@scale) if $self->verbose;

    return \@scale;
}


has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);



sub grace_note {
    my ($self, $duration, $pitch, $offset) = @_;

    $offset //= 1; # Default one note above

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $grace_note = $self->_scale->[ $i + $offset ];

    $pitch = Music::Note->new($pitch, 'midinum')->format('ISO');
    $grace_note = Music::Note->new($grace_note, 'midinum')->format('ISO');

    # Compute the ornament durations
    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $y = $MIDI::Simple::Length{xn} * TICKS; # Thirty-second note
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

    my $number = 4; # Number of notes in the ornament
    $offset //= 1; # Default one note above

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $above = $self->_scale->[ $i + $offset ];
    my $below = $self->_scale->[ $i - $offset ];

    $pitch = Music::Note->new($pitch, 'midinum')->format('ISO');
    $above = Music::Note->new($above, 'midinum')->format('ISO');
    $below = Music::Note->new($below, 'midinum')->format('ISO');

    # Compute the ornament durations
    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', $x / $number;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @turn = ([$z, $above], [$z, $pitch], [$z, $below], [$z, $pitch]);
    print 'Turn: ', ddc(\@turn) if $self->verbose;

    return \@turn;
}


sub trill {
    my ($self, $duration, $pitch, $number, $offset) = @_;

    $number ||= 2; # Number of notes in the ornament
    $offset //= 1; # Default one note above

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $alt = $self->_scale->[ $i + $offset ];

    $pitch = Music::Note->new($pitch, 'midinum')->format('ISO');
    $alt = Music::Note->new($alt, 'midinum')->format('ISO');

    # Compute the ornament durations
    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', ($x / $number / 2);
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @trill;

    push @trill, [$z, $pitch], [$z, $alt] for 1 .. $number;
    print 'Trill: ', ddc(\@trill) if $self->verbose;

    return \@trill;
}


sub mordent {
    my ($self, $duration, $pitch, $offset) = @_;

    my $number = 4; # Finest division needed
    $offset //= 1; # Default one note above

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $alt = $self->_scale->[ $i + $offset ];

    $pitch = Music::Note->new($pitch, 'midinum')->format('ISO');
    $alt = Music::Note->new($alt, 'midinum')->format('ISO');

    # Compute the ornament durations
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


sub slide {
    my ($self, $duration, $from, $to) = @_;

    my @scale = map { get_scale_MIDI($self->scale_note, $_, 'chromatic') } -1 .. OCTAVES - 1;

    (my $i, $from) = $self->_find_pitch($from, \@scale);
    (my $j, $to) = $self->_find_pitch($to, \@scale);

    my ($start, $end);
    if ($i <= $j) {
        $start = $i;
        $end = $j;
    }
    else {
        $start = $j;
        $end = $i;
    }

    # Compute the ornament durations
    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $y = $end - $start + 1; # Number of notes in the slide
    my $z = sprintf '%0.f', $x / $y;
    print "Durations: $x, $y, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @slide = map { [ $z, Music::Note->new($scale[$_], 'midinum')->format('ISO') ] } $start .. $end;
    @slide = reverse @slide if $j < $i;
    print 'Slide: ', ddc(\@slide) if $self->verbose;

    return \@slide;
}

sub _find_pitch {
    my ($self, $pitch, $scale) = @_;

    $scale //= $self->_scale;

    $pitch = Music::Note->new($pitch, 'ISO')->format('midinum');

    my $i = first_index { $_ eq $pitch } @$scale;
    croak "Unknown pitch: $pitch" if $i < 0;

    return $i, $pitch;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::MelodicDevice::Ornamentation - Chromatic and diatonic melodic ornamentation

=head1 VERSION

version 0.0602

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
  $spec = $md->slide('qn', 'D5', 'F5');

=head1 DESCRIPTION

C<Music::MelodicDevice::Ornamentation> provides chromatic and diatonic
musical melodic ornamentation methods.

Each returns a note-set specification.  This specification is a list
of two part array-references: a B<duration> and a B<pitch>.  The list
B<duration> component is a division of the given duration argument,
and is based on the arithmetic of each ornament.  The list B<pitch>
can vary around the given pitch argument by the given offset, and also
depends on the particular ornament re-phrasing.

Since the point is likely to use MIDI-Perl to render these ornaments,
to audio, it is handy to know that the pitches in these specifications
can be translated to a readable format like this:

  $spec = [ map { [ MIDI::Util::midi_format(@$_) ] } @$spec ];
  $score->n(@$_) for @$spec;

=head1 ATTRIBUTES

=head2 scale_note

Default: C<C>

=head2 scale_name

Default: C<chromatic>

For the chromatic scale, enharmonic notes are listed as sharps.  For a
scale with flats, use a diatonic B<scale_name> with a flat
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

I believe that "appoggiatura" means emphasis on the grace note, and
"acciaccatura" means emphasis on the principle note.  This module
doesn't accent notes.  You'll have to do that bit.

=head2 turn

  $spec = $md->turn($duration, $pitch, $offset);

The note C<Above>, the C<Principle> note (the B<pitch>), the note
C<Below>, followed by the C<Principle> note again.

The default B<offset> is C<1>, but if given as C<-1>, the turn is
"inverted" and goes: C<Below>, C<Principle>, C<Above>, C<Principle>.

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

So if the B<pitch> is C<D5>, a diatonic upper mordent, in say C major,
would be C<D5 E5 D5>.  A chromatic lower mordent would be C<D5 C#5 D5>.

=head2 slide

  $spec = $md->slide($duration, $from, $to);

Return a specification where the notes move (in the C<chromatic>
scale) between the B<from> and B<to> pitches, for the given
B<duration>.

This ornament is also known as the "glissando."

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution

L<Carp>

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

This software is copyright (c) 2021 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
