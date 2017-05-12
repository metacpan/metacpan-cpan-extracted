#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 6;

use_ok( 'Net::Rest::Generic' ) || print "Bail out!\n";
use_ok( 'Net::Rest::Generic::Utility' ) || print "Bail out!\n";

my %arguments = (
	mode   => 'post',
	scheme => 'https',
	host   => 'perl.org',
	port   => '8080',
	base   => 'version1',
	string => 1,
);

my $api = Net::Rest::Generic->new(%arguments);
isa_ok($api, 'Net::Rest::Generic', 'Received expected error object when sending an invalid mode');

my $mode = $api->{mode};
my $url  = $api->{uri}->as_string;
my $args = $api->{_params};
$mode = uc($mode);
$args ||= {};
$api->{ua} ||= LWP::UserAgent->new;
my ($request, @params) = Net::Rest::Generic::Utility::_generateRequest($api, $mode, $url, $args);

isa_ok($request, 'HTTP::Request', 'Received an HTTP::Request object');
is($request->{_method}, 'POST', 'Mode is correct');
is($request->{_uri}->as_string, 'https://perl.org:8080', 'url returned the expected string');

1;
