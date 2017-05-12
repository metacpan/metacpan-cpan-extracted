#!/usr/bin/perl -w
use strict;
use lib qw(./lib ../lib t/lib);
use Test::Simple tests => 3;

my @files = qw/xtest-a.ps xtest-b.ps xtest-c.ps/;

foreach (@files) {
	unlink $_;
	ok( ! -e $_ );
}
