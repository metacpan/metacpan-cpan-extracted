#!/usr/bin/env perl
use strict;
use warnings;

# The ceiling for punk-api: the identical spec + handler through
# Open::API::Plack's all-C dispatch pipeline.

use Open::API::Plack;

my $spec = {
    openapi => '3.1.0',
    info    => { title => 'Bench', version => '1' },
    paths   => { '/' => { get => {
        operationId => 'hello',
        parameters  => [ {
            name => 'limit', in => 'query',
            schema => { type => 'integer', minimum => 1, maximum => 100 },
        } ],
        responses => { 200 => { description => 'ok' } },
    } } },
};

Open::API::Plack->new(
    spec     => $spec,
    handlers => { hello => sub { { hello => 'world' } } },
)->to_app;
