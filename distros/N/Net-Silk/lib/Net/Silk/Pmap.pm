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

package Net::Silk::Pmap;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );
use Net::Silk::IPSet;

use Scalar::Util qw( refaddr );

use overload (
  '%{}'  => \&_me_hash,
  '<>'   => \&_fh_iter,
  '""'   => sub { refaddr shift },
);

my %Attr;

use constant HASH           => 0;
use constant LABELS         => 1;
use constant FH_ITER        => 2;
use constant HASH_ITER      => 3;
use constant MAX_LABEL_SIZE => 4;
use constant LABELS_ADDED   => 5;

###

my %Defaults = (
  type    => SILK_PMAP_TYPE_IPV4,
  name    => undef,
  default => "UNKNOWN",
);

sub new {
  my $class = shift;
  my %parms = (%Defaults, @_);
  for my $k (keys %parms) {
    croak "unknown parameter '$k'" unless exists $Defaults{$k};
  }
  my $self = $class->_init;
  if ($parms{type} eq "ipv4" || $parms{type} eq "IPv4-address") {
    $parms{type} = SILK_PMAP_TYPE_IPV4;
  }
  elsif ($parms{type} eq "ipv6" || $parms{type} eq "IPv6-address") {
    $parms{type} = SILK_PMAP_TYPE_IPV6;
  }
  elsif ($parms{type} eq "protoport" || $parms{type} eq "proto-port") {
    $parms{type} = SILK_PMAP_TYPE_PROTO_PORT;
  }
  if (! ($parms{type} == SILK_PMAP_TYPE_IPV4 ||
         $parms{type} == SILK_PMAP_TYPE_IPV6 ||
         $parms{type} == SILK_PMAP_TYPE_PROTO_PORT) ) {
    die "unknown pmap content type: $parms{type}";
  }
  for my $p (qw(type default)) {
    $parms{$p} = $Defaults{$p} unless defined $parms{$p};
  }
  $self->_set_content_type($parms{type});
  $self->_set_default($parms{default}) if defined $parms{default};
  $self->_set_name($parms{name}) if defined $parms{name};
  my $type = $self->_get_content_type;
  if ($type == SILK_PMAP_TYPE_IPV4) {
    bless $self, "Net::Silk::Pmap::IPv4";
  }
  elsif ($type == SILK_PMAP_TYPE_IPV6) {
    bless $self, "Net::Silk::Pmap::IPv6";
  }
  elsif ($type == SILK_PMAP_TYPE_PROTO_PORT) {
    bless $self, "Net::Silk::Pmap::ProtoPort";
  }
  else {
    die "unknown pmap content type: $type";
  }
  $Attr{$self}->[MAX_LABEL_SIZE] = length($parms{default} || "UNKNOWN");
  $self;
}

sub load {
  my $class = shift;
  my $self  = $class->_load(@_);
  my $type  = $self->_get_content_type;
  if ($type == SILK_PMAP_TYPE_IPV4) {
    bless $self, "Net::Silk::Pmap::IPv4";
  }
  elsif ($type == SILK_PMAP_TYPE_IPV6) {
    bless $self, "Net::Silk::Pmap::IPv6";
  }
  elsif ($type == SILK_PMAP_TYPE_PROTO_PORT) {
    bless $self, "Net::Silk::Pmap::ProtoPort";
  }
  else {
    die "unknown pmap content type: $type";
  }
  $Attr{$self}->[MAX_LABEL_SIZE] = $self->_get_max_label_size;
  $self;
}

sub get_type {
  my $self = shift;
  my $type = $self->_get_content_type;
  if ($type == SILK_PMAP_TYPE_IPV4) {
    return 'ipv4';
  }
  elsif ($type == SILK_PMAP_TYPE_IPV6) {
    return 'ipv6';
  }
  elsif ($type == SILK_PMAP_TYPE_PROTO_PORT) {
    return 'protoport';
  }
  else {
    croak "unknown pmap content type: $type";
  }
}

sub _is_ipaddr {
  my $self = shift;
  my $type = $self->_get_content_type;
  $type == SILK_PMAP_TYPE_IPV4 || $type == SILK_PMAP_TYPE_IPV6;
}

sub _set_default {
  my $self  = shift;
  my $label = shift || croak "label required";
  my $attr = $Attr{$self} ||= [];
  $attr->[MAX_LABEL_SIZE] = length($label)
      if length($label) > ($attr->[MAX_LABEL_SIZE] || 0);
  my $val = $self->_get_or_insert_label($label);
  $self->_set_default_value($val);
}

sub get {
  my $self = shift;
  # hash iter returns [hi,lo] keys
  if (ref $_[0] eq 'ARRAY') {
    $_[0] = $_[0]->[0];
  }
  my $label = ($Attr{$self} ||= [])->[LABELS] ||= {};
  my $val = $self->get_val($_[0]);
  return unless defined $val;
  $label->{$val}
    ||= $self->_val_to_label($val, $Attr{$self}->[MAX_LABEL_SIZE]);
}

sub get_range {
  my $self = shift;
  SILK_RANGE_CLASS->new($self->_get_range(@_));
}

sub _fh_iter {
  my $self = shift;
  my $iter = ($Attr{$self} ||= [])->[FH_ITER] ||= $self->iter;
  if (wantarray) {
    $Attr{$self}[FH_ITER] = undef;
    return $iter->();
  }
  else {
    while ($_ = $iter->()) {
      return $_;
    }
    $Attr{$self}[FH_ITER] = undef;
    return;
  }
}

sub iter {
  my $self = shift;
  my $iter = Net::Silk::Pmap::iter_xs->bind($self);
  my $label = ($Attr{$self} ||= [])->[LABELS] ||= {};
  my($next, $range_class);
  if ($self->_is_ipaddr) {
    $next = \&Net::Silk::Pmap::iter_xs::next_ip;
  }
  else {
    $next = \&Net::Silk::Pmap::iter_xs::next_pp;
  }
  my @items;
  sub {
    while (my @block = $next->($iter)) {
      my $r = SILK_RANGE_CLASS->new($block[0], $block[1]);
      my $val = $block[2];
      $val = $label->{$val}
        ||= Net::Silk::Pmap::_val_to_label($self, $val,
                                           $Attr{$self}->[MAX_LABEL_SIZE]);
      if (wantarray) {
        push(@items, [$r, $val]);
      }
      else {
        return [$r, $val];
      }
    }
    return @items if wantarray;
  };
}

*iter_ranges = *iter_pmap = \&iter;

sub iter_vals {
  my $self = shift;
  my $max  = $self->val_count - 1;
  my $label = ($Attr{$self} ||= [])->[LABELS] ||= {};
  my $c = 0;
  sub {
    if (wantarray) {
      my @items;
      foreach (0 .. $max) {
        push(@items,
          $label->{$_}
            ||= Net::Silk::Pmap::_val_to_label(
                  $self, $_, $Attr{$self}->[MAX_LABEL_SIZE]));
      }
      return @items;
    }
    while ($c <= $max) {
      my $val = $label->{$c}
        ||= Net::Silk::Pmap::_val_to_label($self, $c,
                                           $Attr{$self}->[MAX_LABEL_SIZE]);
      ++$c;
      return $val;
    }
    return;
  };
}

sub iter_keys {
  my $self = shift;
  my $iter = $self->iter;
  sub {
    $iter || return;
    if (wantarray) {
      my @keys;
      while (my $r = $iter->()) {
        push(@keys, $r->[0]);
      }
      $iter = undef;
      return @keys;
    }
    else {
      while (my $r = $iter->()) {
        return $r->[0];
      }
      $iter = undef;
      return;
    }
  };
}

sub _parse_entry {
  my $class = shift;
  my($range, $lo, $hi, $label);
  if (@_ == 1) {
    if (@{$_[0]} == 2) {
      ($range, $label) = @{shift()};
      $range = $class->_parse_range($range);
      eval { ($lo, $hi) = ($range->first, $range->last) };
      if ($@) {
        ($lo, $hi) = @$range;
      }
    }
    else {
      ($lo, $hi, $label) = @{shift()};
    }
  }
  elsif (@_ == 2) {
    ($range, $label) = @_;
    $range = $class->_parse_range($range);
    eval { ($lo, $hi) = ($range->first, $range->last) };
    if ($@) {
      ($lo, $hi) = @$range;
    }
  }
  else {
    ($lo, $hi, $label) = @_;
  }
  return($lo, $hi, $label);
}

sub add {
  my $self = shift;
  my($lo, $hi, $label) = $self->_parse_entry(@_);
  my $val = $self->_get_or_insert_label($label);
  $self->_add_range($lo, $hi, $val);
  my $attr = $Attr{$self} ||= [];
  my $labels = $attr->[LABELS_ADDED] ||= {};
  if (! exists $labels->{$label}) {
    ++$labels->{$label};
    if (length $label > $attr->[MAX_LABEL_SIZE] || 0) {
      $attr->[MAX_LABEL_SIZE] = length $label;
    }
  }
}

sub add_all {
  my $self = shift;
  my $key_class;
  my $type = $self->_get_content_type;
  if ($type == SILK_PMAP_TYPE_IPV4) {
    $key_class = SILK_IPV4ADDR_CLASS;
  }
  elsif ($type == SILK_PMAP_TYPE_IPV6) {
    $key_class = SILK_IPV6ADDR_CLASS;
  }
  elsif ($type == SILK_PMAP_TYPE_PROTO_PORT) {
    $key_class = SILK_PROTOPORT_CLASS;
  }
  else {
    croak "unknown pmap content type: $type\n";
  }
  my $original_ranges = shift;
  my @ranges;
  for my $range (@$original_ranges) {
    my($lo, $hi, $label) = $self->_parse_entry($range);
    $lo = $key_class->new($lo);
    $hi = $key_class->new($hi);
    push(@ranges, [$lo, $hi, $label]);
  }
  for my $range (map  { $_->[1] }
                 sort { $b->[0] <=> $a->[0] } 
                 map  { [$_->[0]->distance($_->[1]), $_] } @ranges) {
    $self->add($range);
  }
}

sub invert {
  my $self = shift;
  my $iter = $self->iter;
  my %sets;
  if ($self->_is_ipaddr) {
    while (my $r = $iter->()) {
      my $s = $sets{$r->[-1]} ||= SILK_IPSET_CLASS->new;
      $s->add_range(@{$r->[0]});
    }
  }
  else {
    while (my $r = $iter->()) {
      my $s = $sets{$r->[-1]} ||= [];
      push(@$s, $r->[0]);
    }
  }
  wantarray ? %sets : \%sets;
}

sub _me_hash {
  my $self = shift;
  my $attr = $Attr{$self} ||= [];
  my $hash = $attr->[HASH];
  if (!$hash) {
    $hash = $attr->[HASH] = {};
    tie(%$hash, $self);
  }
  $hash;
}

sub DESTROY {
  my $self = shift;
  delete $Attr{$self};
  Net::Silk::Pmap::_destroy($self);
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

*FETCH = \&get;

sub EXISTS { defined( shift->get(@_) ) ? 1 : 0 }

sub FIRSTKEY {
  my $self = shift;
  my $attr = $Attr{$self} ||= [];
  $attr->[HASH_ITER] = $self->iter_keys();
  $self->NEXTKEY();
}

sub NEXTKEY {
  my $self = shift;
  my $attr = $Attr{$self} ||= [];
  my $iter = $attr->[HASH_ITER] ||= $self->iter_keys();
  my $v = $iter->();
  defined $v ? $v : ($attr->[HASH_ITER] = undef);
}

###

package Net::Silk::Pmap::IPv4;

use strict;
use warnings;
use Carp;

use base qw( Net::Silk::Pmap );

use Net::Silk qw( :basic );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_, type => $class->SILK_PMAP_TYPE_IPV4);
  bless $self, $class;
}

sub _parse_range {
  my $class = shift;
  my $range = shift;
  if ($range =~ /\//) {
    $range = SILK_CIDR_CLASS->new($range);
  }
  elsif ($range =~ /-/) {
    $range = SILK_RANGE_CLASS->new($range);
  }
  return $range;
}

sub get_cidr {
  my $self = shift;
  my $key  = shift;
  for my $cidr ($self->get_range($key)->as_cidr) {
    return $cidr if $cidr->contains($key);
  }
}

sub iter_cidr {
  my $self = shift;
  my $iter = $self->iter_ranges;
  my($block, @cidr, @items);
  sub {
    while ($block ||= $iter->()) {
      @cidr = $block->[0]->as_cidr unless @cidr;
      while (my $c = shift @cidr) {
        if (wantarray) {
          push(@items, [$c, $block->[1]]);
          next;
        }
        else {
          return [$c, $block->[1]];
        }
      }
      $block = undef;
    }
    return @items if wantarray;
  };
}

###

package Net::Silk::Pmap::IPv6;

use strict;
use warnings;
use Carp;

use base qw( Net::Silk::Pmap::IPv4 );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_, type => $class->SILK_PMAP_TYPE_IPV6);
  bless $self, $class;
}

###

package Net::Silk::Pmap::ProtoPort;

use strict;
use warnings;
use Carp;

use base qw( Net::Silk::Pmap );

use Net::Silk qw( :basic );
use Net::Silk::ProtoPort;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_, type => $class->SILK_PMAP_TYPE_PROTO_PORT);
  bless $self, $class;
}

sub _parse_range {
  my $class = shift;
  my $range = shift;
  my($lo, $hi);
  if ($range =~ /-/) {
    $range = SILK_RANGE_CLASS->new($range);
  }
  return $range;
}

sub get {
  my $self = shift;
  # hash iter returns [hi,lo] keys
  my $pp;
  if (ref $_[0] eq 'ARRAY' &&
      UNIVERSAL::isa($_[0]->[0], SILK_PROTOPORT_CLASS)) {
    $pp = $_[0]->[0];
  }
  elsif (@_ == 1 && UNIVERSAL::isa($_[0], SILK_PROTOPORT_CLASS)) {
    $pp = $_[0];
  }
  else {
    $pp = SILK_PROTOPORT_CLASS->new(@_);
  }
  $self->SUPER::get($pp);
}

*FETCH = \&get;

###

1;

__END__

=head1 NAME

Net::Silk::Pmap - SiLK Prefix Map interface

=head1 SYNOPSIS

  use Net::Silk::Pmap;
  use Net::Silk::IPSet;

  my $addys  = Net::Silk::IPSet->load("netblocks.set");
  my $labels = Net::Silk::Pmap->load("services.pmap");

  while (my $ip = <$addys>) {
    my $svc = $labels{$ip}; # or $labels->get($ip)
    print "$ip $svc" unless $svc eq 'UNKNOWN';
  }

  while (my $entry = <$labels>) {
    my($range, $label) = @$entry;
    my $block = Net::Silk::IPSet->new($range);
    if ($block && $addys) {
      # intersects
      print "$range $label\n";
    }
  }

  # or build from scratch

  my $pm = Net::Silk::IPSet::IPv4->new(
    name    => "my ipv4",
    default => "external",
  );
  $pm->add("1.2.2.1", "1.2.3.255" => "lab servers");
  $pm->add("5.6.7.8/27" => "wombat enclave");
  $pm->add("10.11.1.1-10.11.1.255" => "front office");
  $pm->save("my_addys.pmap");

=head1 DESCRIPTION

C<Net::Silk::Pmap> objects are an interface to SiLK Prefix Maps. Prefix
maps are an immutable mapping from IP addresses or protocol/port pairs
to labels. Pmap objects are created from SiLK prefix map files which in
turn are created by L<rwpmapbuild(1)>.

=head1 METHODS

=over

=item new(%parms)

Note that a more typical usage is to invoke C<new()> from the specific
class for the pmap type of interest, notably one of
L<Net::Silk::Pmap::IPv4>, L<Net::Silk::Pmap::IPv6>, or
L<Net::Silk::Pmap::ProtoPort>.

Parameters passed to C<new()> can be any of:

=over

=item type

Type of pmap to create, one of 'ipv4', 'ipv6', or 'protoport'. See above
about using type-specific classes instead. Defaults to 'ipv4'.

=item name

Optional name of this pmap.

=item default

Default label for unspecified ranges. Defaults to 'UNKNOWN'.

=back

=item load($pmap_file)

Returns a new C<Net::Silk::Pmap::IPv4>, C<Net::Silk::Pmap::IPv6>, or
C<Net::Silk::Pmap::ProtoPort> object, depending what type of keys the
file uses for its pmap.

=item get_name()

Return the name of this pmap.

=item get_type()

Return the type of this pmap, one of 'ipv4', 'ipv6', or 'protoport'.

=item get($proto, $port)

=item get($ip_or_pp)

Returns the label for the given IP address or protocol/port pair. For
the single argument version, the key can be a L<Net::Silk::IPAddr>
object or a L<Net::Silk::ProtoPort> object, or a string representation
of either.

=item get_range($key)

Return a L<Net::Silk::Range> object representing the range containing
the given key with high and low L<Net::Silk::IPAddr> or
L<Net::Silk::ProtoPort> values.

=item add($range_or_cidr, $label)

=item add($lo, $hi, $label)

Add a label to a range, specified either as a L<Net::Silk::CIDR> or
L<Net::Silk::Range> object, string (IP range or cidr, or port/proto
pair) or as the low and hi values. NOTE: Nested ranges are allowed as
long as the larger range is added first. The C<add_all()> method will
properly sort these for you. Overlapping ranges are not allowed.

=item add_all(\@ranges)

Add a list of ranges and their associated labels to the pmap, properly
sorting them along the way such that larger ranges are added first. Each
entry to be added can be one of C<[$range_or_cidr, $label]>, C<[[$hi,
$low], $label]>, or C<[$hi, $lo, $label]>.

=item iter_ranges()

=item iter()

Returns a sub ref iterator. Each invocation returns L<Net::Silk::Range>
key paired with a label. The first/last pairs in the range object are
one of L<Net::Silk::IPAddr> or L<Net::Silk::ProtoPort> objects depending
on the type of pmap file. Using the IO operator C<E<lt>$pmE<gt>> on the
pmap reference will also iterate over range/label values. See on of the
ip-specific classes for C<cidr_iter()>. The iterator will return all
values if invoked in list context. Using the pmap as a filehandle with
C<E<lt>$pmapE<gt>> will return the same values.

=item iter_vals()

Returns a sub ref iterator that returns each label value in the pmap.
The iterator returns all values when invoked in list context.

=item iter_keys()

Returns a sub ref iterator that returns a L<Net::Silk::Range> key for
each range present in the pmap. The iterator returns all keys when
invoked in list context.

=item invert()

For an IP address pmap, return a hash that maps labels to
L<Net::Silk::IPSet> objects representing the all of the IP ranges
for that label. For a protocol/port pmap, return a hash mapping
labels to a list of all the proto/port ranges for that label.

=back

=head1 IPv4 AND IPv6 METHODS

The L<Net::Silk::Pmap::IPv4> and L<Net::Silk::Pmap::IPv6> classes have
some additional methods specific to IP addresses:

=over

=item iter_cidr()

Returns a sub ref that when invoked returns an array ref containing a
L<Net::Silk::CIDR> block along with its associated label. The iterator
will return all pairs when invoked in list context.

=item get_cidr($key)

Return a L<Net::Silk::CIDR> object representing the block containing the
given IP address.

=back

=head1 OPERATORS

The IO operator C<E<lt>E<gt>> works on C<Net::Silk::Pmap> references,
returning the same results as the iterator returned from the
C<iter()> method.

=head1 TIED HASH

The pmap reference can be treated as a hash reference, so that
C<$pmap-E<gt>{$key}>, C<keys %$pmap>, etc, work as expected.

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
