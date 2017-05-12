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

package Net::Silk::IPAddr;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );

use constant _bool => 1;

use overload (
  '""'   => \&str,
  '0+'   => \&num,
  '&'    => \&mask,
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
  '='    => \&copy,
  '-'    => \&_copy_sub,
  '+'    => \&_copy_add,
  '-='   => \&_sub,
  '+='   => \&_add,
  '>>'   => \&_copy_rshift,
  '<<'   => \&_copy_lshift,
  '>>='  => \&_rshift,
  '<<='  => \&_lshift,
  '~'    => \&_invert,
);

sub as_ipv4 {
  my $ip;
  eval { $ip = shift->_as_ipv4 };
  $@ ? () : $ip;
}

sub as_ipv6 { shift->_as_ipv6 }

sub mask { $_[0]->_xs_mask($_[1]) }

sub copy { (ref $_[0])->new($_[0]) }

sub _cmp { $_[0]->_xs_cmp($_[1]) }

sub _gt { $_[0]->_cmp($_[1]) >  0 }
sub _ge { $_[0]->_cmp($_[1]) >= 0 }
sub _lt { $_[0]->_cmp($_[1]) <  0 }
sub _le { $_[0]->_cmp($_[1]) <= 0 }

sub _eq  {    defined $_[1]  && $_[0]->_cmp($_[1]) == 0 }
sub _ne  { (! defined $_[1]) || $_[0]->_cmp($_[1]) != 0 }

sub _copy_add { (ref $_[0])->new($_[0]->num + $_[1]) }

sub _add {
  my $self = shift;
  my $new  = $self->_copy_add(@_);
  $$self = $$new;
}

sub _copy_sub {
  my($self, $other, $rev) = @_;
  $rev ? (ref $self)->new((ref $self)->new($other)->num - $self->num)
       : (ref $self)->new($self->num - $other);
}

sub _sub {
  my $self = shift;
  my $new  = $self->_copy_sub(@_);
  $$self = $$new;
}

sub _copy_rshift { (ref $_[0])->new($_[0]->num >> $_[1]) }

sub _rshift {
  my $self = shift;
  my $new  = $self->_copy_rshift(@_);
  $$self   = $$new;
}

sub _copy_lshift { (ref $_[0])->new($_[0]->num << $_[1]) }

sub _lshift {
  my $self = shift;
  my $new  = $self->_copy_lshift(@_);
  $$self   = $$new;
}

sub _copy_invert { (ref $_[0])->new(~ $_[0]->num) }

sub _invert {
  my $self = shift;
  (ref $self)->new(~($self->num) & (ref $self)->SILK_IPADDR_MAX->num);
}

sub distance {
  my($self, $other, $rev) = @_;
  $other = (ref $self)->new($other);
  $self >= $other ? $self->num - $other->num
                  : $other->num - $self->num;
}

###

package Net::Silk::IPv4Addr;

use strict;
use warnings;

use base qw( Net::Silk::IPAddr );

use Net::Silk qw( :basic );

use constant SILK_IPADDR_MAX  => SILK_IPV4ADDR_MAX;
use constant SILK_IPADDR_BITS => SILK_IPV4ADDR_BITS;

sub _cmp {
  my $self = $_[0];
  my $other = $_[1];
  my $res;
  eval { $res = $self->_xs_cmp($other) };
  if ($@) {
    # possibly a ipv6 out of ipv4 range...but don't parse numbers
    # in that case
    $res = (SILK_IPADDR_CLASS->new($other)->_cmp($self)) * -1;
  }
  $res;
}

###

package Net::Silk::IPv6Addr;

use strict;
use warnings;

use base qw( Net::Silk::IPAddr );

use Net::Silk qw( :basic );

use constant SILK_IPADDR_MAX  => SILK_IPV6ADDR_MAX;
use constant SILK_IPADDR_BITS => SILK_IPV6ADDR_BITS;

###

1;

__END__

=head1 NAME

Net::Silk::IPAddr - SiLK IP addresses

=head1 SYNOPSIS

  use Net::Silk::IPAddr;

  my $ipv4 = Net::Silk::IPAddr->new("1.2.3.4");
  my $ipv6 = Net::Silk::IPAddr->new("::ffff:1.2.3.4");

  $ipv4->is_ipv6; # false
  $ipv6->is_ipv6; # true

  $ipv4 = Net::Silk::IPv4Addr->new("::ffff:1.2.3.4");
  $ipv6 = Net::Silk::IPv6Addr->new("1.2.3.4");

  $ipv4->is_ipv6; # false
  $ipv6->is_ipv6; # true

  my $ip = $ipv4->mask('255.255.255.0');

=head1 DESCRIPTION

C<Net::Silk::IPAddr> represents an IPv4 or IPv6 address. These
manifest as the subclasses C<Net::Silk::IPv4Addr> and
C<Net::Silk::IPv6Addr>, respectively.

=head1 METHODS

=over

=item new($spec)

Returns an IP address object. The given spec can be a string
representation of the address or another IP address object.
Returns either a C<Net::Silk::IPv4Addr> or a C<Net::Silk::IPv6Addr>
if the string appears to be an IPv6 address and SILK_IPV6_ENABLED
is true.

=item str()

Returns the string representation of this IP address. This
method is tied to the C<""> operator.

=item padded()

Returns the zero-padded string representation of this IP address.

=item octets()

Returns a list of octets representing this IP address.

=item num()

Returns the integer representation of this IP address.

=item is_ipv6()

Returns true if this is a C<Net::Silk::IPv6Addr>.

=item as_ipv4()

Return a C<Net::Silk::IPv4Addr> representation of this
address if possible.

=item as_ipv6()

Return a C<Net::Silk::IPv6Addr> representation of this address.

=item mask($mask)

Return a copy of this address masked by the provided IP address mask.

=item country_code()

Return the two character country code associated with this address
if available.

=back

=head2 IPv4 METHODS

=over

=item from_int()

Return an IPv4 address from the given integer. Also accepts
hex string representations, e.g. "0xffffffff"

=item mask_prefix()

Return a copy of this address masked by the CIDR prefix bits.
All bits below the I<prefix>th bit will be set to zero. The
maximum value for prefix is 32 for IPv4.

=back

=head2 IPv6 METHODS

=over

=item from_int()

Return an IPv6 address from the given integer. Also accepts a
hex string representation, e.g. "0xffff01020304"

=item mask_prefix()

Return a copy of this address masked by the given CIDR prefix
bits. All bits below the I<prefix>th bit will be set to zero.
The maximum value for prefix is 128 for IPv6.

=back

=head1 OPERATORS

The following operators are overloaded and work with
C<Net::Silk::IPAddr> objects:

  ""              0+
  -=              -
  +=              +
  >               gt
  <               lt
  >=              ge
  <=              le
  ==              eq
  !=              ne
  <=>             cmp
  &               |
  =               bool
  <<              >>
  <<=             >>=
  ~

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
