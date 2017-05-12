# Test our Log::Dispatch/Log::Dispatch::Config testing infrastructure
# Author: Olivier Mengué <dolmen@cpan.org>

use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 5;

use Log::Dispatch::Config;
use t::lib::Log::Dispatch::Configurator::Static;
use t::lib::Log::Dispatch::Expect;

{
    no warnings 'redefine';
    *t::lib::Log::Dispatch::Expect::expect = sub {
        Test::More::is($a->{level}, $b->{level}, "level $b->{level} ok");
        Test::More::is($a->{message}, $b->{message}, "message ok");
    };
}


my @expected = (
    { level => info => message => 'Info 1' },
    { level => debug => message => 'Debug 1' },
);



Log::Dispatch::Config->configure(t::lib::Log::Dispatch::Configurator::Static->new(
    format => undef,
    dispatchers => {
	    test => {
            class => 't::lib::Log::Dispatch::Expect',
            min_level => 'debug',
            expected => [
                @expected
            ],
        }
    }
));

my $logger = Log::Dispatch::Config->instance;

foreach my $message (@expected) {
    $logger->log(%$message);
}

# vim: set et ts=4 sw=4 sts=4 :
