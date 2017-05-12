#!/usr/bin/env perl
 
use strict;
use warnings FATAL => 'all';
 
use Test::More;
use Plack::Test;
use Plack::Middleware::WURFL::ScientiaMobile;
use HTTP::Request::Common qw(GET);
use Scalar::Util qw(refaddr);
 
ok my $app = sub {
    my $env = shift;
    my $error = Plack::Middleware::WURFL::ScientiaMobile->get_error_from_env($env);

    [200, [], [ref $error]];
}, 'Got a sample Plack application';
 
ok $app = Plack::Middleware::WURFL::ScientiaMobile->wrap($app, config => { api_key => '000000:00000000000000000000000000000000' }), 
    'Wrapped application with middleware';

test_psgi $app, sub {
    my $cb = shift;
    
    my $res = $cb->(GET '/')->content;
    ok $res =~ /^Net::WURFL::ScientiaMobile::Exception/,
        'Exception correctly trapped';
};

done_testing;
