#!/usr/bin/env perl

use strict;
use warnings;
use lib './lib';
use Plack::Builder;

my $app = sub {
    return [
        404, [ 'Content-Type' => 'text/plain' ],
        ['Not found, try /index.html'] ];
};

my $root = 'samples/html';

builder {
    enable "Plack::Middleware::AutoRefresh",
      dirs   => [$root],
      filter => qr/.swp|.bak/;
    ## filter => sub { shift =~ /index/ };

    enable "Plack::Middleware::Static",
      path => sub { s{^/$}{index.html}; 1 },
      root => $root;
    $app;
}

