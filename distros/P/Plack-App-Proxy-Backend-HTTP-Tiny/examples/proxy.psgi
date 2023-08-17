#!/usr/bin/perl -c

# starlight proxy.psgi --port=8080 --max-workers=25

use lib '../lib', 'lib';

use strict;
use warnings;

use Plack::Builder;
use Plack::App::Proxy;

builder {
    enable 'AccessLog';
    enable 'Proxy::Requests';
    Plack::App::Proxy->new(backend => 'HTTP::Tiny', options => { timeout => 15 })->to_app;
};
