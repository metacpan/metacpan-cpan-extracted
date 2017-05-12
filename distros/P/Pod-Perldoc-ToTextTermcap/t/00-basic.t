#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 00-basic.t,v 1.11 2008/09/23 19:26:00 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

plan tests => 2;

use_ok 'Pod::Perldoc::ToTextTermcap';
use_ok 'Pod::Perldoc::ToTextOverstrike';
