#!/usr/local/bin/perl
use strict;
use lib qw(./lib ../lib);
use Test::Assertions shift();

Test::Assertions::plan tests => 1;
go();
sub go {
	to();
}
sub to {
#line 100
	ASSERT(0, 'deliberatefail');
}

