package Music::Duration::Partition;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Partition a musical duration

our $VERSION = '0.0303';

use Moo;
use strictures 2;

use MIDI::Simple;
use List::Util qw/ min /;

use namespace::clean;


has names => (
    is      => 'ro',
    default => sub { return \%MIDI::Simple::Length },
);


has sizes => (
    is      => 'ro',
    default => sub { return { reverse %MIDI::Simple::Length } },
);


has size => (
    is      => 'ro',
    default => sub { return 4 },
);


has pool => (
    is      => 'ro',
    default => sub { return [ keys %MIDI::Simple::Length ] },
);


has pool_code => (
    is      => 'rw',
    builder => 1,
    lazy    => 1,
);

sub _build_pool_code {
    my ($self) = @_;
    return sub { return $self->pool->[ int rand @{ $self->pool } ] };
};


has min_size => (
    is       => 'ro',
    builder  => 1,
    lazy     => 1,
    init_arg => undef,
);

sub _build_min_size {
    my ($self) = @_;

    my @sizes = map { $self->duration($_) } @{ $self->pool };

    return min(@sizes);
}


sub name {
    my ( $self, $size ) = @_;
    return $self->sizes->{$size};
}


sub duration {
    my ( $self, $name ) = @_;
    return $self->names->{$name};
}


sub motif {
    my ($self) = @_;

    my $motif = [];

    my $sum = 0;

    while ( $sum < $self->size ) {
        my $name = $self->pool_code->();
        my $size = $self->duration($name);
        my $diff = $self->size - $sum;
        last
            if sprintf( '%.4f', $diff ) < sprintf( '%.4f', $self->min_size );
        next
            if sprintf( '%.4f', $size ) > sprintf( '%.4f', $diff );
        $sum += $size;
#warn(__PACKAGE__,' ',__LINE__," MARK: $name, $size, $sum\n");
        push @$motif, $name
            if $sum <= $self->size;
    }

    return $motif;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Duration::Partition - Partition a musical duration

=head1 VERSION

version 0.0303

=head1 SYNOPSIS

  use Music::Duration::Partition;

  my $mdp = Music::Duration::Partition->new(
    size => 8,
    pool => [qw/ qn en sn /],
  );

  $mdp->pool_code( sub { ... } ); # Optional

  my $motif = $mdp->motif;

  my $notes = get_notes($motif); # Your imaginary note generator

  my $score = MIDI::Util::setup_score(); # https://metacpan.org/pod/MIDI::Util

  for my $n ( 0 .. @$notes - 1 ) {
    $score->n( $motif->[$n], $notes->[$n] );
  }

  $score->write_score('motif.mid');

=head1 DESCRIPTION

C<Music::Duration::Partition> partitions a musical duration (the
B<size> attribute) into smaller durations drawn from the B<pool> of
possible durations.

=head1 ATTRIBUTES

=head2 names

  $names = $mdp->names;

A hash reference of C<%MIDI::Simple::Length> (keyed by duration name).

Default: C<%MIDI::Simple::Length>

=head2 sizes

  $sizes = $mdp->sizes;

A hash reference of C<%MIDI::Simple::Length> (keyed by duration value).

Default: C<reverse %MIDI::Simple::Length>

=head2 size

  $size = $mdp->size;

The value of the duration to partition.

Default: C<4> (whole note)

=head2 pool

  $pool = $mdp->pool;

The list of possible note duration names to use in constructing a
motif.

Default: C<[ keys %MIDI::Simple::Length ]>

=head2 pool_code

  $name = $mdp->pool_code->();
  $mdp->pool_code( sub { ... } );

A code reference to select an item from the given duration B<pool>.

Default: Random item of B<pool>

=head2 min_size

  $min_size = $mdp->min_size;

This is a computed attribute.

=head1 METHODS

=head2 new

  $mdp = Music::Duration::Partition->new(%arguments);

Create a new C<Music::Duration::Partition> object.

=head2 name

  $name = $mdp->name($duration);

Return the duration name of the given value.

=head2 duration

  $duration = $mdp->duration($name);

Return the duration value of the given name.

=head2 motif

  $motif = $mdp->motif;

Generate a rhythmic phrase of the given B<size>.

The default B<pool_code> used constructs this by selecting a B<pool>
duration at random, that fits into the size remaining after each
application, in a loop until the B<size> is met.

=head1 SEE ALSO

The F<t/01-methods.t>, F<eg/motif> and F<eg/shuffle> code in this
distribution.

L<List::Util>

L<Moo>

L<MIDI::Simple>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
