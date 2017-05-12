#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 6;

use_ok( 'Net::Rest::Generic' ) || print "Bail out!\n";

my %arguments = (
	mode   => 'post',
	scheme => 'https',
	host   => 'perl.org',
	port   => '8080',
	base   => 'version1',
	string => 1,
);

my $api = Net::Rest::Generic->new(%arguments);
is($api->{string}, 1, 'string mode is enabled');

my @array = $api->foo->bar->baz;
is(shift(@array), 'post', 'string mode in list context returns expected result');
is(shift(@array), 'https://perl.org:8080/version1/foo/bar/baz', 'string mode in list context returns expected result');

my $scalar = $api->foo->bar->baz;
is($scalar, 'https://perl.org:8080/version1/foo/bar/baz', 'string mode in scalar context returns expected result');

$api->foo->bar->baz;
is(scalar(@{$api->{chain}}), 3, 'string mode in object context contains expected chain');

1;
