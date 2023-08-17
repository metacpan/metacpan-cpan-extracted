#!/usr/bin/perl -c

use strict;
use warnings;

use lib '../lib', 'lib';

use Log::Log4perl qw(:levels get_logger);
Log::Log4perl->init('traffic.l4p');
my $logger = get_logger('traffic');

use YAML::XS;

use Plack::Builder;

my $app = builder {
    enable "Plack::Middleware::TrafficLog",
        logger => sub { $logger->log($INFO, join '', @_) },
        eol    => "\n";
    sub { [200, ['Content-Type' => 'text/plain'], [Dump \@_]] };
};
