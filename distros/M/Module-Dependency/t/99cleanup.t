#!/usr/bin/perl
# $Id: 99cleanup.t,v 1.1 2002/01/21 15:40:39 piers Exp $
use strict;
use Test;
BEGIN { plan tests => 4; }
if (-d 't') {
	chdir( 't' );
}

my @files = qw/dbdump.dat dbindex2.dat dbindext.dat temp.tmp/;

foreach (@files) {
	unlink( $_ );
	ok( ! -e $_ );
}

# cleanup done
