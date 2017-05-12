#!/usr/bin/perl -c

# plackup -s Starlet -E Proxy proxy.psgi

use lib '../lib', 'lib';

use Plack::Builder;
use Plack::App::Proxy;

builder {
    enable 'AccessLog';
    enable 'Proxy::Connect';
    enable 'Proxy::AddVia';
    enable 'Proxy::Requests';
    Plack::App::Proxy->new->to_app;
};
