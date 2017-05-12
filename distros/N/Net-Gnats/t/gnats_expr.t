use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth conn user schema1);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "210 Ok.\r\n",           # Single
                     # cmd does not get defined
                     "210 Ok.\r\n",           # Mult 1
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     "415 Invalid expression.\r\n",
                     "210 Ok.\r\n",           # old skool 1
                     "210 Ok.\r\n",           # old skool 2
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->expr( expressions => ['Priority="High"'] );
my $c2 = Net::Gnats::Command->expr;
my $c3 = Net::Gnats::Command->expr( expressions => ['Priority="High"',
                                                    'Number="10"'] );

is $c1->as_string, 'EXPR Priority="High"', 'string command OK, 1 value';
is $c2->as_string, undef, 'string command undef, no exprs';
is $c3->as_string, 'EXPR Priority="High" & Number="10"',
  'command string OK, 2 values';

is $g->issue($c1)->is_ok, 1, 'Command is OK';
is $g->issue($c2)->is_ok, 0, 'Command is NOT OK';
is $g->issue($c3)->is_ok, 1, 'Command is OK';

## Legacy
# No expressions, undef
$g = Net::Gnats->new();
$g->gnatsd_connect;
$g->login('default', 'madmin','madmin');

is $g->expr, 1, 'no expressions? okay, pass.';

# Bad expression
is $g->expr('bad'), 0, 'Bad expression';

# Single expression
is $g->expr('foo="bar"'), 1, 'Single expression ok';

# Multiple expression
is $g->expr('foo="bar"', 'bar="baz"'), 1, 'Multiple expression ok';


done_testing();

