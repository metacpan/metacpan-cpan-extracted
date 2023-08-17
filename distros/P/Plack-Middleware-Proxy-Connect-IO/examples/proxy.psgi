#!/usr/bin/perl -c

# starlight proxy.psgi --port=8080 --max-workers=25

use lib '../lib', 'lib';

use strict;
use warnings;

use Plack::Builder;
use Plack::App::Proxy;

builder {
    enable 'AccessLog';
    enable 'Proxy::Connect::IO', timeout => 30;
    enable 'Proxy::Requests';
    Plack::App::Proxy->new(backend => 'HTTP::Tiny')->to_app;
};
