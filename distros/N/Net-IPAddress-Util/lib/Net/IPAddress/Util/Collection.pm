package Net::IPAddress::Util::Collection;

use strict;
use warnings;
use 5.010;

require Net::IPAddress::Util;
require Net::IPAddress::Util::Collection::Tie;
require Net::IPAddress::Util::Range;

sub new {
  my $class    = ref($_[0]) ? ref(shift()) : shift;
  my @contents = @_;
  my @o;
  tie @o, 'Net::IPAddress::Util::Collection::Tie', \@contents;
  return bless \@o => $class;
}

sub sorted {
  my $self = shift;
  # In theory, a raw radix sort is O(N), which beats Perl's O(N log N) by
  # a fair margin. However, it _does_ discard duplicates, so ymmv.
  # FIXME Should we sort by hi, lo instead of lo, hi?
  my $from = [ map { [ unpack('C32', $_->{ lower }->{ address } . $_->{ upper }->{ address }) ] } @$self ];
  my $to;
  for (my $i = 31; $i >= 0; $i--) {
    $to = [];
    for my $card (@$from) {
      push @{$to->[ $card->[ $i ] ]}, $card;
    }
    $from = [ map { @{$_ // []} } @$to ];
  }
  my @rv = map {
    my $n = $_;
    my $l = Net::IPAddress::Util->new([@{$n}[0 .. 15]]);
    my $r = Net::IPAddress::Util->new([@{$n}[16 .. 31]]);
    my $x = Net::IPAddress::Util::Range->new({ lower => $l, upper => $r });
    $x;
  } @$from;
  return $self->new(@rv);
}

sub compacted {
  my $self = shift;
  my @sorted = @{$self->sorted()};
  my @compacted;
  my $elem;
  while ($elem = shift @sorted) {
    if (scalar @sorted and $elem->{ upper } >= $sorted[0]->{ lower } - 1) {
      $elem = ref($elem)->new({ lower => $elem->{ lower }, upper => $sorted[0]->{ upper } });
      shift @sorted;
      redo;
    }
    else {
      push @compacted, $elem;
    }
  }
  return $self->new(@compacted);
}

sub tight {
  my $self = shift;
  my @tight;
  map { push @tight, @{$_->tight()} } @{$self->compacted()};
  return $self->new(@tight);
}

sub as_cidrs {
  my $self = shift;
  return map { $_->as_cidr() } grep { eval { $_->{ lower } } } @$self;
}

sub as_netmasks {
  my $self = shift;
  return map { $_->as_netmask() } grep { eval { $_->{ lower } } } @$self;
}

sub as_ranges {
  my $self = shift;
  return map { $_->as_string() } grep { eval { $_->{ lower } } } @$self;
}

1;

__END__

=head1 NAME

Net::IPAddress::Util::Collection - A collection of Net::IPAddress::Util::Range objects

=head1 VERSION

Version 3.033

=head1 SYNOPSIS

  use Net::IPAddress::Util::Collection;

  my $collection = Net::IPAddress::Util::Collection->new();

  while (<>) {
    last if !defined($_);
    push @$collection, $_ if $_;
  }

  print join ', ', $collection->tight->as_ranges;

=head1 DESCRIPTION

Sometimes when dealing with IP Addresses, it can be nice to talk about groups
of them as whole collections of addresses without worrying that the group is
exactly a CIDR-compatible range, or even whether the group is contiguous.

This is what Net::IPAdress::Util::Collection is for. Objects of this class act
as type-checked ARRAYREFs where every entry must be some kind of IP Address
data (either a single address or an arbitrary range).

Knowing that the data within are type-checked (and knowing their specific 
type), we can do a few extra things to the ARRAYREF as a whole that we could 
not (read I<probably should not>) do to general untyped arrays. Things such as
sorting them via a Radix Sort (which is faster than Perl's builtin sort()),
and being able to smoosh together IP ranges that touch or overlap. What is
more, since we know all IP ranges are ultimately collections of CIDR-compatible
ranges (even if any given range does not start / stop on a legal CIDR boundary)
and use that knowledge to extract precisely the CIDRs that match the collection.

=head1 CLASS METHODS

=head2 new

Create a new Collection object. Takes zero or more arguments, each of which
must be either a L<Net::IPAddress::Util::Range> object, or something which can
be coerced into one (such as a L<Net::IPAddress::Util> object, or something
which can in turn be used to construct one).

=head1 OBJECT METHODS

=head2 sorted

Return a clone of this object, sorted ascendingly by IP address. In the case of
ranges that have the same lower address, ties are broken by the upper address.

=head2 compacted

Return a clone of this object, sorted ascendingly by IP address, with
adjacent ranges combined together. This uses $self-E<gt>sorted, so the same
notice about sort order applies.

=head2 tight

Return a clone of this object, compacted and then split on precise legal CIDR
boundaries. The number of CIDR-compatible ranges returned may be less than,
more than, or in rare cases the same as the number of elements in the original
Collection object. Such is the CIDR nature.

=head2 as_ranges

Returns an array of stringified (x .. y) style ranges.

=head2 as_cidrs

Returns an array of stringified CIDR-style strings. In the case where one 
element of the Collection cannot be legally represented as a CIDR, you will get
in its place the smallest single legal CIDR that contains that element.

In other words, if you want complete accuracy, you will want to use:

  $collection->tight->as_cidrs;

=head2 as_netmasks

Returns an array of stringified Netmask-style strings. In the case where one 
element of the Collection cannot be legally represented as a Netmask string, 
you will get in its place the smallest single legal Netmask string that 
contains that element.


In other words, if you want complete accuracy, you will want to use:

  $collection->tight->as_netmasks;

=cut

