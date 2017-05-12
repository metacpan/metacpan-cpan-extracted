#  Net::Patricia - Patricia Trie perl module for fast IP address lookups
#  Copyright (C) 2000-2005  Dave Plonka
#  Copyright (C) 2009       Dave Plonka & Philip Prindeville
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA  02110-1301, USA.

# Dave Plonka <plonka@doit.wisc.edu>
# Philip Prindeville <philipp@redfish-solutions.com>
# Anton Berezin <tobez@tobez.org>

package Net::Patricia;

use strict;
use warnings;

require 5.008;

use version;
use Carp;
use vars qw($VERSION @ISA @EXPORT);
use Socket qw(AF_INET AF_INET6);

BEGIN {
  require Exporter;
  require DynaLoader;
  @ISA = qw(Exporter DynaLoader);
  @EXPORT = qw(AF_INET AF_INET6);
}

'$Revision: 1.22 $' =~ m/(\d+)\.(\d+)((_\d+)|)/ && ( $VERSION = "$1.$2$3");

bootstrap Net::Patricia $VERSION;

sub new {
  my ($class, $type) = @_;

  $type ||= AF_INET;

  if ($type == AF_INET) {
    return bless _new(32), 'Net::Patricia::AF_INET';
  }

  if ($type == AF_INET6) {
    return bless _new(128), 'Net::Patricia::AF_INET6';
  }

  croak "new: unimplemented type";
}

##
## Compat functions
##

sub _ip_bits {
  my ($self, $str) = @_;
  my $bits;

  if (ref ($self) eq 'Net::Patricia::AF_INET6') { 
	$bits = ($str =~ s|/(\d+)$||) ? $1 : 128; 
  } else { 
	$bits = ($str =~ s|/(\d+)$||) ? $1 : 32; 
  }
  ($str,$bits);
}

sub add_string {
  croak "add_string: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self,$str,$data) = @_;
  $data = $str unless @_ > 2;
  $self->add($self->_ip_bits($str),$data);
}

sub match_string {
  croak "match_string: wrong number of args" if (@_ != 2);
  my ($self,$str) = @_;
  $self->match($self->_ip_bits($str))
}

sub match_exact_string {
  croak "match_exact_string: wrong number of args" if (@_ != 2);
  my ($self,$str) = @_;
  $self->exact($self->_ip_bits($str))
}

sub match_exact_integer {
  shift->exact_integer(@_)
}

sub remove_string {
  croak "remove_string: wrong number of args" if (@_ != 2);
  my ($self,$str) = @_;
  $self->remove($self->_ip_bits($str))
}

BEGIN {
  eval {
    my $class = 'Net::CIDR::Lite';
    eval "require $class";
  };
  last if (@_);

  sub add_cidr {
    croak "add_cidr: wrong number of args" if (@_ != 3);
    my ($self, $range, $data) = @_;
    my $cidr = Net::CIDR::Lite->new();
    $cidr->add_range($range);

    my @list = ();
    for ($cidr->list()) {
      push(@list, $_) if ($self->add_string($_, $data));
    }
    @list;
  }

  sub remove_cidr {
    croak "remove_cidr: wrong number of args" if (@_ != 2);
    my ($self, $range) = @_;
    my $cidr = Net::CIDR::Lite->new();
    $cidr->add_range($range);

    my @list = ();
    for ($cidr->list()) {
      push(@list, $_) if ($self->remove_string($_));
    }
    @list;
  }
}

##
## AF_INET
##

package Net::Patricia::AF_INET;

use Carp;
use Socket qw(AF_INET inet_aton inet_ntoa);
use vars qw(@ISA @EXPORT);

BEGIN {
  require Exporter;
  require DynaLoader;
  @ISA = qw(Exporter DynaLoader Net::Patricia);
  @EXPORT = qw(AF_INET);
}

sub add {
  croak "add: wrong number of args" if (@_ < 2 || @_ > 4);
  my ($self, $ip, $bits, $data) = @_;
  $data = (defined $bits ? "$ip/$bits" : $ip) if (@_ < 4);
  my $packed = inet_aton($ip);
  croak("invalid key") unless (defined $packed);
  $bits = 32 if (@_ < 3);
  $self->SUPER::_add(AF_INET, $packed, $bits, $data);
}

sub add_integer {
  croak "add_integer: wrong number of args" if (@_ < 2 || @_ > 4);
  my ($self, $num, $bits, $data) = @_;
  my $packed = pack("N", $num);
  my $ip = inet_ntoa($packed);
  croak("invalid address") unless (defined $ip);
  $data = (defined $bits ? "$ip/$bits" : $ip) if (@_ < 4);
  $bits = 32 if (@_ < 3);
  $self->SUPER::_add(AF_INET, $packed, $bits, $data);
}

sub match_integer {
  croak "match_integer: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $num, $bits) = @_;
  $bits = 32 if (@_ < 3);
  $self->SUPER::_match(AF_INET, pack("N",$num), $bits);
}

sub exact_integer {
  croak "exact_integer: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $num, $bits) = @_;
  $bits = 32 if (@_ < 3);
  $self->SUPER::_exact(AF_INET, pack("N",$num), $bits);
}

sub match {
  croak "match: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $ip, $bits) = @_;
  my $packed = inet_aton($ip);
  croak("invalid key") unless (defined $packed);
  $bits = 32 if (@_ < 3);
  $self->SUPER::_match(AF_INET, $packed, $bits);
}

sub exact {
  croak "exact: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $ip, $bits) = @_;
  my $packed = inet_aton($ip);
  croak("invalid key") unless (defined $packed);
  $bits = 32 if (@_ < 3);
  $self->SUPER::_exact(AF_INET, $packed, $bits);
}

sub remove {
  croak "remove: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $ip, $bits) = @_;
  my $packed = inet_aton($ip);
  croak("invalid key") unless (defined $packed);
  $bits = 32 if (@_ < 3);
  $self->SUPER::_remove(AF_INET, $packed, $bits);
}

sub remove_integer {
  croak "remote_integer: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $num, $bits) = @_;
  $bits = 32 if (@_ < 3);
  $self->SUPER::_remove(AF_INET, pack("N",$num), $bits);
}

##
## AF_INET6
##

package Net::Patricia::AF_INET6;

use Carp;
use Socket qw(AF_INET6);
use Socket6 qw(inet_pton inet_ntop);
use vars qw(@ISA @EXPORT);

BEGIN {
  require Exporter;
  require DynaLoader;
  @ISA = qw(Exporter DynaLoader Net::Patricia);
  @EXPORT = qw(AF_INET6);
}

sub add {
  croak "add: wrong number of args" if (@_ < 2 || @_ > 4);
  my ($self, $ip, $bits, $data) = @_;
  $data = (defined $bits ? "$ip/$bits" : $ip) if (@_ < 3);
  my $packed = inet_pton(AF_INET6, $ip);
  croak("invalid key") unless (defined $packed);
  $bits = 128 if (@_ < 4);
  $self->SUPER::_add(AF_INET6, $packed, $bits, $data);
}

sub add_integer {
  croak "add_integer: wrong number of args" if (@_ < 2 || @_ > 4);
  my ($self, $num, $bits, $data) = @_;
  my $packed = pack("N", $num);
  my $ip = inet_ntop(AF_INET6, $packed);
  croak("invalid address") unless (defined $ip);
  $data = (defined $bits ? "$ip/$bits" : $ip) if (@_ < 3);
  $bits = 128 if (@_ < 4);
  $self->SUPER::_add(AF_INET6, $packed, $bits, $data);
}

sub match_integer {
  croak "match_integer: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $num, $bits) = @_;
  $bits = 128 if (@_ < 3);
  $self->SUPER::_match(AF_INET6, pack("N",$num), $bits);
}

sub exact_integer {
  croak "exact_integer: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $num, $bits) = @_;
  $bits = 128 if (@_ < 3);
  $self->SUPER::_exact(AF_INET6, pack("N",$num), $bits);
}

sub match {
  croak "match: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $ip, $bits) = @_;
  my $packed = inet_pton(AF_INET6, $ip);
  croak("invalid key") unless (defined $packed);
  $bits = 128 if (@_ < 3);
  $self->SUPER::_match(AF_INET6, $packed, $bits);
}

sub exact {
  croak "exact: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $ip, $bits) = @_;
  my $packed = inet_pton(AF_INET6, $ip);
  croak("invalid key") unless (defined $packed);
  $bits = 128 if (@_ < 3);
  $self->SUPER::_exact(AF_INET6, $packed, $bits);
}

sub remove {
  croak "remove: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $ip, $bits) = @_;
  my $packed = inet_pton(AF_INET6, $ip);
  croak("invalid key") unless (defined $packed);
  $bits = 128 if (@_ < 3);
  $self->SUPER::_remove(AF_INET6, $packed, $bits);
}

sub remove_integer {
  croak "remote_integer: wrong number of args" if (@_ < 2 || @_ > 3);
  my ($self, $num, $bits) = @_;
  $bits = 128 if (@_ < 3);
  $self->SUPER::_remove(AF_INET6, pack("N",$num), $bits);
}

1;
__END__

=head1 NAME

Net::Patricia - Patricia Trie perl module for fast IP address lookups

=head1 SYNOPSIS

  use Net::Patricia;

  my $pt = new Net::Patricia;

  $pt->add_string('127.0.0.0/8', \$user_data);
  $pt->match_string('127.0.0.1');
  $pt->match_exact_string('127.0.0.0');
  $pt->match_integer(2130706433); # 127.0.0.1
  $pt->match_exact_integer(2130706432, 8); # 127.0.0.0
  $pt->remove_string('127.0.0.0/8');
  $pt->climb(sub { print "climbing at node $_[0]\n" });

  undef $pt; # automatically destroys the Patricia Trie

  # IPv6 support:
  $pt = new Net::Patricia AF_INET6;
  $pt->add_string('2001:db8::/32');
  $pt->add_string('2001:db8:0:dead::/64');
  $pt->add_string('2001:db8:0:beef::/64');
  $pt->climb(sub { print "climbing at node $_[0]\n" });
  print $pt->match_string('2001:db8:0:dead::1'), "\n";

  # IPv4-mapped IPv6 addresses:
  $pt->add_string('::ffff:0:0/96');
  for my $cidr (qw( 192.0.2.0/24 192.0.2.0/25 192.0.2.128/25 )) {
    my($ip, $len) = split(m|/|, $cidr);
    $pt->add_string("::ffff:$ip/" .
	    (96+(defined($len)? $len : 32)), $cidr);
  }
  $pt->climb(sub { print "climbing at node $_[0]\n" });
  print $pt->match_string("::ffff:" . "192.0.2.129"), "\n";

=head1 DESCRIPTION

This module uses a Patricia Trie data structure to quickly
perform IP address prefix matching for applications such as IP subnet,
network or routing table lookups.  The data structure is based on a
radix tree using a radix of two, so sometimes you see patricia
implementations called "radix" as well.  The term "Trie" is derived
from the word "retrieval" but is pronounced like "try".  Patricia
stands for "Practical Algorithm to Retrieve Information Coded as
Alphanumeric", and was first suggested for routing table lookups by Van
Jacobsen.  Patricia Trie performance characteristics are well-known as
it has been employed for routing table lookups within the BSD kernel
since the 4.3 Reno release.

The BSD radix code is thoroughly described in "TCP/IP Illustrated,
Volume 2" by Wright and Stevens and in the paper ``A Tree-Based Packet
Routing Table for Berkeley Unix'' by Keith Sklower.

=head1 METHODS

=over 4

=item B<new> - create a new Net::Patricia object

   $pt = new Net::Patricia;

This is the class' constructor - it returns a C<Net::Patricia> object
upon success or undef on failure.  The constructor takes an
optional argument (of AF_INET or AF_INET6, defaulting to the former),
and creates a tree with address and mask values of that type as keys.

The C<Net::Patricia> object will be destroyed automatically when
there are no longer any references to it.

=item B<add_string>

  $pt->add_string(key_string[,user_data]);

The first argument, key_string, is a network or subnet specification in
canonical form, e.g. "10.0.0.0/8", where the number after the slash
represents the number of bits in the netmask.  If no mask width is
specified, the longest possible mask is assumed, i.e. 32 bits for
AF_INET addresses.

The second argument, user_data, is optional.  If supplied, it should be
a SCALAR value (which may be a perl reference) specifying the user data
that will be stored in the Patricia Trie node.  Subsequently, this
value will be returned by the match methods described below to indicate
a successful search.  Remember that perl references and objects are
represented as SCALAR values and therefore the user data can be
complicated data objects.

If no second argument is passed, the key_string will be stored as the
user data and therfore will likewise be returned by the match
functions.

On success, this method returns the user_data passed as the second
argument or key_string if no user data was specified.  It returns undef
on failure.

=item B<match_string>

  $pt->match_string(key_string);

This method searches the Patricia Trie to find a matching node,
according to normal subnetting rules for the address and mask
specified.

The key_string argument is a network or subnet specification in
canonical form, e.g. "10.0.0.0/8", where the number after the slash
represents the number of bits in the netmask.  If no mask width value
is specified, the longest mask is assumed, i.e. 32 bits for AF_INET
addresses.

If a matching node is found in the Patricia Trie, this method returns
the user data for the node.  This method returns undef on failure.

=item B<match_exact_string>

  $pt->match_exact_string(key_string);

This method searches the Patricia Trie to find a matching node.  Its
semantics are exactly the same as those described for C<match_string>
except that the key must match a node exactly.  I.e. it is not
sufficient that the address and mask specified merely falls within the
subnet specified by a particular node.

=item B<match_integer>

  $pt->match_integer(integer[,mask_bits]);

This method searches the Patricia Trie to find a matching node,
according to normal subnetting rules for the address and mask
specified.  Its semantics are similar to those described for
C<match_string> except that the key is specified using an integer
(i.e.  SCALAR), such as that returned by perl's C<unpack> function for
values converted using the "N" (network-ordered long).  Note that this
argument is not a packed network-ordered long.

Just to be completely clear, the integer argument should be a value of
the sort produced by this code:

   use Socket;
   $integer = unpack("N", inet_aton("10.0.0.0"));

=item B<match_exact_integer>

  $pt->match_exact_integer(integer[,mask_bits]);

This method searches the Patricia Trie to find a matching node.  Its
semantics are exactly the same as C<match_integer> except that the key
must match a node exactly.  I.e. it is not sufficient that the address
and mask specified merely falls within the subnet specified by a
particular node.

=item B<remove_string>

  $pt->remove_string(key_string);

This method removes the node which exactly matches the the address and
mask specified from the Patricia Trie.

If the matching node is found in the Patricia Trie, it is removed, and
this method returns the user data for the node.  This method returns
undef on failure.

=item B<climb>

   $pt->climb([CODEREF]);

This method climbs the Patricia Trie, visiting each node as it does
so.  It performs a non-recursive, "preorder" traversal.

The CODEREF argument is optional.  It is a perl code reference used to
specify a user-defined subroutine to be called when visiting each
node.  The node's user data will be passed as the sole argument to that
subroutine.

This method returns the number of nodes successfully visited while
climbing the Trie.  That is, without a CODEREF argument, it simply
counts the number of nodes in the Patricia Trie.

Note that currently the return value from your CODEREF subroutine is
ignored.  In the future the climb method may return the number of times
your subroutine returned non-zero, as it is called once per node.  So,
if you are currently relying on the climb return value to accurately
report a count of the number of nodes in the Patricia Trie, it would be
prudent to have your subroutine return a non-zero value.

This method is called climb() rather than walk() because climbing trees
(and therfore tries) is a more popular pass-time than walking them.

=item B<climb_inorder>

   $pt->climb_inorder([CODEREF]);

This method climbs the Patricia Trie, visiting each node in order as it
does so.  That is, it performs an "inorder" traversal.

The CODEREF argument is optional.  It is a perl code reference used to
specify a user-defined subroutine to be called when visiting each
node.  The node's user data will be passed as the sole argument to that
subroutine.

This method returns the number of nodes successfully visited while
climbing the Trie.  That is, without a CODEREF argument, it simply
counts the number of nodes in the Patricia Trie.

Note that currently the return value from your CODEREF subroutine is
ignored.  In the future the climb method may return the number of times
your subroutine returned non-zero, as it is called once per node.  So,
if you are currently relying on the climb return value to accurately
report a count of the number of nodes in the Patricia Trie, it would be
prudent to have your subroutine return a non-zero value.

This method is called climb() rather than walk() because climbing trees
(and therfore tries) is a more popular pass-time than walking them.

=back

=head2 Serialization

Net::Patricia trees, unlike many classes with XS-level data, can be
frozen and thawed using Storable.

=head1 BUGS

When passing a CODEREF argument to the climb method, the return value
from your CODEREF subroutine is currently ignored.  In the future the
climb method may return the number of times your subroutine returned
non-zero, as it is called once per node.  So, if you are currently
relying on the climb return value to accurately report a count of the
number of nodes in the Patricia Trie, it would be prudent to have your
subroutine return a non-zero value.

=head1 AUTHOR

Dave Plonka <plonka@doit.wisc.edu>
Philip Prindeville <philipp@redfish-solutions.com>
Anton Berezin <tobez@tobez.org>

Copyright (C) 2000-2005  Dave Plonka.  Copyright (C) 2009  Dave Plonka
& Philip Prindeville.  This program is free software; you
can redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This product includes software developed by the University of Michigan,
Merit Network, Inc., and their contributors.  See the copyright file in
the patricialib sub-directory of the distribution for details.

patricialib, the C library used by this perl extension, is an extracted
version of MRT's patricia code from radix.[ch], which was worked on by
Masaki Hirabaru and Craig Labovitz.  For more info on MRT see:

   http://www.mrtd.net/

The MRT patricia code owes some heritage to GateD's radix code, which
in turn owes something to the BSD kernel.

=head1 SEE ALSO

perl(1), Socket, Net::Netmask, Text::Trie, Tree::Trie.

Tree::Radix and Net::RoutingTable are modules by Daniel Hagerty
<hag@linnaean.org> written entirely in perl, unlike this module.  At
the time of this writing, they are works-in-progress but may be
available at:

   http://www.linnaean.org/~hag/

=cut
