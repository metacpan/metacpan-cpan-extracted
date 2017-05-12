# Test case for RT#62397: Logger->log does not uses $DefaultLevel synchronously
# Author: Olivier Mengué <dolmen@cpan.org>

use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 17;

my @tests;

BEGIN {
    @tests = (
        { level => error   => message => '1. Error', TODO => 'Fix this race case' },
        { level => warning => message => '2. Warning' },
        { level => warning => message => '3. Warning' },
        { level => error   => message => '4. Error', TODO => 'Fix this race case' },
        { level => warning => message => '5. Warning' },
    );
}

use t::lib::Log::Dispatch::Config::Test \@tests;

use POE;
use POE::Component::Logger;

POE::Component::Logger->spawn(
    ConfigFile => t::lib::Log::Dispatch::Config::Test->configurator);

is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            $POE::Component::Logger::DefaultLevel = 'error';
            Logger->log('1. Error');
            $POE::Component::Logger::DefaultLevel = 'warning';
            Logger->log('2. Warning');
            $poe_kernel->yield('next');
            # Log events will be processed before 'next' as they have
            # been laucnhed before
        },
        next => sub {
            is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';
            Logger->log('3. Warning');
            {
                local $POE::Component::Logger::DefaultLevel = 'error';
                Logger->log('4. Error');
            }
            is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';
            Logger->log('5. Warning');
        },
        _stop => sub {
            pass "_stop";
        },
    },
);

POE::Kernel->run;

pass "POE kernel shutdown";

# vim: set et ts=4 sw=4 sts=4 :
