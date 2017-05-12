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

package Net::Silk::ProtoPort;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );

use constant _bool => 1;

use overload (
  '""'   => \&str,
  '+='   => \&_add,
  '+'    => \&_copy_add,
  '-='   => \&_sub,
  '-'    => \&_copy_sub,
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
  'bool' => \&_bool,
  '='    => \&_clone,
  '@{}'  => \&_me_array,
);

my %Tied;

sub new {
  my $class = shift;
  $class = ref $class || $class;
  my($proto, $port);
  if (@_ == 1) {
    if (ref $_[0]) {
      $proto = $_[0][0];
      $port  = $_[0][1];
    }
    elsif ($_[0] =~ /^(\d+)\D(\d+)$/) {
      ($proto, $port) = ($1, $2);
    }
    elsif ($_[0] =~ /^\d+$/) {
      $proto = ($_[0] & 0xf0000) >> 16;
      $port  = $_[0] & 0x0ffff;
    }
    else {
      croak "invalid proto/port: $_[0]";
    }
  }
  elsif (@_) {
    $proto = shift;
    $port  = shift;
  }
  defined $proto && defined $port
    || croak("invalid proto/port: array ref, int pair," .
             " int, or colon-separated str required");
  $class->init($proto, $port);
}

sub proto {
  my $self = shift;
  $self->_set_proto(shift) if @_;
  $self->_get_proto;
}

sub port {
  my $self = shift;
  $self->_set_port(shift) if @_;
  $self->_get_port;
}

sub copy {
  my $self = shift;
  (ref $self)->new($self->proto, $self->port);
}

sub str {
  my $self = shift;
  join(':', $self->proto, $self->port);
}

sub _cmp {
  my($self, $other, $rev) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, __PACKAGE__);
  ($self, $other) = ($other, $self) if $rev;
  $self->[0] <=> $other->[0] || $self->[1] <=> $other->[1];
}

sub _gt  { shift->_cmp(@_) >  0 }
sub _ge  { shift->_cmp(@_) >= 0 }
sub _lt  { shift->_cmp(@_) <  0 }
sub _le  { shift->_cmp(@_) <= 0 }

sub _eq  {    defined $_[1]  && shift->_cmp(@_) == 0 }
sub _ne  { (! defined $_[1]) || shift->_cmp(@_) != 0 }

sub _add {
  my($self, $num, $rev) = @_;
  my $new = $self->_xs_add($num);
  $$self = $$new;
}

sub _copy_add {
  my $self = shift;
  $self->_xs_add(shift);
}

sub _sub {
  my($self, $num, $rev) = @_;
  my $new = $self->_xs_sub($num);
  $$self = $$new;
}

sub _copy_sub {
  my $self = shift;
  $self->xs_sub(shift);
}

sub distance {
  my($self, $other, $rev) = @_;
  $other = (ref $self)->new($other);
  $self >= $other ? $self->num - $other->num
                  : $other->num - $self->num;
}

###

sub DESTROY { delete $Tied{shift()} }

sub _me_array {
  my $self = shift;
  my $aref = $Tied{$self};
  if (!$aref) {
    $aref = $Tied{$self} = [];
    tie(@$aref, $self);
  }
  $aref;
}

### tied array

use constant FETCHSIZE => 2;

sub TIEARRAY {
  my $class = shift;
  my $self;
  if (ref $class) {
    $self  = $class;
    $class = ref $self;
  }
  else {
    croak("can only tie to an instance");
  }
  $self;
}

sub FETCH {
  my $self = shift;
  my $idx  = shift;
  if ($idx == 0) {
    return $self->proto;
  }
  elsif ($idx == 1) {
    return $self->port;
  }
  else {
    croak "index not 0 or 1";
  }
}

sub EXISTS {
  my $self = shift;
  my $v;
  eval { $v = $self->FETCH(@_) };
  $@ ? 0 : 1;
}

###

1;

__END__

=head1 NAME

Net::Silk::ProtoPort - SiLK protocol/port pair

=head1 SYNOPSIS

  use Net::Silk::ProtoPort;

  my $pp1 = Net::Silk::ProtoPort(6, 22);
  my $pp2 = Net::Silk::ProtoPort("6:443");

  $pp1 < $pp2; # true

  print "proto: ", $pp1->proto, "\n";
  print " port: ", $pp1->port, "\n";

=head1 DESCRIPTION

C<Net::Silk::ProtoPort> objects represent a protocol/port pair
which can be used as a key (as opposed to an IP address) in
L<Net::Silk::Pmap> files.

=head1 METHODS

=over

=item new($spec)

=item new($proto, $port)

Returns a new C<Net::Silk::ProtoPort> object. The protocol and port can
be provided directly as two arguments, or as an array reference
containing the pair, or as a string with a non-digit separator such as
"proto:port".

=item proto()

Return or set the protocol number.

=item port()

Return or set the port number.

=item copy()

Return a copy of this object. This method is tied to the C<=> operator.

=item str()

Return a string representation "port:proto". This method is tied to the
C<""> operator.

=item num()
Return an integer representation of this proto/port pair.

=item distance($other)

Return an integer representing the absolute value of the distance
between this protoport and another.

=back

=head1 TIED ARRAY

The C<Net::Silk::ProtoPort> object can be treated as an array, such that
C<$pp-E<gt>[0]>, C<$pp-E<gt>[1]>, and C<@$pp> work as expected.

=head1 OPERATORS

The following operators are overloaded and work with
C<Net::Silk::ProtoPort> objects:

  ""            bool
  +=            =
  +             @{}
  -=
  -
  <=>           cmp
  >             gt
  <             lt
  >=            ge
  <=            le
  ==            eq
  !=            ne

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
