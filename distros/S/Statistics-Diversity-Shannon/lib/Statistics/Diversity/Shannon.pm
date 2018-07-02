package Statistics::Diversity::Shannon;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Compute the Shannon diversity

use Moo;
use strictures 2;
use namespace::clean;

use List::Util 1.30 qw(sum0);

our $VERSION = '0.0102';


has data => (
    is  => 'ro',
    isa => sub { die 'Not an array reference' unless ref($_[0]) eq 'ARRAY' },
);

has freq => (
    is      => 'ro',
    isa     => sub { die 'Not an array reference' unless ref($_[0]) eq 'ARRAY' },
    builder => 1,
    lazy    => 1,
);

has N => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

has sum => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

has index => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

has evenness => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);


sub _build_N {
    my $self = shift;
    my $n = $self->data ? scalar @{ $self->data } : $self->freq ? scalar @{ $self->freq } : 0;
    return $n;
}

sub _build_sum {
    my $self = shift;
    my $sum = $self->data ? sum0 @{ $self->data } : $self->freq ? sum0 @{ $self->freq } : 0;
    return $sum;
}

sub _build_freq {
    my $self = shift;

    my @freq;

    for my $datum ( @{ $self->data } ) {
        push @freq, $datum / $self->sum;
    }

    return \@freq;
}


sub _build_index {
    my $self = shift;

    my @index;

    for my $datum ( @{ $self->freq } ) {
        push @index, $datum * log($datum);
    }

    return -1 * sum0 @index;
}


sub _build_evenness {
    my $self = shift;
    return $self->index / log( $self->N );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::Diversity::Shannon - Compute the Shannon diversity

=head1 VERSION

version 0.0102

=head1 SYNOPSIS

  use Statistics::Diversity::Shannon;
  my @data = qw( 60 10 25 1 4 );
  my $d = Statistics::Diversity::Shannon->new( data => \@data );
  # OR
  @data = qw( .6 .1 .25 .01 .04 );
  $d = Statistics::Diversity::Shannon->new( freq => \@data );
  my $H = $d->index();
  my $E = $d->evenness();

=head1 DESCRIPTION

A C<Statistics::Diversity::Shannon> computes the Shannon diversity index and
evenness metrics.

=head1 METHODS

=head2 new()

  $d = Statistics::Diversity::Shannon->new( data => \@raw_data );
  $d = Statistics::Diversity::Shannon->new( freq => \@prop_data );

Create a new C<Statistics::Diversity::Shannon> object from either raw numerical data or proportional frequency data.

=head2 Attributes

=head3 data

A reference to a numeric array

=head3 freq

A reference to a numeric array of proportional frequencies

=head2 index()

  $H = $d->index;

Return the Shannon diversity index.

=head2 evenness()

  $E = $d->evenness;

Return the Shannon diversity evenness metric.

=head1 SEE ALSO

L<Moo>

L<List::Util>

The test in this distribution.

L<https://en.wikipedia.org/wiki/Diversity_index#Shannon_index>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
