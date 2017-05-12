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

package Net::Silk::Bag;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );
use Net::Silk::IPAddr;
use Net::Silk::IPSet;

use Scalar::Util qw( looks_like_number refaddr );

use overload (
#  '|'    => \&_or,
  '-'     => \&_copy_subtract,
  '-='    => \&_subtract,
  '+'     => \&_copy_add,
  '+='    => \&_add,
  '/'     => \&_copy_div,
  '/='    => \&_div,
  '*'     => \&_copy_mul,
  '*='    => \&_mul,
  '&'     => \&_copy_and,
  '&='    => \&_and,
#  '^'    => \&_sym,
#  '|='   => \&_oru,
#  '^='   => \&_symu,
#  '<=>'  => \&_cmp,
#  '>'    => \&_gt,
#  '<'    => \&_lt,
#  '>='   => \&_ge,
#  '<='   => \&_le,
  '=='   => \&_eq,
  '!='   => \&_ne,
#  'cmp'  => \&_cmp,
#  'gt'   => \&_gt,
#  'lt'   => \&_lt,
#  'ge'   => \&_ge,
#  'le'   => \&_le,
  'eq'   => \&_eq,
  'ne'   => \&_ne,
  #'0+'   => \&cardinality,
  'bool' => \&cardinality,
  '<>'   => \&_fh_iter,
  '%{}'  => \&_me_hash,
  '""'   => sub { refaddr shift },
);

use constant SILK_VIRTUAL_BAG_CLASS => 'Net::Silk::VirtualBag';

sub _bagify { SILK_VIRTUAL_BAG_CLASS->new(@_) }

my %Attr;

use constant KEY_FIELD_TYPE => 0;
use constant KEY_FIELD_LEN  => 1;
use constant KEY_TYPE       => 2;
use constant KEY_LABEL      => 3;
use constant CNT_FIELD_TYPE => 4;
use constant CNT_FIELD_LEN  => 5;
use constant CNT_TYPE       => 6;
use constant CNT_LABEL      => 7;
use constant ITER           => 10;
use constant FH_ITER        => 11;
use constant HASH           => 11;

sub _attr_init {
  my $self = shift;
  my $attr = $Attr{$self} ||= [Net::Silk::Bag::_bag_info($self)];
  no warnings;
  $attr;
}

sub _parse_bag {
  my $self = shift;
  my $item = shift;
  if (ref $item) {
    return $item if UNIVERSAL::isa($item, __PACKAGE__);
    if (UNIVERSAL::isa($item, 'HASH') || UNIVERSAL::isa($item, 'ARRAY')) {
      my $new = (ref $self)->new;
      $new->update($item);
      return $new;
    }
  }
  $item = _parse_item($item);
  my $new = (ref $self)->new;
  $new->add($item);
  $new;
}

sub _parse_item {
  my $item = shift;
  if (! ref $item) {
    eval { $item = SILK_IPADDR_CLASS->new($item) };
    if ($@) {
      eval { $item = SILK_IPWILDCARD_CLASS->new($item) };
      if ($@) {
        Carp::confess "ip address, string, or number required: $item";
      }
    }
  }
  $item;
}

my(%Field_Type, %Field_Type_Norm);
for my $ft (
  SILK_BAG_FIELD_SIPv4,
  SILK_BAG_FIELD_DIPv4,
  SILK_BAG_FIELD_SPORT,
  SILK_BAG_FIELD_DPORT,
  SILK_BAG_FIELD_PROTO,
  SILK_BAG_FIELD_PACKETS,
  SILK_BAG_FIELD_BYTES,
  SILK_BAG_FIELD_FLAGS,
  SILK_BAG_FIELD_STARTTIME,
  SILK_BAG_FIELD_ELAPSED,
  SILK_BAG_FIELD_ENDTIME,
  SILK_BAG_FIELD_SID,
  SILK_BAG_FIELD_INPUT,
  SILK_BAG_FIELD_OUTPUT,
  SILK_BAG_FIELD_NHIPv4,
  SILK_BAG_FIELD_INIT_FLAGS,
  SILK_BAG_FIELD_REST_FLAGS,
  SILK_BAG_FIELD_TCP_STATE,
  SILK_BAG_FIELD_APPLICATION,
  SILK_BAG_FIELD_FTYPE_CLASS,
  SILK_BAG_FIELD_FTYPE_TYPE,
  SILK_BAG_FIELD_ICMP_TYPE_CODE,
  SILK_BAG_FIELD_SIPv6,
  SILK_BAG_FIELD_DIPv6,
  SILK_BAG_FIELD_NHIPv6,
  SILK_BAG_FIELD_RECORDS,
  SILK_BAG_FIELD_SUM_PACKETS,
  SILK_BAG_FIELD_SUM_BYTES,
  SILK_BAG_FIELD_SUM_ELAPSED,
  SILK_BAG_FIELD_ANY_PORT,
  SILK_BAG_FIELD_ANY_SNMP,
  SILK_BAG_FIELD_ANY_TIME,
  SILK_BAG_FIELD_CUSTOM,
  SILK_BAG_FIELD_ANY_IPv4,
  SILK_BAG_FIELD_ANY_IPv6) {
  $Field_Type{__PACKAGE__->_field_type_label($ft)} = $ft;
  $Field_Type_Norm{lc(__PACKAGE__->_field_type_label($ft))} = $ft;
}

sub field_types { sort keys %Field_Type }

sub _parse_field_type {
  my $type = shift;
  if ($type !~ /^\d+$/) {
    $type = $Field_Type_Norm{lc($type)};
  }
  my $label = __PACKAGE__->_field_type_label($type);
  ($label, $type);
}

my %Defaults = (
  key_type     => SILK_BAG_FIELD_CUSTOM,
  key_len      => 0,
  counter_type => SILK_BAG_FIELD_CUSTOM,
  counter_len  => 0,
  mapping      => undef,
);

sub new {
  my($class, %opt) = @_;
  foreach (keys %opt) {
    if (! exists $Defaults{$_}) {
      croak "unknown keyword param '$_'";
    }
  }
  if (ref $class) {
    my $orig = $class;
    $class   = ref $class;
    if (! UNIVERSAL::isa($class, __PACKAGE__)) {
      croak "invalid type $class\n";
    }
    my $attr = $Attr{$orig} ||= _attr_init($orig);
    $opt{key_type} = $attr->[KEY_FIELD_TYPE]
      unless defined $opt{key_type};
    $opt{key_len} = $attr->[KEY_FIELD_LEN]
      unless defined $opt{key_len};
    $opt{counter_type} = $attr->[CNT_FIELD_TYPE]
      unless defined $opt{counter_type};
    $opt{counter_len} = $attr->[CNT_FIELD_LEN]
      unless defined $opt{counter_len};
  }
  if (! defined $opt{key_type}) {
      $opt{key_type} = SILK_IPV6_ENABLED ? SILK_BAG_FIELD_ANY_IPv6
                                         : SILK_BAG_FIELD_ANY_IPv4;
  }
  $opt{counter_type} = $Defaults{counter_type}
    unless defined $opt{counter_type};
  $opt{key_len} = $Defaults{key_len}
    unless defined $opt{key_len};
  $opt{counter_len} = $Defaults{counter_len}
    unless defined $opt{counter_len};

  my($label, $type);
  ($label, $type) = _parse_field_type($opt{key_type});
  defined $type || croak("invalid key type: $opt{key_type}");
  $opt{key_type} = $type;
  ($label, $type) = _parse_field_type($opt{counter_type});
  defined $type || croak("invalid counter type: $opt{counter_type}");
  $opt{counter_type} = $type;

  my $self = $class->init(@opt{'key_type', 'key_len',
                               'counter_type', 'counter_len'});
  $Attr{$self} = _attr_init($self);
  $self->update($opt{mapping}) if $opt{mapping};
  $self;
}

sub new_ipaddr {
  shift->new(@_, key_type => SILK_IPV6_ENABLED ? SILK_BAG_FIELD_ANY_IPv6
                                               : SILK_BAG_FIELD_ANY_IPv4);
}

sub new_ipv4addr {
  shift->new(@_, key_type => SILK_BAG_FIELD_ANY_IPv4);
}

sub new_integer { shift->new(@_, key_type => SILK_BAG_FIELD_CUSTOM) }

sub get_info {
  my $self = shift;
  my $attr = $Attr{$self} ||= _attr_init($self);
  my %info = (
    key_type     => $attr->[KEY_LABEL],
    key_len      => $attr->[KEY_FIELD_LEN],
    counter_type => $attr->[CNT_LABEL],
    counter_len  => $attr->[CNT_FIELD_LEN],
  );
  wantarray ? %info : \%info;
}

sub set_info {
  my $self = shift;
  my %parm = @_;
  my $attr = $Attr{$self} ||= _attr_init($self);
  if (%parm) {
    my($key_label, $key_type, $cnt_label, $cnt_type, $key_len, $cnt_len);
    if (defined $parm{key_type}) {
      ($key_label, $key_type) = _parse_field_type(delete $parm{key_type});
    }
    if (defined $parm{counter_type}) {
      ($cnt_label, $cnt_type) = _parse_field_type(delete $parm{counter_type});
    }
    $key_type = defined $key_type ? $key_type : $attr->[KEY_FIELD_TYPE];
    $cnt_type = defined $cnt_type ? $cnt_type : $attr->[CNT_FIELD_TYPE];
    $key_len  = delete $parm{key_len} || $attr->[KEY_FIELD_LEN];
    $cnt_len  = delete $parm{counter_len} || $attr->[CNT_FIELD_LEN];
    croak "unknown field for setting" if %parm;
    $self->_modify($key_type, $cnt_type, $key_len, $cnt_len);
    delete $Attr{$self};
  }
  $self->get_info;
}

sub type_merge {
  my $class = shift;
  $class = ref $class if ref $class;
  my($type1, $type2) = @_;
  $type1 = _parse_field_type($type1);
  $type2 = _parse_field_type($type2);
  my $type = $class->_type_merge($type1, $type2);
  $class->_field_type_label($type);
}

sub _key_type_merge {
  my $self  = shift;
  my $other = shift || croak "other bag ref required";
  my $s_attr = $Attr{$self}  ||= _attr_init($self);
  my $o_attr = $Attr{$other} ||= _attr_init($other);
  (ref $self)->_type_merge($s_attr->[KEY_FIELD_TYPE],
                           $o_attr->[KEY_FIELD_TYPE]);
}

sub key_type_merge {
  my $self = shift;
  my $type = $self->_key_type_merge(@_);
  (ref $self)->_field_type_label($type);
}

sub _merge_to_key_type {
  my $self = shift;
  my $type = $self->_key_type_merge(@_);
  my $attr = $Attr{$self} ||= _attr_init($self);
  if ($attr->[KEY_TYPE] != $type) {
    #croak "autoconvert disabled" unless $self->autoconvert;
    $self->set_info(key_type => $type);
  }
  $self;
}

sub _autoconvert {
  my $self = shift;
  if (@_) {
    $_[0] ? $self->_autoconvert_enable
          : $self->_autoconvert_disable;
  }
  $self->_autoconvert_enabled;
}

sub as_ipset {
  my $self = shift;
  croak("invalid bag key type for ipset") unless $self->_is_ipaddr;
  my $s = SILK_IPSET_CLASS->new;
  my $i = $self->iter_keys;
  while ($_ = $i->()) {
    $s->add($_);
  }
  $s;
}

sub constrain_keys {
  my($self, $min, $max) = @_;
  defined($min) || defined($max) || croak "min or max required";
  my $i = $self->iter;
  while ($_ = $i->()) {
    if ((defined $min && $_->[0] < $min) ||
        (defined $max && $_->[0] > $max)) {
      $self->del($_->[0]);
    }
  }
  $self;
}

sub constrain_values {
  my($self, $min, $max) = @_;
  defined($min) || defined($max) || croak "min or max required";
  my $i = $self->iter;
  while ($_ = $i->()) {
    if ((defined $min && $_->[1] < $min) ||
        (defined $max && $_->[1] > $max)) {
      $self->del($_->[0]);
    }
  }
  $self;
}

sub inversion {
  my $self = shift;
  my $new  = (ref $self)->new_integer();
  my $i = $self->iter;
  while ($_ = $i->()) {
    $new->add($_->[1]);
  }
  $new;
}

sub get {
  my $self = shift;
  my $key  = shift;
  return unless defined $key;
  Net::Silk::Bag::_get_val($self, $key) || 0;
}

sub set {
  my $self = shift;
  my($key, $val) = ($_[0], $_[1]);
  Net::Silk::Bag::_set_val($self, $key, $val || 0);
}

sub incr {
  my $self = shift;
  my($key, $val) = ($_[0], defined $_[1] ? $_[1] : 1);
  my $res;
  eval { $res = Net::Silk::Bag::_incr_val($self, $key, $val || 1) };
  $res;
}

sub decr {
  my $self = shift;
  my($key, $val) = ($_[0], $_[1] ? $_[1] : 1);
  if (my $cur = $self->get($key)) {
    if ($val >= $cur) {
      $self->del($key);
    }
    else {
      return Net::Silk::Bag::_decr_val($self, $key, $val);
    }
  }
  return;
}

sub del {
  my $self = shift;
  $self->set($_, 0) foreach @_;
}

sub contains {
  my $self = shift;
  return 0 unless @_;
  $self->get($_[0]) ? 1 : 0;
}

sub cardinality {
  my $self = shift;
  my $card;
  eval { $card = $self->_cardinality };
  if ($@) {
    if ($@ =~ /overflow/) {
      die "bag cardinality overflow (too many ipv6 keys)";
    }
    else {
      croak $@;
    }
  }
  $card;
}

sub _fh_iter {
  my $self = shift;
  my $attr = $Attr{$self} ||= _attr_init($self);
  my $iter = $attr->[FH_ITER] ||= $self->iter;
  if (wantarray) {
    delete $attr->[FH_ITER];
    return $iter->();
  }
  else {
    while ($_ = $iter->()) {
      return $_;
    }
    delete $attr->[FH_ITER];
    return;
  }
}

sub iter {
  my($self, $sorted) = @_;
  my $attr = $Attr{$self} ||= _attr_init($self);
  my $key_class = $attr->[KEY_TYPE];
  my $cnt_class = $attr->[CNT_TYPE];
  my $iter = Net::Silk::Bag::iter_xs->bind($self, $sorted);
  sub {
    return unless $iter;
    if (wantarray) {
      my @items;
      while (my @res = Net::Silk::Bag::iter_xs::next($iter, $key_class,
                                                     $cnt_class)) {
        push(@items, \@res);
      }
      $iter = undef;
      return @items;
    }
    # keep $self in scope to prevent premature destruction
    no warnings;
    $self;
    my @res = Net::Silk::Bag::iter_xs::next($iter, $key_class, $cnt_class);
    if (!@res) {
      $iter = undef;
      return;
    }
    \@res;
  };
}

*iter_bag = \&iter;

sub iter_keys {
  my $s = shift->iter;
  sub {
    if (wantarray) {
      my @items;
      while (my $r = $s->()) {
        push(@items, $r->[0]);
      }
      return @items;
    }
    ($s->() || return)->[0];
  };
}

sub iter_vals {
  my $s = shift->iter;
  sub {
    if (wantarray) {
      my @items;
      while (my $r = $s->()) {
        push(@items, $r->[1]);
      }
      return @items;
    }
    ($s->() || return)->[1];
  };
}

sub iter_group {
  my($self, $other) = @_;
  my $i1 = $self->iter(1);
  my $i2 = $self->_parse_bag($other)->iter(1);
  my($k1, $v1, $k2, $v2, $r, @q);
  sub {
    while ($i1 || $i2 || defined($k1) || defined($k2)) {
      if ($i1 && ! defined $k1) {
        if ($r = $i1->()) {
          ($k1, $v1) = @$r;
        }
        else {
          $i1 = undef;
        }
      }
      if ($i2 && ! defined $k2) {
        if ($r = $i2->()) {
          ($k2, $v2) = @$r;
        }
        else {
          $i2 = undef;
        }
      }
      last unless defined $k1 || defined $k2;
      if (! defined $k2) {
        push(@q, [$k1, $v1, undef]);
        $k1 = $v1 =  undef;
      }
      elsif (! defined $k1) {
        push(@q, [$k2, undef, $v2]);
        $k2 = $v2 = undef;
      }
      elsif ($k1 < $k2) {
        push(@q, [$k1, $v1, undef]);
        $k1 = $v1 =  undef;
      }
      elsif ($k1 > $k2) {
        push(@q, [$k2, undef, $v2]);
        $k2 = $v2 = undef;
      }
      else {
        push(@q, [$k1, $v1, $v2]);
        $k1 = $k2 = $v1 = $v2 = undef;
      }
      last unless wantarray;
    }

    if (wantarray) {
      my @qq = @q;
      @q = ();
      return @qq;
    }

    return shift @q while @q;

  };
}

###

sub min {
  my $self  = shift;
  my $other = $self->_parse_bag(shift);
  my $new   = $self->new;
  my $iter  = $self->iter;
  while (my $r = $iter->()) {
    my @items = sort { $a <=> $b } ($r->[1], $other->get($r->[0]));
    $new->set($r->[0], $items[0]);
  }
  $new;
}

sub max {
  my $self  = shift;
  my $other = $self->_parse_bag(shift);
  my $new   = $self->new;
  my $iter = $self->iter;
  while (my $r = $iter->()) {
    my @items = sort { $a <=> $b } ($r->[1], $other->get($r->[0]));
    $new->set($r->[0], $items[1]);
  }
  $iter = $other->iter_bag;
  while (my $r = $iter->()) {
    my @items = sort { $a <=> $b } ($r->[1], $self->get($r->[0]));
    $new->set($r->[0], $items[1]);
  }
  $new;
}

###

sub _item_div {
  #print STDERR "ITEM DIV! ", join(', ', @_), "\n";
  my($bag, $k, $n, $d) = @_;
  if ($d) {
    my $v = int($n / $d);
    my $m = $n % $d;
    $v += 1 if 2 * $m >= $d;
    $bag->set($k, $v);
  }
  else {
    $bag->del($k);
  }
}

sub div {
  my $self = shift;
  while (@_) {
    #print STDERR "\n\n";
    my $map = shift;
    if (my $vbag = _bagify($map)) {
      my($iter, $sz);
      $self->_merge_to_key_type($map)
        if UNIVERSAL::isa($map, SILK_BAG_CLASS);
      $sz = $vbag->cardinality;
      my $new = $self->new;
      if ($self->cardinality > $sz) {
        $iter = $vbag->iter_bag;
        while (my $r = $iter->()) {
          my $v = $self->get($r->[0]) || next;
          _item_div($new, $r->[0], $v, $r->[1]);
        }
      }
      else {
        $iter = $self->iter;
        while (my $r = $iter->()) {
          my $d = $vbag->get($r->[0]) || next;
          _item_div($new, @$r, $d);
        }
      }
      $self->_copy_from($new);
    }
  }
  $self;
}

sub scalar_div {
  my $self = shift;
  my $item = shift;
  croak "non-numeric scalar division unsupported"
    unless ref $item || looks_like_number($item);
  return $self unless $item > 1;
  my $iter = $self->iter;
  while (my $r = $iter->()) {
    _item_div($self, @$r, $item);
  }
  $self;
}

sub _div {
  my($l, $r, $rev) = @_;
  my $vbag = _bagify($r);
  if ($rev) {
    return $vbag ? $r->div($vbag) : $r->scalar_div($l);
  }
  else {
    return $vbag ? $l->div($r) : $l->scalar_div($r);
  }
}

sub _copy_div { shift->copy->_div(@_) }

###

sub _item_mul {
  my($bag, $k, $l, $r) = @_;
  #print STDERR "L($l):", ref $l || "none", " R($r):", ref $r || 'none', "\n";
  ($l, $r) = ($r, $l) if $l < $r;
  my $v = $l * $r;
  #print STDERR "$v\n";
  #print STDERR "ITEM MUL($k): $l * $r == $v\n";
  croak "overflow error" if $v < $l || $r < 0;
  Net::Silk::Bag::_set_val($bag, $k, $v);
}

sub mul {
  my $self = shift;
  while (@_) {
    my $map = shift;
    if (my $vbag = _bagify($map)) {
      my($iter, $sz);
      $self->_merge_to_key_type($map)
        if UNIVERSAL::isa($map, SILK_BAG_CLASS);
      $sz = $vbag->cardinality;
      my $new = $self->new;
      if ($self->cardinality > $sz) {
        $iter = $vbag->iter_bag;
        while (my $r = $iter->()) {
          my $v = $self->get($r->[0]) || next;
          _item_mul($new, $r->[0], $v, $r->[1]);
        }
      }
      else {
        $iter = $self->iter;
        while (my $r = $iter->()) {
          my $m = $vbag->get($r->[0]) || next;
          _item_mul($new, @$r, $m);
        }
      }
      $self->_copy_from($new);
    }
  }
  $self;
}

sub scalar_mul {
  my $self = shift;
  my $item = shift;
  croak "non-numeric scalar multiplication unsupported"
    unless ref $item || looks_like_number($item);
  my $new  = $self->new;
  my $iter = $self->iter;
  while (my $r = $iter->()) {
    _item_mul($new, @$r, $item);
  }
  $new;
}

sub _mul {
  my($l, $r, $rev) = @_;
  my $vbag = _bagify($r);
  return $vbag ? $l->mul($vbag) : $l->scalar_mul($r);
}

sub _copy_mul { shift->copy->_mul(@_) }

###

sub update {
  my $self = shift;
  while (@_) {
    my $map = shift;
    if (my $vbag = _bagify($map)) {
      $self->_merge_to_key_type($map) if UNIVERSAL::isa($map, SILK_BAG_CLASS);
      my $iter = $vbag->iter_bag;
      while (my $r = $iter->()) {
        Net::Silk::Bag::_set_val($self, @$r);
      }
    }
    else {
      Net::Silk::Bag::_set_val($self, $map, 1);
    }
  }
  $self;
}

###

sub intersect {
  my $self = shift;
  my $new = $self->new;
  my($sz, $iter, $map);
  return $self unless $self->cardinality;
  if (!@_) {
    $self->clear;
    return $self;
  }
  while (@_) {
    $map = shift;
    if (my $vbag = _bagify($map)) {
      my($iter, $sz);
      $sz = $vbag->cardinality;
      if (!$sz) {
        $self->clear;
        last;
      }
      if ($self->cardinality > $sz) {
        my $new = $self->new;
        $iter = $vbag->iter_bag;
        while (my $r = $iter->()) {
          my $v = $self->get($r->[0]) || next;
          $new->set($r->[0], $v);
        }
        $self->_copy_from($new);
      }
      else {
        $iter = $self->iter_keys;
        while (my $k = $iter->()) {
          $self->del($k) unless $vbag->contains($k);
        }
      }
    }
    else {
      my $new = $self->new;
      $new->set($map, $self->get($map));
      $self->_copy_from($new);
    }
  }
  $self;
}

sub _and {
  my($l, $r, $rev) = @_;
  ($l, $r) = ($l->_parse_bag($r), $l) if $rev;
  $l->intersect($r);
}

sub _copy_and { shift->copy->_and(@_) }

###

sub complement_intersect {
  my $self = shift;
  return $self unless @_ && $self->cardinality;
  my $new = $self->new;
  while (@_ && $self->cardinality) {
    my $map = shift;
    if (my $vbag = _bagify($map)) {
      my($iter, $sz);
      $sz = $vbag->cardinality || next;
      if ($self->cardinality > $sz) {
        $iter = $vbag->iter_bag;
        while (my $r = $iter->()) {
          $self->del($r->[0]);
        }
      }
      else {
        my $new = $self->new;
        $iter = $self->iter_bag;
        while (my $r = $iter->()) {
          $new->set(@$r) unless $vbag->contains($r->[0]);
        }
        $self->_copy_from($new);
      }
    }
    else {
      $self->del($map);
    }
  }
  $self;
}

###

sub add {
  my $self = shift;
  while (@_) {
    my $map = shift;
    if (my $vbag = _bagify($map)) {
      my $iter;
      if (UNIVERSAL::isa($map, SILK_BAG_CLASS)) {
        #print STDERR "BAG ADD\n";
        Net::Silk::Bag::_add_bag($self, $map);
        next;
      }
      #print STDERR "VBAG ADD\n";
      if ($self->cardinality > $vbag->cardinality) {
        $iter = $vbag->iter_bag;
        while ($_ = $iter->()) {
          $self->incr(@$_);
        }
      }
      else {
        $iter = $self->iter;
        while ($_ = $iter->()) {
          $self->incr($_, $vbag->get($_));
        }
      }
    }
    else {
      #print STDERR "SCALAR ADD $map\n";
      $self->incr($map, 1);
    }
  }
  $self;
}

sub _add {
  my($l, $r, $rev) = @_;
  ($l, $r) = ($l->_parse_bag($r), $l) if $rev;
  $l->add($r);
}

sub _copy_add { shift->copy->add($_[0]) }

###

sub remove {
  my $self = shift;
  while (@_) {
    my $map = shift;
    if (my $vbag = _bagify($map)) {
      my $iter;
      $self->_merge_to_key_type($map)
        if UNIVERSAL::isa($map, SILK_BAG_CLASS);
      if ($self->cardinality > $vbag->cardinality) {
        $iter = $vbag->iter_bag;
        while ($_ = $iter->()) {
          $self->decr(@$_);
        }
      }
      else {
        $iter = $self->iter_keys;
        while ($_ = $iter->()) {
          next unless $vbag->contains($_);
          $self->decr($_, $vbag->get($_));
        }
      }
      next;
    }
    else {
      $self->decr($map, 1);
    }
  }
  $self;
}

sub _subtract {
  my($l, $r, $rev) = @_;
  ($l, $r) = ($l->_parse_bag($r), $l) if $rev;
  $l->remove($r);
}

sub _copy_subtract {
  my($l, $r, $rev) = @_;
  ($l, $r) = ($l->_parse_bag($r), $l) if $rev;
  $l->copy->remove($r);
}

###

sub _eq {
  my $self  = shift;
  return 0 unless @_;
  my $other = $self->_parse_bag(shift);
  return 0 unless $self->cardinality == $other->cardinality;
  my $iter = $self->iter_bag;
  while (my $kv = $iter->()) {
    return 0 unless $other->get($kv->[0]) == $kv->[1];
  }
  1;
}

sub _ne {
  my $self  = shift;
  return 1 unless @_;
  my $other = $self->_parse_bag(shift);
  return 1 if $self->cardinality != $other->cardinality;
  my $iter = $self->iter_bag;
  while (my $kv = $iter->()) {
    my $ov = $other->get($kv->[0]);
    return 1 if $other->get($kv->[0]) != $kv->[1];
  }
  0;
}

###

sub _me_hash {
  my $self = shift;
  my $attr = $Attr{$self} ||= _attr_init($self);
  my $hash = $attr->[HASH];
  if (!$hash) {
    $hash = $attr->[HASH] = {};
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

*FETCH  = \&get;
*EXISTS = \&contains;
*CLEAR  = \&clear;
*STORE  = \&set;
*DELETE = \&del;

sub FIRSTKEY {
  my $self = shift;
  my $attr = $Attr{$self} ||= _attr_init($self);
  my $iter = $attr->[ITER] = $self->iter_keys(0);
  $iter->();
}

sub NEXTKEY {
  my $self = shift;
  my $attr = $Attr{$self} ||= _attr_init($self);
  my $iter = $attr->[ITER] ||= $self->iter_keys(0);
  $iter->();
}

sub SCALAR { shift->_str }

###

sub DESTROY {
  my $self = shift;
  delete $Attr{$self};
  Net::Silk::Bag::_destroy($self);
}

###

package Net::Silk::VirtualBag;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );

sub new {
  my $class = shift;
  my $item  = shift;
  defined $item || croak "inner item required";
  return $item if UNIVERSAL::isa($item => SILK_BAG_CLASS) ||
                  UNIVERSAL::isa($item => $class);
  if (! UNIVERSAL::isa($item => SILK_RANGE_CLASS) &&
      ! UNIVERSAL::isa($item => SILK_CIDR_CLASS)) {
    if (UNIVERSAL::isa($item => 'ARRAY')) {
      my $h = {};
      ++$h->{$_} foreach @$item;
      $item = $h;
    }
    if (UNIVERSAL::isa($item => 'HASH')) {
      my $self = { item => $item };
      bless($self, 'Net::Silk::VirtualBag::Hash');
      return $self;
    }
  }
  return undef unless
    UNIVERSAL::can($item => 'cardinality') &&
    UNIVERSAL::can($item => 'iter_bag')    &&
    UNIVERSAL::can($item => 'contains');
  my $self = { item => $item };
  bless $self, $class;
}

sub cardinality { shift->{item}->cardinality }

sub contains { shift->{item}->contains(@_) }

sub iter_bag { shift->{item}->iter_bag() }

sub get { shift->contains(@_) ? 1 : 0 }

###

package Net::Silk::VirtualBag::Hash;

use strict;
use warnings;
use Carp;

use base qw( Net::Silk::VirtualBag );

sub cardinality { scalar keys %{shift->{item}} }

sub contains {
  my $self = shift;
  exists $self->{item}{shift()};
}

sub iter_bag {
  my $item = shift->{item};
  sub {
    while (my($k,$v) = each %$item) {
      return [$k, $v];
    }
  };
}

sub get {
  my $item = shift->{item};
  $item->{shift()} || 0;
}

###

1;

__END__


=head1 NAME

Net::Silk::Bag - SiLK bag file interface

=head1 SYNOPSIS

  use Net::Silk::Bag;
  use Net::Silk::IPSet;
  use Net::Silk::IPWildcard;

  my $bag1 = Net::Silk::Bag->new_ipaddr;
  $bag1->add('1.1.1.1', '2.2.2.2', '3.3.3.3');
  $bag1->incr('3.3.3.3');

  my $bag2 = Net::Silk::Bag->new_ipaddr;
  $bag2->add('3.3.3.3', '4.4.4.4', '5.5.5.5');

  # intersection
  my $bag3 = $bag1 & $bag2;

  # IO handle
  while (my $kv = <$bag3>) {
    print "$kv->[0] -> $kv->[1]\n";
  }

  # hash interface
  foreach my $key (keys %$bag3) {
    print "$key -> $bag3->{$key}\n";
  }

  # iterator
  my $iter = $bag3->iter;
  while (my $kv = $iter->()) {
    print "$kv->[0] -> $kv->[1]\n";
  }

  # interact with other object types
  my $set   = Net::Silk::IPSet->new('3.3.3.3');
  my $wc    = Net::Silk::IPWildcard->new('3.3.3.3');
  my %hash  = ('3.3.3.3' => 1);
  my @array = qw( 3.3.3.3 );
  my $bag4 = $bag1 & $set;
  my $bag5 = $bag1 & $wc;
  my $bag6 = $bag1 & \%hash;
  my $bag7 = $bag1 & \@array;

=head1 DESCRIPTION

C<Net::Silk::Bag> is a representation of a multiset. Each key represents
a potential element in the set, and the key's value represents the
number of times that key is in the set. As such, it is also a reasonable
representation of a mapping from keys to integers. Despite its
set-like properties, a bag object is not nearly as efficient as
a <Net::Silk::IPSet> when representing large contiguous ranges of
key data.

=head1 METHODS

The following are methods are available for bags:

=head2 CONSTRUCTORS

=over

=item new(...)

Returns a new bag object. Accepts the following keyword arguments:

=over

=item key_type

Type of key to use. Valid types are listed below. Defaults to 'any-IPv6'
if SILK_IPV6_ENABLED is true, otherwise 'any-IPv4'.

=item key_len

Length of key. If not specified, defaults to the default number of
bytes for the given key type.

=item counter_type

Type of counter to use. Valid types are listed below. Defaults to 'custom'.

=item counter_len

Length of the counter type. Currently this defaults to 8, which is the
only valid value so far.

=item mapping

Values with which to initialize the bag. This can be a reference to
a hash, array, or L<Net::Silk::IPSet>. In the latter two cases, the
count values are set to 1.

=back

Valid key and counter types are:

=over

  sIPv4                 class
  dIPv4                 type
  sPort                 icmpTypeCode
  dPort                 sIPv6
  protocol              dIPv6
  packets               nhIPv6
  bytes                 records
  flags                 sum-packets
  sTime                 sum-bytes
  duration              sum-duration
  eTime                 any-port
  sensor                any-snmp
  input                 any-time
  output                custom
  nhIPv4                any-IPv4
  initialFlags          any-IPv6
  sessionFlags          application
  attributes

=back

=item new_ipaddr()

Creates a bag using 'any-ipv6' if SILK_IPV6_ENABLED is true, otherwise
using 'any-ipv4'.

=item new_ipv4addr()

Creates a bag using 'any-ipv4', regardless of SILK_IPV6_ENABLED.

=item new_integer()

Returns a bag using the 'custom' key type (integer bag).

=item copy()

Returns a copy of the bag object.

=item load($filename)

Returns a bag object loaded from the given filename.

=item save($filename)

Saves the bag object into th given filename.

=back

=head2 META METHODS

=over

=item field_types()

Return a list of valid key/counter type values.

=item get_info()

Return a hash of key type, counter type, and their respective
lengths for this bag.

=item set_info(...)

Modify the key and counter characteristics of the bag. Accepts
the following keyword arguments:

=over

  key_type
  key_len
  counter_type
  counter_len

=back

=item type_merge($type1, $type2)

Return the field type that would be given (by default) to a bag
that is a result of co-mingling two bags of the given types.
For example, 'sport' and 'dport' would merge to 'any-port'.

=item key_type_merge($other)

Given another bag, return the key merge type that results from
co-mingling with that bag.

=back

=head2 MANIPULATION METHODS

=over

=item add($item1, $item2, ...)

Add values to the bag. Items can be keys, arrays of keys, hashes,
a C<Net::Silk::IPSet>, or other bags. For items having key/value
pairs, the given value is added to the current value for that key.
For keys and lists of keys, the value is incremented by 1.

=item remove($item1, $item2, ...)

Remove values from the bag. Items can be keys, arrays of keys, hashes, a
C<Net::Silk::IPSet>, or other bags. For items having key/value pairs,
the given value is subtracted from the current value for that key. For
keys and lists of keys, the value is deccremented by 1.

=item get($key)

Return the value for the given key.

=item set($key, $val)

Set the given key to the given value.

=item del($key)

Delete the given key.

=item update($item1, $item2, ...)

Update the bag with the key/values in the given items. Items can
be other bags, hashes, arrays of keys, single keys, etc. In the
latter two cases, the value for the keys is 1.

=item constrain_keys($min, $max)

Delete all keys which do not fall into the given range. Either min
or max can be undef, but not both.

=item constrain_values($min, $max)

Delete all keys having values which do not fall into the given range.
Either min or max can be undef, but not both.

=item incr($key, $val)

Increment the number of the given key in the bag by the given value,
which defaults to 1.

=item decr($key, $val)

Decrement the number of the given key in the bag by the given value,
which defaults to 1. If the given value is greater than the current
value, the key is deleted.

=item div($item1, $item2, ...)

Divide the bag by the given items. Items can be other bags or hashes.
Returns a new bag for which values in the original bag are divided by
their corresponding values in the given bag (non-zero), rounded to the
nearest integer.

=item mul()

Multiply the bag by the given items. Items can be other bags or hashes.
Returns a new bag for which values in the original bag are multiplied by
their corresponding values in the given bag.

=item scalar_div($val)

Return a new bag where all values are divided by the given value,
rounded to the nearest integer.

=item scalar_mul()

Return a new bag where all values are multiplied by the given value.

=item clear()

Empty the bag.

=back

=head2 QUERY METHODS

=over

=item cardinality()

Return a count of how many keys are present in the bag.

=item contains($key)

Return whether or not the bag contains the given key.

=item max()

Return the maximum value contained in the bag.

=item min()

Return the minimum value contained in the bag.

=back

=head2 OPERATIONAL METHODS

=over

=item as_ipset()

Return a L<Net::Silk::IPSet> containing the keys of the bag
in cases where the keys are IP addresses.

=item inversion()

Return a new integer bag for which all values from the original bag are
inserted as keys with values representing how many times that value was
present in the bag. Hence, if two keys in the bag have a value of 5, the
newbag would have a key of 5 with a value of 2.

=item intersect($item1, $item2, ...)

Return a new bag with keys present in the given items. Items can be
other bags, hashes, arrays of keys, single keys, L<Net::Silk::IPSet>,
or L<Net::Silk::IPWildcard>.

=item complement_intersect($item1, $item2, ...)

Return a new bag with keys not present in the given items. Items can
be other bags, hashes, arrays of keys, single keys, L<Net::Silk::IPSet>,
or L<Net::Silk::IPWildcard>.

=back

=head2 ITERATION METHODS

=over

=item iter_bag($sorted)

=item iter($sorted)

Return a sub ref iterator that returns key/value pairs as an array ref.
In list context, returns all key/value pairs in a flattened list
suitable for sending to a hash. Takes an optional parameter which, if
present and true, causes results to be returned in key-sorted order. This
is the type of iterator used when the bag is placed in the IO operator.

=item iter_keys()

Return a sub ref iterator that returns all keys of the bag
that have non-zero values.

=item iter_vals()

Return a sub ref iterator that returns all non-zero values in the bag.

=item iter_group($other)

Return a sub ref iterator that returns keys and values from this bag
and the given bag. For each key which is in either bag, the iterator
returns a triple (key, value1, value2) where the first value is from
this bag and the second from the given bag. The keys are returned in
sorted order.

=back

=head1 TIED HASH

Bag objects can be treated as though they are hash references.
All corresponding hash functions work as expected.

=head1 OPERATORS

The following operators are overloaded and work with bag objects:

  -             &
  -=            &=
  +             ==
  +=            !=
  /             eq
  /=            ne
  *             ""
  *=            <>

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
