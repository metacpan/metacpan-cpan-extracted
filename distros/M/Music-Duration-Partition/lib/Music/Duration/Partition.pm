package Music::Duration::Partition;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Partition a musical duration into rhythmic phrases

our $VERSION = '0.0820';

use Moo;
use strictures 2;
use MIDI::Simple ();
use Math::Random::Discrete ();
use List::Util qw(min);
use namespace::clean;

use constant TICKS => 96;


has size => (
    is      => 'ro',
    default => sub { return 4 },
);


has pool => (
    is      => 'ro',
    isa     => sub { die 'Empty pool not allowed' unless ref( $_[0] ) eq 'ARRAY' && @{ $_[0] } > 0 },
    default => sub { return [ keys %MIDI::Simple::Length ] },
);

has _min_size => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build__min_size {
    my ($self) = @_;

    my @sizes = map { $self->_duration($_) } @{ $self->pool };

    return min(@sizes);
}

has _mrd => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build__mrd {
    my ($self) = @_;
    die 'Sizes of weights and pool not equal'
        unless @{ $self->weights } == @{ $self->pool };
    return Math::Random::Discrete->new($self->weights, $self->pool);
}


has pool_select => (
    is      => 'rw',
    builder => 1,
    lazy    => 1,
);

sub _build_pool_select {
    my ($self) = @_;
    return sub { return $self->_mrd->rand };
};


has weights => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build_weights {
    my ($self) = @_;
    # Equal probability for all pool members
    return [ (1) x @{ $self->pool } ];
}


has groups => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build_groups {
    my ($self) = @_;
    return [ (0) x @{ $self->pool } ];
}

has _pool_group => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build__pool_group {
    my ($self) = @_;

    my %pool_group;
    for my $i (0 .. @{ $self->pool } - 1) {
        $pool_group{ $self->pool->[$i] } = $self->groups->[$i];
    }

    return \%pool_group;
}


has remainder => (
    is      => 'ro',
    default => sub { return 1 },
);


has verbose => (
    is      => 'ro',
    default => sub { return 0 },
);

# hash reference of duration lengths (keyed by duration name)
# Default: \%MIDI::Simple::Length
has _durations => (
    is      => 'ro',
    default => sub { return \%MIDI::Simple::Length },
);


sub motif {
    my ($self) = @_;

    my $motif = [];

    my $format = '%.4f';

    my $sum = 0;
    my $group_num = 0;
    my $group_name = '';

    while ( $sum < $self->size ) {
        my $name = $self->pool_select->($self); # Chooses a note duration

        # Compute grouping
        if ($group_num) {
            $group_num--;
            $name = $group_name;
        }
        else {
            if ($self->_pool_group->{$name}) {
                $group_num = $self->_pool_group->{$name} - 1;
                $group_name = $name;
            }
            else {
                $group_num = 0;
                $group_name = '';
            }
        }

        my $size = $self->_duration($name); # Get the duration of the note
        my $diff = $self->size - $sum; # How much is left?

        # The difference is less than the min_size
        if (sprintf( $format, $diff ) < sprintf( $format, $self->_min_size )) {
            warn "WARNING: Leftover duration: $diff\n"
                if $self->verbose;
            push @$motif, 'd' . sprintf('%.0f', TICKS * $diff)
                if $self->remainder && sprintf($format, TICKS * $diff) > 0;
            last;
        }

        # The note duration is greater than the difference
        next
            if sprintf( $format, $size ) > sprintf( $format, $diff );

        # Increment the sum by the note duration
        $sum += $size;

        warn(__PACKAGE__,' ',__LINE__," $name, $size, $sum\n")
            if $self->verbose;

        # Add the note to the motif if the sum is less than the total duration size
        push @$motif, $name
            if $sum <= $self->size;
    }

    return $motif;
}


sub motifs {
    my ($self, $n) = @_;
    $n ||= 1;
    my @motifs = map { $self->motif } 1 .. $n;
    return @motifs;
}


sub add_to_score {
    my ($self, $score, $motif, $pitches) = @_;
    for my $i (0 .. $#$motif) {
        $score->n($motif->[$i], $pitches->[$i]);
    }
}

sub _duration {
    my ( $self, $name ) = @_;

    my $dura;

    if ($name =~ /^d(\d+)$/) {
        $dura = $1;
    }
    else {
        $dura = $self->_durations->{$name};
    }

    return $dura;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Duration::Partition - Partition a musical duration into rhythmic phrases

=head1 VERSION

version 0.0820

=head1 SYNOPSIS

  use Music::Duration::Partition ();

  my $mdp = Music::Duration::Partition->new(
    size => 8,                  # 2 measures in 4/4 time
    pool => [qw(hn dqn qn en)], # made from these durations
  );

  # the pool may be optionally weighted
  $mdp = Music::Duration::Partition->new(
    size    => 100,
    pool    => [qw(d50  d25)],
    weights => [   0.7, 0.3 ],
  );

  # the pool may also be grouped
  $mdp = Music::Duration::Partition->new(
    pool   => [qw(hn qn tqn)],
    groups => [   1, 1, 3   ],
  );

  my $motif  = $mdp->motif;     # list-ref of pool members
  my @motifs = $mdp->motifs(4); # list of motifs

=head1 DESCRIPTION

A C<Music::Duration::Partition> divides a musical duration given by
B<size>, into rhythmic phrases of smaller durations drawn from the
B<pool>.

For example, to generate a measure in C<5/4> time, set B<size> equal
to C<5> and set the B<pool> to an array-reference of L<MIDI::Simple>
durations whose lengths are less than or equal to C<5> quarter notes.

To generate a measure in C<5/8> time, set B<size> equal to C<2.5>
(meaning 5 eighth notes).

For MIDI usage, please see
L<Music::Duration::Partition::Tutorial::Quickstart> and
L<Music::Duration::Partition::Tutorial::Advanced>.

=head1 ATTRIBUTES

=head2 size

  $size = $mdp->size;

The value, in quarter notes, of the duration to partition.

Default: C<4>

=head2 pool

  $pool = $mdp->pool;

The list of possible note durations to use in constructing a rhythmic
motif.

Default: C<[ keys %MIDI::Simple::Length ]> (wn, hn, qn, ...)

This can be either a list of duration names, or duration values,
specified with a preceding C<d>.  A mixture of both is not well
defined. YMMV

=head2 pool_select

  $code = $mdp->pool_select->();
  $mdp->pool_select( sub { ... } );

A code reference used to select an item from the given duration
B<pool>.

Default: Random item from B<pool>

=head2 weights

  $weights = $mdp->weights;

The frequencies of pool item selection.

The number of weights must equal the number of B<pool> entries. The
weights do not have to sum to 1 and can be any relative numbers.

Default: Equal probability for each pool entry

=head2 groups

  $groups = $mdp->groups;

The number of times that a pool item is selected in sequence.

The number of groups must equal the number of B<pool> entries.

Default: C<0> for each pool entry

* C<0> and C<1> mean the same thing for grouping. So if needed, an
entry should have a value greater than one.

=head2 remainder

  $remainder = $mdp->remainder;

Append any remaining duration ticks to the end of the motif.

Default: C<1> "Yes. Make it so."

=head2 verbose

  $verbose = $mdp->verbose;

Show the progress of the B<motif> method.

Default: C<0>

=head1 METHODS

=head2 new

  $mdp = Music::Duration::Partition->new(%arguments);

Create a new C<Music::Duration::Partition> object.

=head2 motif

  $motif = $mdp->motif;

Generate a rhythmic phrase of the given B<size>.

This method returns a possibly different rhythmic motif each time it
is called.

The default B<pool_select> used constructs this by selecting a B<pool>
duration at random, that fits into the size remaining after each
application, in a loop until the B<size> is met.

=head2 motifs

  @motifs = $mdp->motifs;
  @motifs = $mdp->motifs($n);

Return B<n> motifs.

Default: C<n=1>

=head2 add_to_score

  $mdp->add_to_score($score, $motif, $pitches);

Add the B<motif> and B<pitches> to the B<score>.

=head1 SEE ALSO

The F<eg/*> and F<t/01-methods.t> programs in this distribution.

L<https://ology.github.io/music-duration-partition-tutorial/>

L<List::Util>

L<Math::Random::Discrete>

L<MIDI::Simple>

L<Moo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
