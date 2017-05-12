package ShardedKV::Continuum::StaticMapping;
$ShardedKV::Continuum::StaticMapping::VERSION = '0.20';
use Moose;
# ABSTRACT: A continuum strategy based on a simple "significant bits" static mapping
use JSON::XS qw(encode_json decode_json);
use Array::IntSpan;
use POSIX ();

with 'ShardedKV::Continuum';

has 'num_significant_bits' => (
   is => 'ro',
   isa => 'Int',
);

# 2**num_significant_bits
has '_modulo' => (
   is => 'ro',
   isa => 'Int',
);

has '_min_key_length' => (
  is => 'ro',
  isa => 'Int',
);

has '_original_range_mapping' => (
  is => 'ro',
  isa => 'ArrayRef[ArrayRef]',
);

has '_intspan' => (
  is => 'ro',
  isa => 'Array::IntSpan',
);

# bypassing accessors, hot path
sub choose {
  my ($self, $key) = @_;

  die "Invalid key length: Need at least $self->{_min_key_length} bytes"
    if length($key) < $self->{_min_key_length};

  my ($location) = unpack("V", $key);
  return $self->{_intspan}->lookup($location % $self->{_modulo});
}

sub serialize {
  encode_json( {
    num_significant_bits => $_[0]->num_significant_bits,
    from => $_[0]->_original_range_mapping
  } )
}

sub deserialize {
  my $class = shift;
  return $class->new(decode_json( $_[1] ));
}

sub clone {
  my $self = shift;
  return ref($self)->new(
    num_significant_bits => $self->num_significant_bits,
    from => $self->_original_range_mapping
  );
}

sub extend {
  my $self = shift;
  my $spec = shift;

  die "Extension not supported for StaticMapping at this time!";

  # TODO: To be figure out
  # - How do you extend? In theory, we'd have to add a new range that takes over a part of a
  #   range from one or more others. This doesn't naturally allow for "take a bit of data from
  #   all other shards" which would be desireable for many key migration situations.
  # - Should we support increasing the no. of significant bits? Ie. go from 10 to 11 (1024 to 2048
  #   partitions) and thus simply double all ints in the ranges? How does this work with assigning
  #   actual semantics to the range numbers -- eg. for splitting into many tables in mysql?
  # - Does this allow for natural distribution of data into $n tables on $m hosts? IOW, the
  #   value returned by choose() would identify the host and the table, but the table would be
  #   identified directly by the integer in the host range. This is a natural fit if we want
  #   to shard by promoting a database slave to a master for a subset of the data and then simply
  #   drop partitions or tables that are not required respectively on old or new machine.
  #   GAAH.

  Carp::croak("StaticMapping spec must be an Array of Arrays, each inner record holding range start, end, and weight! This is not an array")
    if not ref($spec) eq 'ARRAY';
  my @ranges = [sort {$a->[0] <=> $b->[0]} @$spec];
  my $orig_mapping = $self->_original_range_mapping;
  my $prev = $orig_mapping->[-1][1];
  my $intspan = $self->_intspan;
  foreach my $range (@ranges) {
    Carp::croak("StaticMapping spec must be an Array of Arrays, each inner record "
                . "holding range start, end, and weight! This particular record is not an array or does not hold three elements")
      if not ref($range) eq 'ARRAY' and @$range == 3;
    if ($range->[0] != $prev+1) {
      Carp::croak("The lower boundary of any StaticMapping range needs to be one above the end of the previous"
                  ." range or 0 for the first range");
    }
    my $overlapping = $intspan->set_range(@$range);
    die("Assertion fail: range overlap!")
      if $overlapping;

    push @$orig_mapping, [@$range];
    $prev = $range->[1];
  }
}

sub get_bucket_names {
  my $self = shift;
  my $orig_mapping = $self->_original_range_mapping;
  return map $_->[2], @$orig_mapping;
}

sub BUILD {
  my $self = shift;
  my $args = shift;
  my $from = delete $args->{from};
  if (ref($from) eq 'ARRAY') {
    my $mapping = [sort {$a->[0] <=> $b->[0]} @$from];
    $self->{_intspan} = $self->_make_intspan($mapping);
    $self->{_original_range_mapping} = $mapping;
  }
  else {
    die "Invalid 'from' specification for " . __PACKAGE__;
  }
  my $bits = $self->num_significant_bits;
  $self->{_min_key_length} = POSIX::ceil($bits/8);
  $self->{_modulo} = 2 ** $bits;
}

sub _make_intspan {
  my $self = shift;
  my $spec = shift;

  Carp::croak("StaticMapping spec must be an Array of Arrays, each inner record holding range start, end, and weight! This is not an array")
    if not ref($spec) eq 'ARRAY';
  my $prev = -1;
  my $intspan = Array::IntSpan->new;
  foreach my $range (@$spec) {
    Carp::croak("StaticMapping spec must be an Array of Arrays, each inner record "
                . "holding range start, end, and weight! This particular record is not an array or does not hold three elements")
      if not ref($range) eq 'ARRAY' and @$range == 3;
    if ($range->[0] != $prev+1) {
      Carp::croak("The lower boundary of any StaticMapping range needs to be one above the end of the previous"
                  ." range or 0 for the first range");
    }
    my $overlapping = $intspan->set_range(@$range);
    die("Assertion fail: range overlap!")
      if $overlapping;
    $prev = $range->[1];
  }

  return $intspan;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

ShardedKV::Continuum::StaticMapping - A continuum strategy based on a simple "significant bits" static mapping

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Continuum::StaticMapping;
  my $skv = ShardedKV->new(
    continuum => ShardedKV::Continuum::StaticMapping->new(
      num_significant_bits => 10, # 2**10 == up to 1024 tables/shards
      from => [
        [0, 255, "shard1"],
        [256, 511, "shard2"],
        [512, 767, "shard3"],
        [768, 1023, "shard4"],
      ], FIXME!?
    ),
    storages => {...},
  );

If you ever wanted to add shards to a cluster that uses StaticMapping,
you can't (currently) use "extend" to add more shards, you have to do
something like this:

  # given the above example ShardedKV and StaticMapping:
  my $cont = $skv->continuum;
  # Let's split shard2 into shard2 and shard2-1
  my $new_cont_spec = [
    [0, 255, "shard1"],
    [256, 383, "shard2"],
    [384, 511, "shard2-1"],
    [512, 767, "shard3"],
    [768, 1023, "shard4"],
  ];
  my $migration_cont = ShardedKV::Continuum::StaticMapping->new(
    num_significant_bits => $cont->num_significant_bits,
    from => $new_cont_spec,
  );
  $skv->begin_migration($migration_cont);
  ... passive or active migration taking place from shard2 to shard2-1...
  $skv->end_migration();

=head1 DESCRIPTION

A sharding strategy that skips the consistent hashing step and simply uses
the first N bits of the key to decide which shard the key falls in.

B<Do not use this sharding strategy unless your key space is naturally
evenly populated. This is generally only true if you use some sort of
randomly generated key WHOSE RANDOMNESS YOU CAN RELY ON. Do realize that if
an untrusted client or component has the ability to choose its own key, then
this sharding strategy opens up a denial of service attack vector by
defeating your sharding altogether.>

If in doubt, use L<ShardedKV::Continuum::Ketama> instead.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Continuum>

=item *

L<Array::IntSpan>

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
