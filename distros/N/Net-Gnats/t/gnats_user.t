use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "351-The current user access level is:\r\n",
                     "350 admin\r\n",
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     "422 CODE_NO_ACCESS\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin')->gconnect;

my $c1 = Net::Gnats::Command->user; #ok
my $c2 = Net::Gnats::Command->user(username => 'foo'); #bad
my $c3 = Net::Gnats::Command->user(username => 'foo', password => 'bar'); #ok
my $c4 = Net::Gnats::Command->user(username => 'foo', password => 'baz'); #bad pass

is $g->issue($c1)->is_ok, 1, 'c1 OK';
is $g->issue($c2)->is_ok, 0, 'c2 NOT OK';
is $g->issue($c3)->is_ok, 1, 'c3 OK';
is $g->issue($c4)->is_ok, 0, 'c4 NOT OK';


# my $g = Net::Gnats->new();
# $g->gnatsd_connect;

# is $g->cmd_user, undef, 'Must have 2 arguments';
# is $g->cmd_user("user"), undef, 'Must have 2 arguments';
# is $g->cmd_user("user", "badpass"), undef, 'ERROR 422 No Access';
# is $g->cmd_user("user", "goodpass"), undef, 'CODE_OK';

done_testing();
