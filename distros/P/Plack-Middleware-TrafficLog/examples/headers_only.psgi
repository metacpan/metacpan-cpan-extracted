#!/usr/bin/perl -c

use strict;
use warnings;

use lib '../lib', 'lib';

use YAML::XS;

use Plack::Builder;

my $app = builder {
    enable "Plack::Middleware::TrafficLog",
        with_body => 0;
    sub { [200, ['Content-Type' => 'text/plain'], [Dump \@_]] };
};
