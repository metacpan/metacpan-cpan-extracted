package Music::MelodicDevice::Arpeggiation;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Apply arpeggiation patterns to groups of notes

our $VERSION = '0.0104';

use Moo;
use strictures 2;
use Data::Dumper::Compact qw(ddc);
use namespace::clean;

use constant TICKS => 96;


has pattern => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not an array reference" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [0,1,2] },
);


has duration => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a valid duration" unless $_[0] =~ /^\d+\.?(\d+)?$/ },
    default => sub { 1 },
);


has repeats => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 1 },
);


has verbose => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);



sub arp {
    my ($self, $notes, $duration, $pattern, $repeats) = @_;

    $duration ||= $self->duration;
    $pattern  ||= $self->pattern;
    $repeats  ||= $self->repeats;

    my $number = @$notes; # Number of notes in the arpeggiation

    # Compute the ornament durations
    my $x = $duration * TICKS;
    my $z = sprintf '%0.f', $x / $number;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @arp;
    for my $i (1 .. $repeats) {
        for my $p (@$pattern) {
            push @arp, [ $z, $notes->[$p] ];
        }
    }
    print 'Arp: ', ddc(\@arp) if $self->verbose;

    return \@arp;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::MelodicDevice::Arpeggiation - Apply arpeggiation patterns to groups of notes

=head1 VERSION

version 0.0104

=head1 SYNOPSIS

  use Music::MelodicDevice::Arpeggiation;

  my $arp = Music::MelodicDevice::Arpeggiation->new;

  my $arped = $arp->arp([60,64,67], 1, [0,1,2,1], 3);

=head1 DESCRIPTION

C<Music::MelodicDevice::Arpeggiation> applies arpeggiation patterns to
groups of notes.

=head1 ATTRIBUTES

=head2 pattern

  $arp->pattern(\@pattern);
  $pattern = $arp->pattern;

Default: C<[0,1,2]>

Arpeggiation note index selection pattern.

=head2 duration

  $arp->duration($duration);
  $duration = $arp->duration;

Default: C<1> (quarter-note)

Duration over which to distribute the arpeggiated pattern of notes.

=head2 repeats

  $arp->repeats($repeats);
  $repeats = $arp->repeats;

Default: C<1>

Number of times to repeat the arpeggiated pattern of notes.

=head2 verbose

  $arp->verbose($verbose);
  $verbose = $arp->verbose;

Default: C<0>

Show progress.

=head1 METHODS

=head2 new

  $x = Music::MelodicDevice::Arpeggiation->new(
    scale_note => $scale_note,
    scale_name => $scale_name,
    verbose    => $verbose,
  );

Create a new C<Music::MelodicDevice::Arpeggiation> object.

=for Pod::Coverage TICKS

=head2 arp

  $notes = $arp->arp(\@pitches); # use object defaults
  $notes = $arp->arp(\@pitches, $duration);
  $notes = $arp->arp(\@pitches, $duration, \@pattern);
  $notes = $arp->arp(\@pitches, $duration, \@pattern, $repeats);

Return a list of lists of C<d#> MIDI-Perl strings with the pitches indexed by the arpeggiated pattern. These MIDI-Perl duration strings are distributed evenly across the given C<duration>.

So given a duration of 1 (a quarter-note), a list of 4 notes to arpeggiate, an arpeggiation pattern of C<[0,1,2,3]>, and 1 repeat, this method will return a list of lists with length of the duration divided by the number of pitches. An item of the list is itself a list of 2 elements: the divided duration and the selected pitch given the pattern index.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution

L<Data::Dumper::Compact>

L<Moo>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
