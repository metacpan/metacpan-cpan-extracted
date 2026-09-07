#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 8;

# Not in a BEGIN block: the plan is emitted at run time, and a BEGIN would put
# these ok lines in front of it - which is a TAP parse error, not a pass.
use_ok('Punk::Challenge')         || BAIL_OUT('the facade did not load');
use_ok('Punk::Plugin::Challenge') || BAIL_OUT('the plugin did not load');
use_ok('Punk::Challenge::Token')  || BAIL_OUT('the token module did not load');
use_ok('Punk::Challenge::Solver') || BAIL_OUT('the solver module did not load');

# The modules ship together and are versioned together. A facade that drifts
# from its plugin is a dependency nobody can pin.
is($Punk::Plugin::Challenge::VERSION, $Punk::Challenge::VERSION,
    'the plugin and the facade carry the same version');
is($Punk::Challenge::Token::VERSION, $Punk::Challenge::VERSION,
    'the token module and the facade carry the same version');
is($Punk::Challenge::Solver::VERSION, $Punk::Challenge::VERSION,
    'the solver module and the facade carry the same version');

# One bundle: the plugin's XSUBs are there once any module of the dist loaded.
can_ok('Punk::Plugin::Challenge', qw(new register));

diag("Testing Punk::Challenge $Punk::Challenge::VERSION, Perl $], $^X");
