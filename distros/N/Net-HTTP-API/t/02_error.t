use strict;
use warnings;
use Test::More;
use Test::Exception;

package test::api::missing_api_base_url;
use Net::HTTP::API;

net_api_method user => (method => 'GET', path => '/user/');

package main;

ok my $t = test::api::missing_api_base_url->new;
dies_ok { $t->user } 'die with missing url';
like $@, qr/'api_base_url' have not been defined/, 'missing api_base_url';

done_testing;
