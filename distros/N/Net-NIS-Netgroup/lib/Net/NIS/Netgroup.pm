# $Id: Netgroup.pm,v 1.4 2010/08/12 14:06:14 bastian Exp $
# Copyright (c) 2007 Collax GmbH
package Net::NIS::Netgroup;

use 5.006001;
use strict;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw ( getdomainname setdomainname innetgr listnetgr );

our $VERSION = "1.1";

=head1 NAME

Net::NIS::Netgroup - Interface to glibc "getdomainname" function and its family

=head1 VERSION

Version 1.1

=cut

bootstrap Net::NIS::Netgroup;

=head1 SYNOPSIS

 use Net::NIS::Netgroup;

 printf("Domain name is %s\n", getdomainname());
 setdomainname("newdom.com");

 printf("Is user in group? %d\n",
 	innetgr('netgroup', 'host', 'user', 'domain'));

 my @result = listnetgr("some-netgroup");
 foreach my $r (@result) {
 	printf("Found entry (%s, %s, %s)\n",
 		$r->{host}, $r->{user}, $->{domain});
 }

 #
 # Return string representations instead of hashes: 2nd arg true
 #
 my @result2 = listnetgr("some-netgroup", 1);
 foreach my $r (@result2) {
 	printf("Found entry %s\n", $r);
 }

=head1 DESCRIPTION

This module provides access methods for net groups. The following functions are offered:

=over

=item C<getdomainname()>

=item C<setdomainname($domain)>

=item C<innetgr($group, $host, $user, $domain)>

=item C<listnetgr($group [, $bool])>

=back

Detailed information about the three functions C<getgroupname>,
C<setdomainname>, and C<innetgr> can be found on the man pages of the
respective glibc functions.

C<innetgr> will happily take "undef" for one or more of its arguments,
representing the same as a NULL pointer in the C equivalent.

The function C<listnetgr($group [, $bool])> uses the functions C<setnetgrent>,
C<getnetgrent>, and C<endnetgrent> to iterate over the members of a net group,
returning a list of hash references

 {
 	host => $host,
	user => $user,
	domain => $domain
 }

for all found elements. If the (optional) second argument to C<listnetgr> is a true value,
string representations C<(host,user,domain)> of all entries are returned.

=head1 EXPORTED FUNCTIONS

All functions are exported per default. Use

 use Net::Nis::Netgroup ();

to not import the provided symbols.

=cut

1;
