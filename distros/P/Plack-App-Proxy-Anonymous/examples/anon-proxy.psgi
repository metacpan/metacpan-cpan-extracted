#!/usr/bin/perl -c

# starlight anon-proxy.psgi --port=8080 --max-workers=25

use lib '../lib', 'lib';

use strict;
use warnings;

use Plack::Builder;
use Plack::App::Proxy::Anonymous;

builder {
    enable 'AccessLog';
    enable 'Proxy::Requests';
    Plack::App::Proxy::Anonymous->new->to_app;
};
