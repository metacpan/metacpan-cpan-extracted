#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 10;

use_ok( 'Net::Rest::Generic' ) || print "Bail out!\n";
use_ok( 'Net::Rest::Generic::Error' ) || print "Bail out!\n";

my %arguments = (
	mode   => 'foo',
	scheme => 'https',
	host   => 'perl.org',
	port   => '8080',
	base   => 'version1',
	string => 1,
);

my $api = Net::Rest::Generic->new(%arguments);
isa_ok($api, 'Net::Rest::Generic::Error', 'Received expected error object when sending an invalid mode');
is($api->message, 'mode must be one of the following: delete, get, post, put, head. You supplied: foo', 'message is correct');
is($api->category, 'input', 'category is correct');
is($api->type, 'fail', 'type is correct');

$arguments{mode} = 'POST';
$api = Net::Rest::Generic->new(%arguments);
isa_ok($api, 'Net::Rest::Generic', 'Received expected object when giving capitalized mode');

$arguments{scheme} = 'http';
$api = Net::Rest::Generic->new(%arguments);
isa_ok($api, 'Net::Rest::Generic', 'Received expected object with new scheme');

$arguments{scheme} = 'HTTP';
$api = Net::Rest::Generic->new(%arguments);
isa_ok($api, 'Net::Rest::Generic', 'Received expected object with capitalized scheme');

$arguments{scheme} = 'FOO';
$api = Net::Rest::Generic->new(%arguments);
isa_ok($api, 'Net::Rest::Generic::Error', 'Received expected error object with invalid scheme');

1;
