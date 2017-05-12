# Net::IPAddress - IP Addressing stuff
# Copyright(c) 2003-2005 Scott Renner <srenner@mandtbank.com>.  All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::IPAddress;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = "1.10";
our @EXPORT = qw(ip2num num2ip mask validaddr fqdn);
our @ISA = qw(Exporter);

sub ip2num { 
  return(unpack("N",pack("C4",split(/\./,$_[0]))));
}

sub num2ip {
  return(join(".",unpack("C4",pack("N",$_[0]))));
}  

sub validaddr {
  return(0) unless ($_[0]);
  my (@ipaddr) = split(/\./,$_[0]);
  return(0) if (scalar(@ipaddr) != 4);
  my ($ip);
  foreach $ip (@ipaddr) {
    return(0) if ($ip eq "");
    return(0) if (($ip < 0) || ($ip > 255))
  }
  return(1);
}

sub mask {  
  my ($ipaddr, $mask) = @_; 
  my $format = 0;
  my ($addr);
  if (validaddr($ipaddr)) { 
    $addr = ip2num($ipaddr); 
    $format = 1;
  } else { 
    $addr = $ipaddr; 
  }
  if (validaddr($mask)) { # Mask can be sent as either "255.255.0.0" or "16"
    $mask = ip2num($mask);
  } else {
    $mask = (((1 << $mask) - 1) << (32 - $mask));
  }
  my $result = $addr & $mask;
  return($format ? num2ip($result) : $result);
}

sub fqdn {
  my ($fqdn) = @_;
  $fqdn =~ s/^\s*(.*?)\s*$/$1/; # remove leading and trailing spaces
  my ($host,@domain) = split(/\./,$fqdn); # Split the domain
  return scalar(@domain) > 0 ? ($host, join('.',@domain)) : undef
}
1;

=head1 NAME

Net::IPAddress - Functions used to manipulate IP addresses, masks and FQDN's.

=head1 SYNOPSIS
 
use Net::IPAddress;
  
@ISA = qw(Net::IPAddress);

=head1 DESCRIPTION

C<Net::IPAddr> is a collection of helpful functions used to convert IP
addresses to/from 32-bit integers, applying subnet masks to IP addresses, 
validating IP address strings, and splitting a FQDN into its host and domain 
parts. 

No rocket science here, but I have found these functions to very, very handy.
For example, have you ever tried to sort a list of IP addresses only to find
out that they don't sort the way you expected?  Here is the solution!
If you convert the IP addresses to 32-bit integer addresses, they will sort
in correct order.

=over 4

=item ip2num( STRING )

Returns the 32-bit integer of the passed IP address string.

S<C<$ipnum = ip2num("10.1.1.1");>>
$ipnum is 167837953.

=item num2ip( INTEGER )

Returns the IP address string of the passed 32-bit IP address.

S<C<$IP = num2ip(167837953);>>
$IP is "10.1.1.1".

=item validaddr( STRING )

Returns true (1) if the IP address string is a valid and properly formatted 
IP address, and false (0) otherwise.  

S<C<$valid = validaddr("10.1.2.1");>  # returns true>

S<C<$valid = validaddr("10.1.2.");>   # returns false!>

If you have your own IP address validator, try the last one.  Most will 
incorrectly compute that as a valid address.              

=item mask( IPADDRESS, MASK )

Returns the result of binary (IPADDRESS & MASK).  IPADDRESS can be either 
an IP address string or a 32-bit integer address. MASK can be either an IP 
address string, or the number of bits in the mask.  The returned value will 
be in the same format as the passed IP address.  If you pass an IP address 
string, then an IP address string is returned, if you pass a 32-bit integer 
address then a 32-bit integer address is returned.

Examples

=over 2

S<C<$subnet = mask("10.96.3.2",16);>>
S<# $subnet = "10.96.0.0">

S<C<$subnet = mask("10.21.4.22","255.240.0.0");>>
S<# $subnet = "10.16.0.0">

S<C<$subnet = mask(167837953,"255.255.255.0");>>
S<# $subnet = 167837952>>

=back

This function, when used with the others, is very useful for computing IP
addresses.  For example, you need to add another server to a subnet that an 
existing server is on.  You want the new server to be the ".17" address of a 
/24 subnet. This is done easily in the following example:

=over 2


S<C<use Net::IPAddress>>

S<C<$server = "10.8.9.12";>
C<$newserver = num2ip(ip2num(mask($server,24)) + 17);>
C<print "New server IP is $newserver\n";>>

S<C<New server IP is 10.8.9.17>>

The following code does exactly the same thing:

S<C<use Net::IPAddress;>>

S<C<$server = "10.8.9.12";>
C<$newserver = num2ip(mask(ip2num($server),24) + 17);>
C<print "New server IP is $newserver\n";>>

=back

=item fqdn( FQDN )

This function returns the host and domain of the passed FQDN (fully qualified
domain name).

S<C<($host,$domain) = fqdn("www.cpan.perl.org");>> 
S<# $host = "www", $domain = "cpan.perl.org">

=back

=head1 EXPORTS

C<Net::IPAddress> exports five functions C<ip2num>, C<num2ip>, C<validaddr>,
C<mask>, and C<fqdn>.

=head1 AUTHOR

Scott Renner <srenner@mandtbank.com>, <srenner@comcast.net>

=head1 COPYRIGHT

Copyright(c) 2003-2005 Scott Renner.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
