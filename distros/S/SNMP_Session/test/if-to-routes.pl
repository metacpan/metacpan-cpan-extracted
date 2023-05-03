#!/usr/local/bin/perl -w
######################################################################
### Name:	  if-to-routes.pl
### Date Created: Wed May  6 22:21:55 1998
### Author:	  Simon Leinen  <simon@switch.ch>
### RCS $Id: if-to-routes.pl,v 1.1 1998-05-06 20:31:01 simon Exp $
######################################################################
### Given an SNMP interface index, list the destination networks and
### netmasks for all routes which point to that interface.
######################################################################

use strict;
use BER;
use SNMP_Session "0.57";

sub usage();

my $if_index = shift @ARGV || usage ();
my $target = shift @ARGV || usage ();
my $community = shift @ARGV || 'public';

my $ipRouteIfIndex = [1,3,6,1,2,1,4,21,1,2];
my $ipRouteMask = [1,3,6,1,2,1,4,21,1,11];

my $session = SNMP_Session->open ($target, $community, 161)
  || die "Opening SNMP_Session";
$session->map_table ([$ipRouteIfIndex,$ipRouteMask],
		     sub { my ($dest, $index, $mask) = @_;
			   grep (defined $_ && ($_=pretty_print $_),
				 ($index, $mask));
			   if ($index == $if_index) {
			       print "$dest $mask\n";
			   }
		       });
1;

sub usage () {
    die "usage: $0 if_index target [community]";
}
