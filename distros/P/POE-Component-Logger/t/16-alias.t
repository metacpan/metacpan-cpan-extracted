# Tests with an alternate session alias
# Author: Olivier Mengué <dolmen@cpan.org>

use strict;
use warnings;

my @tests;

BEGIN {
    @tests = (
        { level =>   warning => message => '1. Warning'   },
        { level =>     error => message => '2. Error'     },
        { level =>     alert => message => '3. Alert'     },
        { level =>  critical => message => '4. Critical'  },
    );
}

use Test::NoWarnings;
use Test::More tests => 9+2*@tests;

use t::lib::Log::Dispatch::Config::Test \@tests;

use POE;
use POE::Component::Logger;

is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';

my $log_alias = 'mylog';
is $poe_kernel->alias_resolve($log_alias), undef, "'logger' session doesn't exists";

POE::Component::Logger->spawn(
    Alias => $log_alias,
    ConfigFile => t::lib::Log::Dispatch::Config::Test->configurator,
);

is $poe_kernel->alias_resolve('logger'), undef, "'logger' session exists";
isnt $poe_kernel->alias_resolve($log_alias), undef, "'logger' session exists";

is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            $poe_kernel->yield('evt1');
        },
        evt1 => sub {
            $poe_kernel->post($log_alias => log => { level => warning => message => '1. Warning'});
            $poe_kernel->yield('evt2');
        },
        evt2 => sub {
            $poe_kernel->post($log_alias => log => { level => error => message => '2. Error'});
            $poe_kernel->post($log_alias => alert => '3. Alert');
            $poe_kernel->post($log_alias => critical => '4. ', 'Critical');
        },
        _stop => sub {
            pass "_stop";
        },
    },
);

POE::Kernel->run;

pass "POE kernel shutdown";

# vim: set et ts=4 sw=4 sts=4 :
