package Music::MelodicDevice::Inversion;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Apply melodic inversion to a series of notes

our $VERSION = '0.0400';

use Data::Dumper::Compact qw(ddc);
use List::SomeUtils qw(first_index);
use Music::Note;
use Music::Scales qw(get_scale_MIDI is_scale);
use Moo;
use strictures 2;
use namespace::clean;

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


sub intervals {
    my ($self, $notes) = @_;

    my @pitches;

    for my $note (@$notes) {
        my ($i, $pitch) = $self->_find_pitch($note);
        push @pitches, $i;
    }
    print 'Pitches: ', ddc(\@pitches) if $self->verbose;

    my @intervals;
    my $last;

    for my $pitch (@pitches) {
        if (defined $last) {
            push @intervals, $pitch - $last;
        }
        $last = $pitch;
    }
    print 'Intervals: ', ddc(\@intervals) if $self->verbose;

    return \@intervals;
}


sub invert {
    my ($self, $note, $notes) = @_;

    my @inverted = ($note);

    my $intervals = $self->intervals($notes);

    for my $interval (@$intervals) {
        # Find the note that is the opposite interval away from the original note
        (my $i, $note) = $self->_find_pitch($note);
        my $pitch = $self->_scale->[ $i - $interval ];

        $note = Music::Note->new($pitch, 'midinum')->format('ISO');

        push @inverted, $note;
    }

    print 'Inverted: ', ddc(\@inverted) if $self->verbose;

    return \@inverted;
}

sub _find_pitch {
    my ($self, $pitch) = @_;
    $pitch = Music::Note->new($pitch, 'ISO')->format('midinum');
    my $i = first_index { $_ eq $pitch } @{ $self->_scale };
    return $i, $pitch;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::MelodicDevice::Inversion - Apply melodic inversion to a series of notes

=head1 VERSION

version 0.0400

=head1 SYNOPSIS

  use Music::MelodicDevice::Inversion;

  my @notes = qw(C4 E4 D4 G4 C5);

  # Chromatic
  my $md = Music::MelodicDevice::Inversion->new;
  my $intervals = $md->intervals(\@notes); # [4, -2, 5, 5]
  my $inverted = $md->invert('C4', \@notes); # [C4, G#3, A#3, F3, C3]

  # Diatonic
  $md = Music::MelodicDevice::Inversion->new(scale_name => 'major');
  $intervals = $md->intervals(\@notes); # [2, -1, 3, 3]
  $inverted = $md->invert('C4', \@notes); # [C4, A3, B3, F3, C3]

=head1 DESCRIPTION

C<Music::MelodicDevice::Inversion> applies intervallic melodic
inversions, both chromatic or diatonic, to a series of ISO formatted
notes.  Basically, this flips a melody upside-down given a starting
note.

While there are a couple modules on CPAN that do various versions of
melodic inversion, none appear to apply to an arbitrary series of
notes.  Hence this module.

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

=head1 METHODS

=head2 new

  $md = Music::MelodicDevice::Inversion->new(
    scale_note => $scale_note,
    scale_name => $scale_name,
    verbose => $verbose,
  );

Create a new C<Music::MelodicDevice::Inversion> object.

=head2 intervals

  $intervals = $md->intervals($notes);

Return the positive or negative intervals between successive B<notes>.

=head2 invert

  $inverted = $md->invert($note, $notes);

Return the inverted series of notes.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> distribution programs

L<Music::AtonalUtil> (contains a similar "invert" method)

L<MIDI::Praxis::Variation> (contains a mystery "inversion" function)

L<Data::Dumper::Compact>

L<List::SomeUtils>

L<Moo>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Inversion_(music)#Melodies>

L<https://music.stackexchange.com/a/32508/6683>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
