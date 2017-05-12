#!/usr/bin/perl -c

# plackup -s Starlet -E Proxy apt-proxy.psgi

use Plack::Builder;
use Plack::App::Proxy;

builder {
    enable 'AccessLog';
    enable 'Cache',
        match_url => ['/dists/', '\.deb$', '/Packages(\.\w+)$', '\.(gz|bz2)$'],
        cache_dir => '/tmp/apt-cache';
    enable 'Proxy::Connect';
    enable 'Proxy::AddVia';
    enable 'Proxy::Requests';
    Plack::App::Proxy->new->to_app;
};
