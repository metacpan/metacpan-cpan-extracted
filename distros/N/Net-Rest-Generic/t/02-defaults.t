#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 5;

use_ok( 'Net::Rest::Generic' ) || print "Bail out!\n";

my $api = Net::Rest::Generic->new();
isa_ok($api, 'Net::Rest::Generic');
is($api->{mode}, 'get', 'GET is default mode');
is($api->{scheme}, 'https', 'HTTPS is default scheme');
is($api->{string}, '0', 'String mode is defaulted to 0');

1;
