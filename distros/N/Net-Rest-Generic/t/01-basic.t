#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;
plan tests => 15;

use_ok( 'Net::Rest::Generic' ) || print "Bail out!\n";

my %arguments = (
	mode   => 'post',
	scheme => 'https',
	host   => 'perl.org',
	port   => '8080',
	base   => 'version1',
	string => 1,
);

my $api = Net::Rest::Generic->new({mode => 'post'});

my $cloneapi = $api->cloneApi();
isa_ok(
	$cloneapi,
	'Net::Rest::Generic',
	'Clone succeeded'
);

my $test = 'test';
my $request = $cloneapi->setRequestContent($test)->foo;
is($request->{_request}{_content}, 'test', 'setRequestContent is adding content properly');

isa_ok(
	$api,
	'Net::Rest::Generic',
	'Create with a HASHREF succeeded'
);
$api->userAgentOptions(ssl_opts => {verify_hostname => 0});
my $opts_test = $api->foo->bar->baz;
isa_ok(
	$api->{ua},
	'LWP::UserAgent',
	'LWP::UserAgent object present in the $api',
);
is($api->{ua}{ssl_opts}{verify_hostname}, 0, 'UserAgent Options were successfully passed on');
$api = Net::Rest::Generic->new(%arguments);
isa_ok(
	$api,
	'Net::Rest::Generic',
	'Create with a HASH succeeded'
);
for my $key (keys %arguments) {
	is($arguments{$key}, $api->{$key}, "$key returned expected value");
}

my ($foo, $bar, $baz) = ('one', 'two', 'three');
$api->$foo->$bar->$baz;
is(scalar(@{$api->{chain}}), '3', 'Chain contains expected number of elements');
cmp_deeply(
	$api->{chain},
	[
		'one',
		'two',
		'three',
	],
	'Chain returns expected elements in the correct order'
);

1;
