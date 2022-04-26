use warnings;
use strict;

use lib 't/';

use Data::Dumper;
use Mock::Sub;
use Tesla::API;
use Test::More;
use TestResponse;
use TestSuite;

my $ms = Mock::Sub->new;
my $ts = TestSuite->new;

my $req_sub = $ms->mock('WWW::Mechanize::request');
my $t = Tesla::API->new(unauthenticated => 1);

# test the TestRespone object
{
    my $r = TestResponse->new(1, 200, '{"a" : 1}', 'error');

    is $r->is_success, 1, "is_success() returns ok";
    is $r->code, 200, "code() returns ok";
    is $r->decoded_content, '{"a" : 1}', "decoded_content() returns ok";
    is $r->status_line, 'error', "status_line() returns ok";
}

# one pass - success
{
    my $response = TestResponse->new(1, 200, '{"a" : 1}', '');
    $req_sub->return_value($response);

    my @ret = $t->_tesla_api_call(10);

    is $req_sub->called_count, 1, "request() was called only once ok";
    is $t->_api_attempts, 1, "_tesla_api_call() only called once ok";

    is $ret[0], 1, "is_success() returned 1 ok";
    is $ret[1], 200, "code() returned 200 ok";
    is $ret[2], '{"a" : 1}', "decoded_content() returned ok";
}

# retry - failure
{
    my $response = TestResponse->new(0, 500, '', '500 - Timeout');
    $req_sub->reset;
    $req_sub->return_value($response);

    my @ret = $t->_tesla_api_call(10);

    is $req_sub->called_count, 3, "request() was called only once ok";
    is $t->_api_attempts, 3, "_tesla_api_call() only called once ok";

    is $ret[0], 0, "is_success() returned 1 ok";
    is $ret[1], 500, "code() returned 200 ok";
    is $ret[2], '{"error" : "500 - Timeout"}', "decoded_content() returned ok";
}


done_testing();