package ShardedKV::Continuum::Ketama;
$ShardedKV::Continuum::Ketama::VERSION = '0.20';
use Moose;
# ABSTRACT: Continuum implementation based on ketama consistent hashing
use Algorithm::ConsistentHash::Ketama;
use JSON::XS qw(encode_json decode_json);

with 'ShardedKV::Continuum';

has '_orig_continuum_spec' => (
  is => 'ro',
);

has '_ketama' => (
  is => 'ro',
  isa => 'Algorithm::ConsistentHash::Ketama',
);

sub choose {
  $_[0]->_ketama->hash($_[1])
}

# FIXME losing logger
sub serialize {
  my $self = shift;
  my $logger = $self->{logger};
  $logger->debug("Serializing continuum, this will lose the logger!") if $logger;
  encode_json( $self->_orig_continuum_spec )
}

sub deserialize {
  my $class = shift;
  return $class->new(from => decode_json( $_[1] ));
}

sub clone {
  my $self = shift;
  my $clone = ref($self)->new(from => $self->_orig_continuum_spec);
  $clone->{logger} = $self->{logger};
  return $clone;
}

sub extend {
  my $self = shift;
  my $spec = shift;

  my $ketama = $self->_ketama;
  Carp::croak("Ketama spec must be an Array of Arrays, each inner record holding key and weight! This is not an array")
    if not ref($spec) eq 'ARRAY';
  foreach my $elem (@$spec) {
    Carp::croak("Ketama spec must be an Array of Arrays, each inner record "
                . "holding key and weight! This particular record is not an array or does not hold two elements")
      if ref($elem) ne 'ARRAY' or @$elem != 2;
    $ketama->add_bucket(@$elem);
  }
}

sub get_bucket_names {
  my $self = shift;
  my $ketama = $self->_ketama;
  my @buckets = $ketama->buckets;
  return map $_->label, @buckets;
}

sub BUILD {
  my $self = shift;
  my $args = shift;
  my $from = delete $args->{from};
  if (ref($from) eq 'ARRAY') {
    $self->{_ketama} = $self->_make_ketama($from);
    $self->{_orig_continuum_spec} = $from;
  }
  else {
    die "Invalid 'from' specification for " . __PACKAGE__;
  }
}

sub _make_ketama {
  my $self = shift;
  my $spec = shift;
  my $ketama = Algorithm::ConsistentHash::Ketama->new;
  Carp::croak("Ketama spec must be an Array of Arrays, each inner record holding key and weight! This is not an array")
    if not ref($spec) eq 'ARRAY'
    or @$spec == 0;
  foreach my $elem (@$spec) {
    Carp::croak("Ketama spec must be an Array of Arrays, each inner record "
                . "holding key and weight! This particular record is not an array or does not hold two elements")
      if ref($elem) ne 'ARRAY' or @$elem != 2;
    $ketama->add_bucket(@$elem);
  }
  return $ketama;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

ShardedKV::Continuum::Ketama - Continuum implementation based on ketama consistent hashing

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Continuum::Ketama;
  my $skv = ShardedKV->new(
    continuum => ShardedKV::Continuum::Ketama->new(
      from => [ [shard1 => 100], [shard2 => 200], ... ],
    ),
    storages => {...},
  );

=head1 DESCRIPTION

A continuum implementation based on ketama consistent hashing.
See C<Algorithm::ConsistentHash::Ketama>.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Continuum>

=item *

L<Algorithm::ConsistentHash::Ketama>

=back

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
