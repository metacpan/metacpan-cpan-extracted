#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Fatal;
use Plack::Middleware::WURFL::ScientiaMobile;
use Plack::Builder;

ok my $mw = Plack::Middleware::WURFL::ScientiaMobile->new(config => { api_key => '000000:00000000000000000000000000000000' }),
    'created test object';

isa_ok $mw->client, 'Net::WURFL::ScientiaMobile',
    'correctly created ScientiaMobile client';

ok my $app = sub { [200, ['Content-Type' => 'text/plain'], ['Hello!']] },
    'made a Plack compatible application';

is (
    exception {
        $app = builder {
            enable 'WURFL::ScientiaMobile', config => {
                api_key => '000000:00000000000000000000000000000000',
            };
            $app;
        };      
    },
    undef,
    'No errors wrapping the application',
);

done_testing;
