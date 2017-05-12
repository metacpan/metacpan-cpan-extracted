#!/usr/bin/perl -wT

# $Id: 02-Netmask.t,v 1.2 2003/05/28 22:19:20 unimlo Exp $

use strict;

use Test::More tests => 4;

use_ok('Net::Netmask');

my %t = (
	'any'	=> '0.0.0.0/0',
	'10.0.0.0#0.255.255.255' => '10.0.0.0/8',
	'10.0.0.0:255.0.0.0' => '10.0.0.0/8'
	);

while (my ($key,$value) = each %t)
 {
  my $x = new2 Net::Netmask($key);
  my $ok = (defined $x ? $x->desc : '') eq $value;
  ok($ok,$key);
  diag('A newer version of Net::Netmask should fix this!') unless $ok;
 };
