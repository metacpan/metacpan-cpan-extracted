#!/usr/bin/perl
# $Id: basic.t,v 1.1 2019/02/23 02:55:55 cmanley Exp $
use strict;
use warnings;
use Test::More;
use lib qw(../lib);
use MySQL::Compress;

my @methods = qw(
	mysql_compress
	mysql_uncompress
	mysql_uncompressed_length
);

plan tests => scalar(@methods);

my $class = 'MySQL::Compress';
foreach my $method (@methods) {
	can_ok($class, $method);
}
#done_testing();


unless($ENV{'HARNESS_ACTIVE'}) {
	#require Data::Dumper; Data::Dumper->import('Dumper'); local $Data::Dumper::Terse = 1;
}
