#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 9;

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

#void context
my @voidchain = ('foo', 'bar', 'baz');
$api->foo->bar->baz;
my $count;
for (@{$api->{chain}}) {
	if (is($_, shift(@voidchain), "found $_ in void context")) {
		$count++;
	}
}
is($count, 3, 'found expected chain in void context');

#scalar & list context
my $scalar = $api->foo->bar->baz;
is(scalar(@{$api->{chain}}), 0, 'found empty chain after scalar context');

my @array = $api->foo->bar->baz;
is(scalar(@{$api->{chain}}), 0, 'found empty chain after list context');

#object context
$api->foo;
is(shift(@{$api->{chain}}), 'foo', "found expected chain in object context");
is(scalar(@{$api->{chain}}), 0, 'found expected chain in object context');

1;
