#!/usr/bin/env perl
use warnings;
use strict;

use Plack::Test;
use Plack::Builder;

use HTTP::Request::Common;
use Test::More;

my $handler = builder {
    enable "AMF", path => qr(^/amf);
    sub {
        [200, ['Content-Type' => 'text/plain'], ['ok']]
    };
};

my %test = (
    client => sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "http://localhost/amf");
            is $res->content_type, 'application/x-amf';
			is $res->content, '';
        }
		
		{
            my $res = $cb->(GET "http://localhost/test");
            is $res->content_type, 'text/plain';
			is $res->content, 'ok';
        }
	},
    app => $handler,
);

test_psgi %test;

done_testing;