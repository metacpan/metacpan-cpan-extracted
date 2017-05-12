package ShardedKV::Continuum::Jump;

# This implementation is based heavily on the ShardedKV::Continuum::CHash module by Steffen Mueller

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.04';

use Algorithm::ConsistentHash::JumpHash;

use Moose;
use JSON::XS qw(encode_json decode_json);

with 'ShardedKV::Continuum';

has '_orig_continuum_spec' => (
  is => 'ro',
);

has '_expanded_weights' => (
  is => 'ro'
);

sub choose {
    my ($self, $key) = @_;
    my $idx = Algorithm::ConsistentHash::JumpHash::jumphash_siphash($key, scalar @{$self->_expanded_weights});
    $idx = $self->{_expanded_weights}->[$idx];
    return $self->_orig_continuum_spec->{ids}->[$idx];
}

sub serialize {
  my $self = shift;
  encode_json( $self->_orig_continuum_spec )
}

sub deserialize {
  my $class = shift;
  return $class->new(from => decode_json( $_[1] ));
}

sub clone {
  my $self = shift;
  my $clone = ref($self)->new(from => $self->_orig_continuum_spec);
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
    weights => [ @{$orig_spec->{weights}} ], # deep clone
  };
  push @{ $clone_spec->{ids} }, @{ $spec->{ids} };

  my $weights = $spec->{weights};
  if (!defined($weights)) {
      push @$weights, 1 for 1..@{$spec->{ids}};
  }
  push @{ $clone_spec->{weights} }, @{ $weights };

  $self->{_expanded_weights} = _expand_weights($clone_spec->{weights});

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
  $self->_assert_spec_ok($from);

  $self->{_orig_continuum_spec} = $from;

  my $weights = $from->{weights};
  if (!defined($weights)) {
      $weights = [];
      push @$weights, 1 for 1..@{$from->{ids}};
  }

  $from->{weights} = $weights;
  $self->{_expanded_weights} = _expand_weights($weights);
}

sub _expand_weights {
  my ($weights) = @_;

  my @expanded;

  for(my $i=0;$i<@$weights;$i++) {
    my $w = $weights->[$i];
    push @expanded, $i for 1..$w;
  }

  return \@expanded;
}

sub _assert_spec_ok {
  my ($self, $spec) = @_;

  Carp::croak("Continuum spec must be a hash of the form {ids => [qw(node1 node2 node3)]}")
    if not ref($spec) eq 'HASH'
    or not ref($spec->{ids}) eq 'ARRAY'
    or (defined($spec->{weights}) && (ref($spec->{weights}) ne 'ARRAY' || @{$spec->{ids}} != @{$spec->{weights}}));
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Continuum::Jump;
  my $skv = ShardedKV->new(
    continuum => ShardedKV::Continuum::Jump->new(
      from => {
        ids => [qw(node1 node2 node3 node4)],
      }
    ),
    storages => {...},
  );
  ...
  $skv->extend({ids => [qw(node5 node6 node7)]});


=head1 DESCRIPTION

A continuum implementation based on Google's Jump consistent hashing algorithm.

It uses SipHash to turn the string keys into 64-bit integers.

Note that the *order* of shard IDs is significant, unlike with other continuum implementations.  This is a limitation of the Jump algorithm.

=head1 SEE ALSO

* L<ShardedKV>
* L<ShardedKV::Continuum>
* L<ShardedKV::Continuum::CHash>

=head1 AUTHOR

Damian Gryski, E<lt>damian@gryski.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Damian Gryski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
