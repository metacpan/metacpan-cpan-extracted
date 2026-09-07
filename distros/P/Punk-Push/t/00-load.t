#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 8;

use_ok('Punk::Push')                || BAIL_OUT('the facade did not load');
use_ok('Punk::Push::Subscription')  || BAIL_OUT('Subscription did not load');
use_ok('Punk::Push::Result')        || BAIL_OUT('Result did not load');
use_ok('Punk::Plugin::Push')        || BAIL_OUT('the plugin did not load');
use_ok('Punk::Command::Push')       || BAIL_OUT('the command did not load');

# Everything in the distribution is versioned together. A module that drifts
# from its siblings is a dependency nobody can pin.
my @drift;
{
    no strict 'refs';
    @drift = grep { ${"${_}::VERSION"} ne $Punk::Push::VERSION }
        qw(Punk::Push::Subscription Punk::Push::Result
           Punk::Plugin::Push Punk::Command::Push);
}
is_deeply(\@drift, [], 'every module carries the same version')
    or diag "out of step: @drift";

isa_ok(Punk::Plugin::Push->new, 'Punk::Plugin',
    'the plugin is a Punk::Plugin');

# VAPID 2.00 or newer: 1.06 sends the superseded aesgcm draft and spells the
# auth scheme "vapit", which a conformant push service refuses.
cmp_ok($VAPID::VERSION, '>=', 2.00, "VAPID $VAPID::VERSION is 2.00 or newer");

diag("Testing Punk::Push $Punk::Push::VERSION, Perl $], $^X");
