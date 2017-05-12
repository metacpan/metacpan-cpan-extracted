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

package Net::Silk::IPWildcard;

use strict;
use warnings;

use Net::Silk qw( :basic );
use Net::Silk::IPAddr;

use Math::BigInt;
use Scalar::Util qw( refaddr );

use overload (
  '<>' => \&_fh_iter,
  '""' => sub { refaddr shift },
);

my %Attr;

sub cardinality {
  my $self = shift;
  my $card;
  eval { $card = $self->_cardinality };
  if ($@) {
    if ($@ =~ /overflow/) {
      $card = Math::BigInt->new("0x100000000000000000000000000000000");
    }
    else {
      croak $@;
    }
  }
  $card;
}

sub iter {
  my $self = shift;
  my $iter = Net::Silk::IPWildcard::iter_xs->bind($self);
  my($sub, @items);
  sub {
    if (wantarray) {
      @items = ();
      while (my $item = Net::Silk::IPWildcard::iter_xs::next($iter)) {
        push(@items, $item);
      }
      return @items;
    }
    Net::Silk::IPWildcard::iter_xs::next($iter);
  };
}

sub iter_cidr {
  my $self = shift;
  my $iter = Net::Silk::IPWildcard::iter_xs->bind($self);
  sub {
    if (wantarray) {
      my @items;
      while (my @cidr = Net::Silk::IPWildcard::iter_xs::next_cidr($iter)) {
        push(@items, SILK_CIDR_CLASS->new(@cidr));
      }
      return @items;
    }
    my @res = Net::Silk::IPWildcard::iter_xs::next_cidr($iter);
    @res ? SILK_CIDR_CLASS->new(@res) : ();
  };
}

sub iter_ranges {
  my $self = shift;
  SILK_CIDR_CLASS->_iter_ranges($self->iter_cidr);
}

sub iter_bag {
  my $self = shift;
  my $iter = Net::Silk::IPWildcard::iter_xs->bind($self);
  sub {
    my $item = Net::Silk::IPWildcard::iter_xs::next($iter) || return;
    [$item, 1];
  };
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

sub _set_repr {
  my $self = shift;
  $Attr{$self}{set} ||= SILK_IPSET_CLASS->new($self);
}

sub DESTROY {
  my $self = shift;
  delete $Attr{$self};
}

###

1;

__END__

=head1 NAME

Net::Silk::IPWildcard - SiLK IP wildcard class

=head1 SYNOPSIS

  use Net::Silk::IPWildcard;

  my $w = Net::Silk::IPWildcard->new('1.2.3.0/24');
  $w->contains('1.2.3.4'); # true
  
  while (my $ip = <$w>) {
    ...
  }

  my $iter = $w->iter_cidr;
  while (my $cidr = $iter->()) {
    my($ip, $prefix) = @$cidr;
    ...
  }

=head1 DESCRIPTION

C<Net::Silk::IPWildcard> objects represent a range or block of IP
addresses.

=head1 METHODS

=over

=item new($spec)

Returns a new C<Net::Silk::IPWildcard> object. The provide spec can be
a L<Net::Silk::IPAddr> object, another wildcard object, a IP CIDR
string, an integer, an integer with a CIDR designation, or an entry in
SiLK wildcard notation. In SiLK wildcard notation, a wildcard is
represented as an IP address in canonical form with each octet (IPv4) or
hexadectet (IPv6) represented by one of following: a value, a range of
values, a comma separated list of values and ranges, or the character
'x' used to represent the entire octet or hexadectet.

Some examples of valid strings:

  '1.2.3.0/24'
  'ff80::/16'
  '1.2.3.4'
  '::ffff:0102:0304'
  '16909056'
  '16909056/24'
  '1.2.3.x'
  '1:2:3:4:5:6:7:x'
  '1.2,3.4,5.6,7'
  '1.2.3.0-255'
  '::2-4'
  '1-2:3-4:5-6:7-8:9-a:b-c:d-e:0-ffff'

=item cardinality()

Return the number of addresses represented by this IPWildcard.

=item contains($ip)

Returns true if the given IP address is contained within this Wildcard.
The given IP address can be a string or L<Net::Silk::IPAddr>.

=item is_ipv6()

Returns true if this wildcard is IPv6 enabled.

=item iter()

Return a sub ref iterator that returns each L<Net::Silk::IPAddr> represented
by this wildcard. In list context this will slurp all addresses.

=item iter_cidr()

Return a sub ref iterator that returns a L<Net::Silk::CIDR> object for
each CIDR block contained in this wildcard.

=item iter_ranges()

Return a sub ref iterator that returns a L<Net::Silk::Range> object for
each IP range contained in this wildcard.

=back

=head1 OPERATORS

The IO operator C<E<lt>E<gt>> works with C<Net::Silk::IPWildcard>
objects, returning each address in the wildcard space.

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
