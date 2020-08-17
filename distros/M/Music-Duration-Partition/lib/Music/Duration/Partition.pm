package Music::Duration::Partition;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Partition a musical duration into rhythmic phrases

our $VERSION = '0.0513';

use Moo;
use strictures 2;

use Math::Random::Discrete;
use MIDI::Simple;
use List::Util qw/ min /;

use namespace::clean;


has durations => (
    is      => 'ro',
    default => sub { return \%MIDI::Simple::Length },
);


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
    die 'Sizes of weights and pool not equal' unless @{ $self->weights } == @{ $self->pool };
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


has verbose => (
    is      => 'ro',
    default => sub { return 0 },
);


sub motif {
    my ($self) = @_;

    my $motif = [];

    my $format = '%.4f';

    my $sum = 0;

    while ( $sum < $self->size ) {
        my $name = $self->pool_select->();
        my $size = $self->_duration($name);
        my $diff = $self->size - $sum;

        last
            if sprintf( $format, $diff ) < sprintf( $format, $self->_min_size );

        next
            if sprintf( $format, $size ) > sprintf( $format, $diff );

        $sum += $size;

        warn(__PACKAGE__,' ',__LINE__," $name, $size, $sum\n")
            if $self->verbose;

        push @$motif, $name
            if $sum <= $self->size;
    }

    return $motif;
}

sub _duration {
    my ( $self, $name ) = @_;

    my $dura;

    if ($name =~ /^d(\d+)$/) {
        $dura = $1;
    }
    else {
        $dura = $self->durations->{$name};
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

version 0.0513

=head1 SYNOPSIS

  use MIDI::Simple;
  use Music::Duration::Partition;
  use Music::Scales;

  my $mdp = Music::Duration::Partition->new(
    size    => 8,
    pool    => [qw/ qn en sn /],
    weights => [ 0.2, 0.3, 0.5 ], # Optional
  );

  $mdp->pool_select( sub { ... } ); # Optional

  my $motif = $mdp->motif;

  my @scale = get_scale_MIDI( 'C', 4, 'major' );

  my $score = MIDI::Simple->new_score;

  for my $n ( 0 .. 31 ) { # 4 loops over the motif
    $score->n( $motif->[$n % @$motif], $scale[int rand @scale] );
  }

  $score->write_score('motif.mid');

  # The size and pool may also be made of MIDI durations
  $mdp = Music::Duration::Partition->new(
    size => 100,
    pool => [qw/ d50 d25 /],
  );

=head1 DESCRIPTION

C<Music::Duration::Partition> partitions a musical duration into
rhythmic phrases, given by the B<size>, into smaller durations drawn
from the B<pool> of possibly weighted durations.

=head1 ATTRIBUTES

=head2 durations

  $durations = $mdp->durations;

A hash reference of duration lengths (keyed by duration name).

Default: C<\%MIDI::Simple::Length>

=head2 size

  $size = $mdp->size;

The value, in quarter notes, of the duration to partition.

Default: C<4>

=head2 pool

  $pool = $mdp->pool;

The list of possible note durations to use in constructing a rhythmic
motif.

Default: C<[ keys %MIDI::Simple::Length ]> (wn, hn, qn, ...)

This can be B<either> a list of duration names, as in the default
example, or duration values, specified with a preceding 'd'.  A
mixture of both is not well defined. YMMV

=head2 pool_select

  $code = $mdp->pool_select->();
  $mdp->pool_select( sub { ... } );

A code reference used to select an item from the given duration
B<pool>.

Default: Random item from B<pool>

=head2 weights

  $weights = $mdp->weights;

Specification of the frequency of pool item selection.

The number of weights must equal the number of pool entries.  The
weights do not have to sum to 1 and can be any relative numbers.

Default: Equal probability for each pool entry

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

=head1 SEE ALSO

The F<eg/*> and F<t/01-methods.t> programs in this distribution.

L<List::Util>

L<Math::Random::Discrete>

L<MIDI::Simple>

L<Moo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
