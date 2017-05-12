package ShardedKV::Continuum::CHash;
{
  $ShardedKV::Continuum::CHash::VERSION = '0.01';
}
use Moose;
# ABSTRACT: Continuum implementation based on Algorithm::ConsistentHash::CHash
use Algorithm::ConsistentHash::CHash;
use JSON::XS qw(encode_json decode_json);

with 'ShardedKV::Continuum';

has '_orig_continuum_spec' => (
  is => 'ro',
);

has '_chash' => (
  is => 'ro',
  isa => 'Algorithm::ConsistentHash::CHash',
);

sub choose {
  $_[0]->_chash->lookup($_[1])
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
  
  $self->_assert_spec_ok($spec);

  # Build clone of the original spec (to avoid action at a
  # distance) and add the new nodes.
  my $orig_spec = $self->_orig_continuum_spec;
  my $clone_spec = {
    %$orig_spec, # replicas + in case there's other gunk in it, at least make an effort
    ids => [ @{$orig_spec->{ids}} ], # deep clone
  };
  push @{ $clone_spec->{ids} }, @{ $spec->{ids} };

  $self->{_chash} = $self->_make_chash($clone_spec);
  $self->{_orig_continuum_spec} = $clone_spec;
  return 1;
}

sub get_bucket_names {
  my $self = shift;

  return @{ $self->_orig_continuum_spec()->{ids} };
}

sub BUILD {
  my ($self, $args) = @_;

  my $from = delete $args->{from};
  if (ref($from) eq 'HASH') {
    $self->{_chash} = $self->_make_chash($from);
    $self->{_orig_continuum_spec} = $from;
  }
  else {
    die "Invalid 'from' specification for " . __PACKAGE__;
  }
}

sub _assert_spec_ok {
  my ($self, $spec) = @_;
  Carp::croak("Continuum spec must be a hash of the form {ids => [qw(node1 node2 node3)], replicas => 123}")
    if not ref($spec) eq 'HASH'
    or not ref($spec->{ids}) eq 'ARRAY'
    or not @{$spec->{ids}};
  return 1;
}

sub _make_chash {
  my ($self, $spec) = @_;

  $self->_assert_spec_ok($spec);

  return Algorithm::ConsistentHash::CHash->new(%$spec);
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

ShardedKV::Continuum::CHash - Continuum implementation based on Algorithm::ConsistentHash::CHash

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Continuum::CHash;
  my $skv = ShardedKV->new(
    continuum => ShardedKV::Continuum::CHash->new(
      from => {
        ids => [qw(node1 node2 node3 node4)],
        replicas => 200,
      }
    ),
    storages => {...},
  );
  ...
  $skv->extend({ids => [qw(node5 node6 node7)]});

=head1 DESCRIPTION

A continuum implementation based on libchash consistent hashing.
See C<Algorithm::ConsistentHash::CHash>.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Continuum>

=item *

L<ShardedKV::Continuum::Ketama>

=item *

L<Algorithm::ConsistentHash::CHash>

=item *

L<Algorithm::ConsistentHash::Ketama>

=back

=head1 AUTHOR

Steffen Mueller <smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
