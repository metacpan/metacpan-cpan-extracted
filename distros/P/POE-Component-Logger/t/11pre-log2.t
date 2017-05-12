# Test our Log::Dispatch/Log::Dispatch::Config testing infrastructure
# Author: Olivier Mengué <dolmen@cpan.org>

use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 5;

my @tests;

BEGIN {
    @tests = (
        { level => info => message => 'Info 1' },
        { level => debug => message => 'Debug 1' },
    );
}

use t::lib::Log::Dispatch::Config::Test \@tests;

my $logger = Log::Dispatch::Config->instance;

foreach my $message (@tests) {
    $logger->log(%$message);
}

# vim: set et ts=4 sw=4 sts=4 :
