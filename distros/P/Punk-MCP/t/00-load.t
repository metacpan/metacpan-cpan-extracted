#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 6;

# Not in a BEGIN block: the plan is emitted at run time, and a BEGIN would put
# these ok lines in front of it, which is a TAP parse error, not a pass.
use_ok('Punk::MCP')          || BAIL_OUT('the facade did not load');
use_ok('Punk::Plugin::MCP')  || BAIL_OUT('the plugin did not load');
use_ok('Punk::Command::Mcp') || BAIL_OUT('the command did not load');

# A load test passes for a .pm whose XS never booted, so call into the C.
is(Punk::Plugin::MCP::_dist(), 'Punk::MCP', 'the XS booted');

# The modules ship together and are versioned together. One that drifts is a
# dependency nobody can pin.
is($Punk::Plugin::MCP::VERSION,  $Punk::MCP::VERSION,
    'the plugin and the facade carry the same version');
is($Punk::Command::Mcp::VERSION, $Punk::MCP::VERSION,
    'the command and the facade carry the same version');

diag("Testing Punk::MCP $Punk::MCP::VERSION, Perl $], $^X");
