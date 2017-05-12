#!/usr/bin/perl
package Net::Connection::Sniffer::Util;

use strict;

use NetAddr::IP::Util qw(
	sub128
	hasbits
	ipanyto6
	ipv6_aton
);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Net::Connection::Sniffer::Util -- netaddr utilities

=head1 SYNOPSIS

  use Net::Connection::Sniffer::Util;

  my $ip = newcidr24 Net::Connection::Sniffer::Util($netaddr);

  my $ipcopy = $ip->copy;

  if ($someip->within($ip)) {
	do something...

  if ($ip->contains($someip)) {
	do something...

  if ($ip1->equal($ip2)) {
	do something

=head1 DESCRIPTION

B<Net::Connection::Sniffer::Util> is a lite weight perl module to do NetAddr::IP like 
operations on ip addresses in either 32 or 128 bit formats.

=over 4

=item * my $ip = newcidr24;

Create a blessed address object with cidr/24 network/broadcast bounds (assumes 32
bit addressing), for ipv6, this will be cidr/120

=cut

my $oxFF	= ipv6_aton('::FF');
my $oxFF00	= ~ $oxFF;

sub newcidr24 {
  my($proto,$naddr) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{IP} = $naddr = ipanyto6($naddr);
  $self->{BC} = $naddr | $oxFF;
  $self->{NT} = $naddr & $oxFF00;
  bless ($self, $class);
  return $self;
}

=item * my $ipcopy = $ip->copy;

Copy a blessed network address object to a new blessed object;

Returns 'undef' if $ip is not a Net::Connection::Sniffer::Util object.

=cut

sub copy {
  my $proto = shift;
  return undef unless (my $class = ref($proto)) eq __PACKAGE__;
  my $self = {};
  @{$self}{qw(IP BC NT)} = @{$proto}{qw(IP BC NT)};
  bless ($self,$class);
  return $self;
}

=item * $rv = $someip->within($ip);

Check to see if $someip is within the cidr of $ip. i.e. 

  network address <= $someip <= broadcast address

  input:	ip object for range check
  returns:	true if within, else false

Returns 'undef' if $someip and $ip are not Net::Connection::Sniffer::Util objects.

=cut

sub within {
  my($sref,$ip) = @_;
  return undef unless 	ref($sref) eq __PACKAGE__ &&
			ref($ip) eq __PACKAGE__;
  return (sub128($sref->{IP},$ip->{NT}) && sub128($ip->{BC},$sref->{IP}))
	? 1 : 0;
}

=item * $rv = $ip->contains($someip);

Check to see if $ip is within the cidr range of $someip. i.e.

This is the logical compliment of the B<within> method.

=cut

sub contains {
  my($sref,$ip) = @_;
  return within($ip,$sref);
}

=item * $rv = $ip1->equal($ip2);

Check if IP1 equal IP2

  input:	ip2 object
  returns:	true/false

=cut

sub equal {
  my($ip1,$ip2) = @_;
  return 0 unless $ip1 && $ip2 && ref $ip1 && ref $ip2;
  return hasbits((sub128($ip1->{IP},$ip2->{IP}))[1])
	? 0 : 1;
}

=pod

=back

=head1 COPYRIGHT

Copyright 2006, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License (except as noted
otherwise in individuals sub modules)  published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

	man (3) NetAddr::IP::Util

=cut

1;
