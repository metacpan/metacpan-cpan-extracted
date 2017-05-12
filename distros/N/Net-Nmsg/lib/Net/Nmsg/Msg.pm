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

package Net::Nmsg::Msg;

use strict;
use warnings;
use Carp;

###

use Net::Nmsg::Util qw( :field :alias );
use Net::Nmsg::Typemap;

use constant MSG   => 0;
use constant STAGE => 1;
use constant DIRTY => 2;
use constant SEC   => 3;
use constant NSEC  => 4;
use constant SRC   => 5;
use constant OPR   => 6;
use constant GRP   => 7;

my $Input_Typemap_Class  = 'Net::Nmsg::Typemap::Input';
my $Output_Typemap_Class = 'Net::Nmsg::Typemap::Output';
my $XS_Msg_Class         = 'Net::Nmsg::XS::msg';

my @Modules;

sub modules { @Modules }

{
  # build sub classes based on modules present
  no strict 'refs';
  my $pkg = __PACKAGE__;
  for my $m (Net::Nmsg::Util::_dump_msgtypes()) {
    my($vid, $mid, $vname, $mname) = @$m;
    my $class = join('::', $pkg, $vname, $mname);
    push(@Modules, $class);
    my @classes = $class;
    if ($vname eq 'base') {
      # backwards compat for vendor string 'ISC'
      # don't put these in @Modules
      push(@classes, join('::', $pkg, 'ISC', $mname));
    }
    elsif ($vname eq 'ISC') {
      # forwards compat so new examples will work with
      # older libnmsg installs
      push(@classes, join('::', $pkg, 'base', $mname));
    }
    for $class (@classes) {
      eval <<__CLASS;
package $class;

use base qw( $pkg );

use Net::Nmsg::Util;

use constant VID    => $vid;
use constant MID    => $mid;
use constant type   => qw( $mname );
use constant vendor => qw( $vname );

my \$Mod = Net::Nmsg::Util::_msgmod_lookup($vid, $mid);
die \$@ if \$@;

sub _new_msg { $XS_Msg_Class->init(\$Mod) }

my \$Class_Msg;

sub _class_msg { \$Class_Msg ||= _new_msg() }

__CLASS
    die "class construction failed : $@" if $@;
    $class->_load_methods;
    }
  }
}

sub new {
  my $self = bless [], shift;
  if (@_) {
    $self->[MSG] = $_[0];
    $self->_unpack;
  }
  $self;
}

sub msg {
  my $self = shift;
  if ($self->[DIRTY]) {
    $self->[MSG] = $self->_new_msg;
    $self->_pack;
  }
  $self->[MSG];
}

sub _msg {
  my $self = shift;
  $self->[MSG] ||= $self->_new_msg;
}

sub source {
  my $self = shift;
  if (@_) {
    $self->[DIRTY] ||= $self->_unpack;
    $self->[SRC] = shift;
  }
  else {
    $self->_unpack;
  }
  $self->[SRC];
}

sub operator {
  my $self = shift;
  if (@_) {
    $self->[DIRTY] ||= $self->_unpack;
    my($k, $v) = operator_lookup(shift);
    $self->[OPR] = $k;
  }
  else {
    $self->_unpack;
  }
  my($k, $v) = operator_lookup($self->[OPR]);
  $v;
}

sub group {
  my $self = shift;
  if (@_) {
    $self->[DIRTY] ||= $self->_unpack;
    my($k, $v) = group_lookup(shift);
    $self->[GRP] = $k;
  }
  else {
    $self->_unpack;
  }
  my($k, $v) = group_lookup($self->[GRP]);
  $v;
}

sub time {
  my $self = shift;
  if (@_) {
    $self->[DIRTY] ||= $self->_unpack;
    $self->[SEC]  = shift || 0;
    $self->[NSEC] = shift || 0;
  }
  else {
    $self->_unpack;
  }
  return($self->[SEC], $self->[NSEC]);
}

sub fields_present {
  my $self   = shift;
  my $fields = $self->_fields;
  my $flags  = $self->_flags;
  my @fp;
  for my $i (0 .. $#$fields) {
    next if $flags->[$i] & NMSG_FF_HIDDEN;
    my $f = $fields->[$i];
    my $method = 'get_' . $f;
    push(@fp, $f) if UNIVERSAL::can($self, $method);
  }
  @fp;
}

###

sub headers_as_str {
  my $self = shift;
  my $msg  = $self->_msg || return '';
  my($ts, $nsec) = $msg->get_time;
  my($s, $min, $h, $d, $m, $y) = (gmtime($ts))[0..5];
  $y += 1900; ++$m;
  my @str = sprintf("[%04d-%02d-%02d %02d:%02d:%02d.%09d]",
                    $y, $m, $d, $h, $min, $s, $nsec);
  push(@str, sprintf("[%d:%d %s %s]",
             $self->VID, $self->MID, $self->vendor, $self->type));
  my $src = $msg->get_source;
  push(@str, $src ? sprintf("[%08x]", $src) : '[]');
  join(' ',
    @str,
    map { $_ ? "[$_]" : '[]' } (
      $msg->get_operator || "<UNKNOWN>",
      $msg->get_group    || "<UNKNOWN>"
    )
  );
}

sub as_str {
  my $self = shift;
  my $eol  = shift || "\n";
  join($eol, $self->headers_as_str, $self->_msg->message_to_pres($eol));
}

sub _debug_as_str {
  my $self   = shift;
  my $eol    = shift || "\n";
  my @str    = $self->headers_as_str;
  my $fields = $self->_fields;
  my $flags  = $self->_flags;
  for my $i (0 .. $#$fields) {
    next if $flags->[$i] & (NMSG_FF_HIDDEN | NMSG_FF_NOPRINT);
    my $f = $fields->[$i];
    my $m = 'get_' . $f;
    my @v = $self->$m;
    @v && push(@str, sprintf("%s: %s", $f, join(', ', @v)));
  }
  join($eol, @str, '');
}


###

sub _flush { $_[0]->[MSG] = undef }

sub _unpack {
  return $_[0]->[STAGE] if $_[0]->[STAGE];
  my $self = $_[0];
  my @unpacked;
  $#unpacked = $self->count - 1;
  if (my $msg = $self->[MSG]) {
    @{$self}[SEC,NSEC] = $msg->get_time();
    $self->[SRC] = $msg->get_source();
    $self->[OPR] = $msg->get_operator();
    $self->[GRP] = $msg->get_group();
    for my $i (0 .. $#unpacked) {
      my @v = $msg->get_field_vals_by_idx($i);
      $unpacked[$i] = @v ? \@v : undef;
    }
  }
  $self->[STAGE] = \@unpacked;
}

sub _pack {
  my $unp = $_[0]->[DIRTY];
  my $msg = $_[0]->[MSG];
  return if $msg && !$unp;
  my $self = $_[0];
  $unp ||= $self->[STAGE];
  $msg = $_[0]->[MSG] = $self->_new_msg;
  $msg->set_time(@{$self}[SEC, NSEC])
    if defined $self->[SEC];
  $msg->set_source($self->[SRC])
    if defined $self->[SRC];
  $msg->set_operator($self->[OPR])
    if defined $self->[OPR];
  $msg->set_group($self->[GRP])
    if defined $self->[GRP];
  my $flags = $self->_flags;
  for my $i (0 .. $#$unp) {
    my $val = $unp->[$i];
    if (defined $val) {
      for my $f (0 .. $#$val) {
        $msg->set_field_by_idx($i, $f, $val->[$f]);
      }
    }
  }
  $self->[DIRTY] = undef;
}

###

sub _getter {
  my($class, $idx, $flags, $mapper) = @_;
  my $repeated = $flags & NMSG_FF_REPEATED;
  if ($repeated) {
    return sub {
      my @val;
      my $unp = $_[0]->[STAGE] ||= $_[0]->_unpack;
      my $fval = $unp->[$idx];
      if (!$fval || !@$fval) {
        $fval = [];
        @$fval = $class->_class_msg->get_field_vals_by_idx($idx);
      }
      if ($mapper) {
        @val = map { $mapper->($_, $class) } @$fval;
      }
      else {
        @val = @$fval;
      }
      wantarray ? @val : \@val;
    };
  }
  else {
    return sub {
      my $unp = $_[0]->[STAGE] ||= $_[0]->_unpack;
      my $val = $unp->[$idx];
      if (!$val || !@$val) {
        $val = [];
        @$val = $class->_class_msg->get_field_by_idx($idx);
      }
      return unless defined($val = $val->[0]);
      $mapper ? $mapper->($val, $class) : $val;
    };
  }
}

sub _setter {
  my($class, $idx, $flags, $mapper) = @_;
  my $repeated = $flags & NMSG_FF_REPEATED;
  if ($repeated) {
    return sub {
      my $self = shift;
      my $unp = $self->[DIRTY] ||= $self->_unpack;
      my $val = $unp->[$idx]   ||= [];
      @$val = ();
      return if @_ == 1 && ! defined $_[0];
      if ($mapper) {
        @$val = map { defined $_ ? $mapper->($_, $class)
                                 : croak("undefined value is assignment\n")
                    }
                @_;
      }
      else {
        @$val = @_;
      }
    };
  }
  else {
    return sub {
      my $self = shift;
      my $unp = $self->[DIRTY] ||= $self->_unpack;
      my $val = $unp->[$idx]   ||= [];
      @_ = pop if @_ > 1 && !$repeated;
      if (defined $_[0]) {
        if ($mapper) {
          $val->[0] = $mapper->($_[0], $class);
        }
        else {
          $val->[0] = $_[0];
        }
      }
    };
  }
}
              
sub _pusher {
  my($class, $idx, $flags, $mapper) = @_;
  croak "not a repeated field ($idx)" unless $flags & NMSG_FF_REPEATED;
  return sub {
    my $self = shift;
    @_ || return;
    my $unp = $self->[DIRTY] ||= $self->_unpack;
    my $val = $unp->[$idx]   ||= [];
    $self->[MSG] = undef;
    if ($mapper) {
      push(@$val,
           map { defined $_ ? $mapper->($_, $class)
                            : croak("undefined value in assignment\n")
               }
           @_
      );
    }
    else {
      push(@$val, @_);
    }
  };
}

###

sub _msg_descr {
  my($class, $msg) = @_;
  my(@fields, @types, @flags);
  my $i = 0;
  while (defined(my $val = $msg->get_field_name($i))) {
    $fields [$i] = $val;
    $types  [$i] = $msg->get_field_type_by_idx ($i);
    $flags  [$i] = $msg->get_field_flags_by_idx($i);
    ++$i;
  }
  return(\@fields, \@types, \@flags);
}

sub _load_methods {
  my $class = shift;
  $class = ref $class || $class;

  my $types_by_val = field_types_by_val();
  my $flags_by_val = field_flags_by_val();

  my $msg = $class->_new_msg;
  my($fields, $types, $flags) = $class->_msg_descr($msg);

  my(@tlabels, @flabels);

  no strict "refs";
  *{ "$class\::_fields" } = sub { $fields };
  *{ "$class\::_types"  } = sub { $types  };
  *{ "$class\::_flags"  } = sub { $flags  };
  *{ "$class\::fields"  } = sub { wantarray ? @$fields : [@$fields] };
  *{ "$class\::types"   } = sub { wantarray ? @tlabels : [@tlabels] };
  *{ "$class\::count"   } = sub { scalar @$fields };
  *{ "$class\::flags"   } = sub {
    my @flags;
    for my $f (@flabels) {
      push(@flags, {%$f});
    }
    wantarray ? @flags : \@flags;
  };
  for my $i (0 .. $#$fields) {
    my $key = $fields->[$i];
    my $ft  = $types ->[$i];
    my $ff  = $flags ->[$i];
    $tlabels[$i] = $types_by_val->{$ft};
    my %labels;
    if ($ff) {
      my $c = 0;
      my $fff = $ff;
      while ($fff) {
        if ($fff & 0x01) {
          my $v = 2 ** $c;
          $labels{$flags_by_val->{$v} || 'UNKNOWN'} = $v;
        }
        ++$c;
        $fff >>= 1;
      }
    }
    $flabels[$i] = \%labels;
    my $repeated = $ff & NMSG_FF_REPEATED;
    my $in_map   = $Input_Typemap_Class ->make_mapper($ft, $i);
    my $out_map  = $Output_Typemap_Class->make_mapper($ft, $i);
    *{ "$class\::get_$key" } = $class->_getter($i, $ff, $out_map);
    *{ "$class\::set_$key" } = $class->_setter($i, $ff, $in_map);
    *{ "$class\::add_$key" } = $class->_pusher($i, $ff, $in_map)
      if $repeated;
    *{ "$class\::get_raw_$key" } = $class->_getter($i, $ff);
    *{ "$class\::set_raw_$key" } = $class->_setter($i, $ff);
    *{ "$class\::add_raw_$key" } = $class->_pusher($i, $ff)
      if $repeated;
  }
}

###

1;

__END__

=pod

=head1 NAME

Net::Nmsg::Msg - Perl interface for messages from the NMSG library

=head1 SYNOPSIS

  use Net::Nmsg::Output;
  use Net::Nmsg::Input;
  use Net::Nmsg::Msg;

  # Each message type (vendor/msgtype) gets its own subclass with
  # methods specific to the fields for that type. For example:

  my $o = Net::Nmsg::Output->open('127.0.0.1/9430');
  my $m = Net::Nmsg::Msg::base::ipconn->new();
  for my $i (0 .. 99) {
    $m->set_srcip("127.0.0.$i");
    $m->set_dstip("127.1.0.$i");
    $m->set_srcport($i);
    $m->set_dstport(65535 - $i);
    $o->write($m);
  }

  my $c = 0;
  my $i = Net::Nmsg::Input->open('input.nmsg');
  while (my $m = $i->read) {
    print "message $c vendor ", $m->vendor, " type ", $m->type, "\n"
    print $m->as_str, "\n";
    ++$c;
  }

=head1 DESCRIPTION

Net::Nmsg::Msg is the base class for NMSG messages. Each vendor/msgtype
has a tailored subclass for handling fields particular to that type.

=head1 METHODS

=over

=item modules()

Returns a list of all message module classes installed on the system.

=item vendor()

The name of the vendor of this message module.

=item type()

The message type of this message module.

=item source([source])

Return or set the source ID of this nmsg message.

=item operator([operator])

Return or set the operator ID of this nmsg message.

=item group([group])

Return or set the group of this nmsg message.

=item time([time_sec, time_nsec])

Return or set the timestamp of this nmsg message. Accepts and returns
two integer values representing seconds and nanoseconds.

=item fields()

A list of possible fields defined for this message module.

=item fields_present()

A list of fields actually defined for a message module.

=item headers_as_str()

Renders the headers of a message (vendor, type, source, operator, group)
as a string.

=item as_str()

Renders the entire message, headers plus fields and their values
as a string.

=back

=head1 ACCESSORS

Each field of a message has several methods associated with it. Replace
'fieldname' with the actual name of the field:

  get_fieldname()
  get_raw_fieldname()

  set_fieldname($val)
  set_raw_fieldname($packed_val)

Fields that are 'repeated' accept multiple values in the setters and
return (possibly) multiple values from the getters. Repeated fields have
these additional methods associated with them which push values onto the
list of existing values:

  add_fieldname(@vals)
  add_raw_fieldname(@packed_vals)

There is no difference between the plain and raw versions of these
methods if the field is one of the following data types:

  NMSG_FT_BYTES
  NMSG_FT_STRING
  NMSG_FT_MLSTRING
  NMSG_FT_UINT16
  NMSG_FT_UINT32
  NMSG_FT_INT16
  NMSG_FT_INT32
  NMSG_FT_DOUBLE
  NMSG_FT_BOOL

The following field types behave differently since there are no native
perl types for them:

  field           mode  type   returns/accepts
  -------------------------------------------------------------
  NMSG_FT_IP      get          IPv4/IPv6 strings
  NMSG_FT_IP      set          IPv4/IPv6 strings
  NMSG_FT_IP      get   raw    IPv4/IPv6 packed network order
  NMSG_FT_IP      set   raw    IPv4/IPv6 packed network order

  NMSG_FT_INT64   get          Math::Int64
  NMSG_FT_INT64   set          Math::Int64 or string
  NMSG_FT_INT64   get   raw    64-bit integer packed native
  NMSG_FT_INT64   set   raw    64-bit integer packed native

  NMSG_FT_UINT64  *     *      same as above but unsigned

  NMSG_FT_ENUM    get          string
  NMSG_FT_ENUM    set          string
  NMSG_FT_ENUM    get   raw    int
  NMSG_FT_ENUM    set   raw    int

=head1 SEE ALSO

L<Net::Nmsg>, L<Net::Nmsg::IO>, L<Net::Nmsg::Input>, L<Net::Nmsg::Output>, L<Net::WDNS>, L<nmsgtool(1)>

=head1 AUTHOR

Matthew Sisk, E<lt>sisk@cert.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010-2015 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
