# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Silk::IPSet;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );
use Net::Silk::IPAddr;
use Net::Silk::IPWildcard;

use Math::Int128 qw( uint128 );
use Math::Int128::die_on_overflow;
use Math::BigInt;

use Symbol();
use Scalar::Util qw( refaddr );

use overload (
  '&'    => \&_and,
  '+'    => \&_and,
  '|'    => \&_or,
  '-'    => \&_sub,
  '^'    => \&_sym,
  '&='   => \&_andu,
  '|='   => \&_oru,
  '-='   => \&_subu,
  '^='   => \&_symu,
  '<=>'  => \&_cmp,
  '>'    => \&_gt,
  '<'    => \&_lt,
  '>='   => \&_ge,
  '<='   => \&_le,
  '=='   => \&_eq,
  '!='   => \&_ne,
  'cmp'  => \&_cmp,
  'gt'   => \&_gt,
  'lt'   => \&_lt,
  'ge'   => \&_ge,
  'le'   => \&_le,
  'eq'   => \&_eq,
  'ne'   => \&_ne,
  #'0+'   => \&cardinality,
  'bool' => \&_bool,
  '<>'   => \&_fh_iter,
  '%{}'  => \&_me_hash,
  '""'   => sub { refaddr shift },
);

my %Attr;

###

sub _parse_set {
  return $_[0] if UNIVERSAL::isa($_[0], __PACKAGE__);
  __PACKAGE__->new(defined $_[0] ? $_[0] : ());
}

sub _parse_item {
  my $item;
  if (! ref $_[0]) {
    eval { $item = SILK_IPADDR_CLASS->new($_[0]) };
    if ($@) {
      eval { $item = SILK_CIDR_CLASS->new($_[0]) };
    }
    if ($@) {
      eval { $item = SILK_RANGE_CLASS->new($_[0]) };
    }
    if ($@) {
      eval { $item = SILK_IPWILDCARD_CLASS->new($_[0]) };
    }
  }
  elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
    if (UNIVERSAL::isa($_[0], SILK_CIDR_CLASS) ||
        UNIVERSAL::isa($_[0], SILK_RANGE_CLASS)) {
      $item = $_[0];
    }
    else {
      # flatten the array
      $item = __PACKAGE__->new(@{$_[0]});
    }
  }
  $item ||= $_[0];
}

sub new {
  my $class = shift;
  my $self = Net::Silk::IPSet::_new(ref $class || $class);
  $self->add(@_) if @_;
  $self;
}

sub copy {
  my $self = shift;
  my $new  = (ref $self)->new;
  Net::Silk::IPSet::_union_update($new, $self);
  $new;
}

sub cardinality {
  my $self = shift;
  my $card;
  eval { $card = $self->_cardinality };
  if ($@) {
    if ($@ =~ /overflow/) {
      # >= UINT64_MAX
      my $thing = $self->_cardinality_as_str;
      eval { $card = uint128($self->_cardinality_as_str) };
      if ($@) {
        if ($@ =~ /overflow/) {
          # UINT128_MAX...except the first call returns 0 which isn't
          # what it's supposed to do, so we catch it below
          $card = Math::BigInt->new($self->_cardinality_as_str);
        }
        else {
          croak $@;
        }
      }
    }
    else {
      croak $@;
    }
  }
  elsif ($card == 0 && $self->iter->()) {
    $card = Math::BigInt->new("0x100000000000000000000000000000000");
  }
  $card;
}

sub add {
  my $self = shift;
  return unless @_;
  foreach (map { _parse_item($_) } @_) {
    if (UNIVERSAL::isa($_, SILK_IPADDR_CLASS)) {
      Net::Silk::IPSet::add_addr($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_CIDR_CLASS)) {
      $self->add_cidr(@$_);
    }
    elsif (UNIVERSAL::isa($_, SILK_RANGE_CLASS)) {
      $self->add_range(@$_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPWILDCARD_CLASS)) {
      Net::Silk::IPSet::add_wildcard($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPSET_CLASS)) {
      Net::Silk::IPSet::_union_update($self, $_);
    }
    else {
      croak "ip address, string, cidr, range, wildcard, or ipset required: $_"
    }
  }
}

sub add_cidr {
  my $self = shift;
  my($addr, $prefix) = @_;
  if (! defined $prefix) {
    eval { ($addr, $prefix) = ($addr->ip, $addr->bits) };
    if ($@) {
      my $cidr = SILK_CIDR_CLASS->new($addr);
      ($addr, $prefix) = @$cidr;
    }
  }
  Net::Silk::IPSet::add_addr($self, $addr, $prefix);
}

sub add_range {
  my $self = shift;
  my($lo, $hi) = @_;
  if (! defined $hi) {
    eval { ($lo, $hi) = ($lo->first, $lo->last) };
    if ($@) {
      my $range = SILK_RANGE_CLASS->new($lo);
      ($lo, $hi) = @$range;
    }
  }
  Net::Silk::IPSet::_add_range($self, $lo, $hi);
}

sub pop {
  my $self = shift;
  my $item = shift;
  if (! defined $item) {
    $item = $self->iter->();
  }
  return () unless defined $item;
  $self->remove($item);
  return $item;
}

sub remove {
  my $self = shift;
  croak "ip address, string, number, or wildcard required"
    unless @_;
  my @items;
  foreach (map { _parse_item($_) } @_) {
    if (UNIVERSAL::isa($_, SILK_IPADDR_CLASS)) {
      Net::Silk::IPSet::remove_addr($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPWILDCARD_CLASS)) {
      Net::Silk::IPSet::remove_wildcard($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPSET_CLASS)) {
      Net::Silk::IPSet::_difference_update($self, $_);
    }
    else {
      $_ = SILK_IPSET_CLASS->new($_);
      Net::Silk::IPSet::_difference_update($self, $_);
    }
    push(@items, $_);
  }
  @items;
}

sub update {
  my $self = shift;
  return unless @_;
  foreach (map { _parse_item($_) } @_) {
    if (UNIVERSAL::isa($_, SILK_IPSET_CLASS)) {
      Net::Silk::IPSet::_union_update($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPADDR_CLASS)) {
      Net::Silk::IPSet::add_addr($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPWILDCARD_CLASS)) {
      Net::Silk::IPSet::add_wildcard($self, $_);
    }
    else {
      $_ = SILK_IPSET_CLASS->new($_);
      Net::Silk::IPSet::_union_update($self, $_);
    }
  }
  $self;
}

sub difference_update {
  my $self = shift;
  return unless @_;
  foreach (map { _parse_item($_) } @_) {
    if (UNIVERSAL::isa($_, SILK_IPSET_CLASS)) {
      Net::Silk::IPSet::_difference_update($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPADDR_CLASS)) {
      Net::Silk::IPSet::remove_addr($self, $_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPWILDCARD_CLASS)) {
      Net::Silk::IPSet::remove_wildcard($self, $_);
    }
    else {
      $_ = SILK_IPSET_CLASS->new($_);
      Net::Silk::IPSet::_difference_update($self, $_);
    }
  }
  $self;
}

sub intersection_update {
  my $self = shift;
  if (!@_) {
    $self->clear;
    return;
  }
  my $other = _parse_set(shift);
  $other = $other->union(@_) if @_;
  Net::Silk::IPSet::_intersection_update($self, $other);
  $self;
}

sub symmetric_difference_update {
  my $self = shift;
  return unless @_;
  my $other = _parse_set(shift);
  $other = $other->union(@_) if @_;
  my $int = $self->intersection($other);
  $self->update($other);
  $self->_difference_update($int);
  $self;
}

sub union {
  my $new = shift->copy;
  $new->update(@_);
}

sub difference {
  my $new = shift->copy;
  $new->difference_update(@_);
}

sub intersection {
  my $new = shift->copy;
  $new->intersection_update(@_);
}

sub symmetric_difference {
  my $new = shift->copy;
  my $int = $new->intersection(@_);
  $new->update(@_);
  $new->difference_update($int);
}

sub iter {
  my $self = shift;
  my $iter = Net::Silk::IPSet::iter_xs->bind($self, 0);
  return sub {
    if (wantarray) {
      # keep $self in scope to prevent premature destruction
      no warnings;
      $self;
      my @items;
      while (my $item = Net::Silk::IPSet::iter_xs::next($iter)) {
        push(@items, $item);
      }
      return @items;
    }
    Net::Silk::IPSet::iter_xs::next($iter) || return;
  };
}

sub iter_cidr {
  my $self = shift;
  my $iter = Net::Silk::IPSet::iter_xs->bind($self, 1);
  # workaround for libsilk wildcard bug
  return sub {
    if (wantarray) {
      my @items;
      while (my @block = Net::Silk::IPSet::iter_xs::next($iter)) {
        push(@items, SILK_CIDR_CLASS->new(@block));
      }
      return @items;
    }
    # keep $self in scope to prevent premature destruction
    no warnings;
    $self;
    my @block = Net::Silk::IPSet::iter_xs::next($iter);
    @block ? SILK_CIDR_CLASS->new(@block) : ();
  };
}

sub iter_ranges {
  my $self = shift;
  SILK_CIDR_CLASS->_iter_ranges($self->iter_cidr);
}

sub iter_bag {
  my $self = shift;
  my $iter = Net::Silk::IPSet::iter_xs->bind($self, 0);
  my $item;
  sub {
    if (wantarray) {
      my @counts;
      while (my $ip = $iter->()) {
        push(@counts, [$ip, 1]);
      }
      return @counts;
    }
    else {
      my $item = Net::Silk::IPSet::iter_xs::next($iter) || return;
      return [$item, 1];
    }
  };
}

sub as_bag {
  my $self = shift;
  my $bag = Net::Silk::Bag->new_ipaddr;
  $bag->add($self);
  $bag;
}

sub bounds {
  my $self = shift;
  my($first_addr, $last_block);
  my $iter = $self->iter_cidr;
  while (my $block = $iter->()) {
    $first_addr ||= $block->[0];
    $last_block = $block;
  }
  return($first_addr, $last_block->last, $self->cardinality);
}

###

sub is_subset { shift->difference(@_) ? 0 : 1 }

sub is_superset {
  my $self  = shift;
  my $other;
  if (@_ > 1) {
    $other = (ref $self)->new;
    $other->update(@_);
  }
  else {
    $other = _parse_set(shift);
  }
  $other->difference($self) ? 0 : 1;
}

sub is_disjoint {
  my $self = shift;
  foreach (map { _parse_item($_) } @_) {
    if (UNIVERSAL::isa($_, SILK_IPSET_CLASS)) {
      return 0 unless $self->_is_disjoint_set($_);
    }
    elsif (UNIVERSAL::isa($_, SILK_IPWILDCARD_CLASS)) {
      return 0 unless $self->_is_disjoint_wildcard($_);
    }
    else {
      return 0 if $self->contains($_);
    }
  }
  1;
}

###

sub _or  { $_[0]->union               ($_[1]) }
sub _and { $_[0]->intersection        ($_[1]) }
sub _sym { $_[0]->symmetric_difference($_[1]) }

sub _sub {
  my($l, $r, $reversed) = @_;
  $r = _parse_set($r);
  ($l, $r) = ($r, $l) if $reversed;
  $l->difference($r);
}

sub _oru  { $_[0]->update                     ($_[1]) }
sub _andu { $_[0]->intersection_update        ($_[1]) }
sub _symu { $_[0]->symmetric_difference_update($_[1]) }

sub _subu {
  my($l, $r, $reversed) = @_;
  $r = _parse_set($r);
  ($l, $r) = ($r, $l) if $reversed;
  $l->difference_update($r);
}

sub _bool { defined shift->iter->() ? 1 : 0 }

sub _eq {
  my $self  = $_[0];
  my $other = _parse_set($_[1]);
  $self->is_subset($other) && $self->is_superset($other);
}

sub _ne { ! shift->_eq(@_) }

sub _lt {
  my($l, $r, $reversed) = @_;
  $r = _parse_set($r);
  ($l, $r) = ($r, $l) if $reversed;
  $l->is_subset($r) && $l->_ne($r);
}

sub _gt {
  my($l, $r, $reversed) = @_;
  $r = _parse_set($r);
  ($l, $r) = ($r, $l) if $reversed;
  $l->is_superset($r) && $l->_ne($r);
}

sub _le {
  my($l, $r, $reversed) = @_;
  $r = _parse_set($r);
  ($l, $r) = ($r, $l) if $reversed;
  $l->is_subset($r);
}

sub _ge {
  my($l, $r, $reversed) = @_;
  $r = _parse_set($r);
  ($l, $r) = ($r, $l) if $reversed;
  $l->is_superset($r);
}

sub _cmp {
  return -1 if $_[0] < $_[1];
  return  1 if $_[0] > $_[1];
  0;
}

sub _fh_iter {
  my $self = shift;
  my $iter = $Attr{$self}{fh_iter} ||= $self->iter;
  if (wantarray) {
    delete $Attr{$self}{fh_iter};
    return $iter->();
  }
  else {
    while ($_ = $iter->()) {
      return $_;
    }
    delete $Attr{$self}{fh_iter};
    return;
  }
}

sub _me_hash {
  my $self  = shift;
  my $state = $Attr{$self} ||= {};
  my $hash  = $state->{hash};
  if (!$hash) {
    $hash = $state->{hash} = {};
    tie(%$hash, $self);
  }
  $hash;
}

### tied hash

sub TIEHASH {
  my $class = shift;
  my $self;
  if (ref $class) {
    $self  = $class;
    $class = ref $self;
  }
  else {
    $self = $class->new;
  }
  $self;
}

sub FETCH {
  my $self = shift;
  croak "ip address, string, or number required" unless @_;
  my $item = shift;
  return () unless defined $item;
  $item = SILK_IPADDR_CLASS->new($item) unless ref $item;
  $self->contains($item) ? $item : ();
}

*EXISTS = \&contains;
*CLEAR  = \&clear;
*STORE  = \&add;
*DELETE = \&remove;

sub FIRSTKEY {
  my $self  = shift;
  my $iter = ($Attr{$self} ||= {})->{h_iter} = $self->iter(0);
  $iter->();
}

sub NEXTKEY {
  my $self = shift;
  my $iter = ($Attr{$self} ||= {})->{h_iter} || return $self->FIRSTKEY;
  $iter->() || ($Attr{$self}{iter} = ());
}

sub SCALAR { shift->_str }

###

sub DESTROY {
  my $self = shift;
  delete $Attr{$self};
  $self->_destroy;
}

###

1;

__END__


=head1 NAME

Net::Silk::IPSet - SiLK IP sets

=head1 SYNOPSIS

  use Net::Silk::IPSet;

  $s1 = Silk::IPSet->new(["1.2.3.4", "5.6.7.8"]);
  $s2 = Silk::IPSet->new;
  $s2->add("5.6.7.8");
  $s2 |= "9.10.11.12";

  scalar keys %$s1; # 2
  $s2->cardinality; # 2

  $s1->is_subset($s2);   # false
  $s1->is_superset($s2); # false
  $s1->is_disjoint($s2); # false

  $s3 = $s1 & $s2; # $s1->intersection($s2), 1 element
  $s3 = $s1 | $s2; # $s1->union($s2), 3 elements

  $s3->{"1.2.3.4"}; # $s1->contains("1.2.3.4"), true

  @ip_list = <$s3>;
  @ip_list = keys %$s3;

  while ($ip = <$s3>) {
    print "ip: $ip\n";
  }

  $iter = $s3->iter_cidr;
  while ($cidr = $iter->()) {
    print "$cidr\n";
  }

  $iter = $s3->iter_ranges;
  while ($range = $iter->()) {
    print "$range\n";
  }

  $s3->clear;
  $s3->cardinality; # 0

=head1 DESCRIPTION

C<Net::Silk::IPSet> objects represent a set of IP addresses, as produced
by L<rwset(1)> and L<rwsetbuild(1)>.

=head1 METHODS

A number of the following methods accept a list of I<items> as arguments.
The I<items> can be any of the following:

  * Net::Silk::IPAddr or string representation
  * Net::Silk::IPWildcard or string representation
  * Net::Silk::IPSet
  * Net::Silk::Range or string representation of a range (x.x.x.x-y.y.y.y)
  * Net::Silk::CIDR string representation of a CIDR block (x.x.x.x/n)
  * ref to array of any of the above
  * arbitrary list of any of the above (multiple arguments)

The following methods are available:

=head2 CONSTRUCTORS

=over

=item new(...)

Returns a new C<Net::Silk::IPSet> object. Any arguments are passed to
the C<add()> method of the newly created set, so therefore accepts
an I<item> list as described above.

=item load($file)

Return a new C<Net::Silk::IPSet> object loaded from the given SiLK
IPSet file.

=item copy()

Returns a copy of this IPSet object.

=item save($file)

Save the IPSet as a SiLK IPSet file with the given name.

=back

=head2 QUERY METHODS

=over

=item cardinality()

Return a count of how many IP addresses are in this set.

=item contains($ip)

Return true if the given IP address is present in this set.

=item supports_ipv6()

Return true if this set supports IPv6.

=item is_subset(...)

Return true if this set is a subset of the union of the given
I<item> list.

=item is_superset(...)

Return true if this set is a superset of the union of the given
I<item> list.

=item is_disjoint(...)

Return true if this set has no members in common with the union
of the given I<items>.

=item difference(...)

Return a new C<Net::Silk::IPSet> containing IP addresses in this set but
not in the union of the given I<item> list.

=item intersection(...)

Return a new C<Net::Silk::IPSet> representing IP addresses present in
both this set and the union of the given I<item> list.

=item symmetric_difference(...)

Return a new C<Net::Silk::IPSet> containing IP addresses found in either
this set or the union of the given I<items>, but not both.

=item union(..)

Return a new C<Net::Silk::IPSet> representing IP addresses present in
either this set or the union of the given I<items>.

=item iter()

Return a sub ref iterator that returns each IP address present in this
set as a L<Net::Silk::IPAddr>. These IP addresses can also be obtained
by using the IO operator on this object C<E<lt>$ipsetE<gt>>. In list
context the iterator will produce all addresses.

=item iter_cidr()

Return a sub ref iterator that, upon each invocation, returns
L<Net::Silk::CIDR> object for each CIDR block present in the set. The
iterator will procude all of them in list context.

=item iter_ranges()

Return a sub ref iterator which produces L<Net::Silk::Range> objects
representing each contiguous range present in the set. The iterator will
return all of them in list context.

=back

=head2 MANIPULATION METHODS

A number of the methods below are for a specific type, e.g. ip address,
wildcard, etc. If you know what you have ahead of time, these can be
more efficient since they don't have to do class lookups to determine
what is being added.

=over

=item pop()

Remove and return a random IP address from this set.

=item add(...)

Add all items in the provided list of I<items> to this set.

=item add_addr($ip)

Specifically add an IP address (string or object) to this set.

=item add_cidr($ip, $prefix)

=item add_cidr($cidr)

Specifically add a CIDR block to this set. A single argument can
be provided as a string representation of the CIDR block (x.x.x.x/n).

=item add_range($low, $high)

=item add_range($range)

Specifically add the given range of IP addresses (string or object) to
this set, inclusive. A single argument can be provided as a string
representation of a range (x.x.x.x-y.y.y.y).

=item add_wildcard($wc)

Specifically add an IPwildcard (string or object) to this set.

=item remove(...)

Remove all items in the provided list of I<items> from this set.

=item remove_addr($ip)

Specifically remove an IP address (string or object) from this set.

=item remove_wildcard($wc)

Specifically remove an IPWildcard (string or object) from this set.

=item difference_update(...)

Remove from this set all IP addresses present in the union of the
provided list of I<items>.

=item intersection_update(...)

Remove from this set all IP addresses not present in both this set as
well as the union of the provided list of I<items>.

=item symmetric_difference_update(...)

Update this set, retaining the IP addresses found in this set or
in the union of the provided list of I<items>, but not in both.

=item union_update(...)

=item update(...)

Add to this set all IP addresses present in the given list of I<items>.

=item clear()

Remove all IP addresses from this set.

=item as_bag()

Return the current set as a L<Net::Silk::Bag> with counts for each ip
address set to 1.

=back

=head1 OPERATORS

The following operators are overloaded and work with
C<Net::Silk::IPSet> objects:

  &
  +             ==
  |             !=
  -             cmp
  ^             gt
  &=            lt
  |=            ge
  -=            le
  ^=            eq
  <=>           ne
  >             ""
  <             bool
  >=            <>
  <=            %{}

=head1 TIED HASH

The IPSet object reference can be treated like a hash reference, with
each key being an IP address with a value of 1. So containment can be
tested with C<if ($ipset->{$ip}) { ... }>

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
