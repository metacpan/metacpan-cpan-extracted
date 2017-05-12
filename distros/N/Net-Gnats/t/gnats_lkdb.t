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
                     "210 GNATS database is now locked\r\n",
                     "600 CODE_ERROR\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "431 CODE_GNATS_LOCKED\r\n",
                   );

isa_ok my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin'), 'Net::Gnats::Session';
$g->gconnect();

my $c1 = Net::Gnats::Command->lkdb;
my $c2 = Net::Gnats::Command->lkdb;
my $c3 = Net::Gnats::Command->lkdb;
my $c4 = Net::Gnats::Command->lkdb;

is $g->issue($c1)->is_ok, 1, 'c1 OK';
is $g->issue($c2)->is_ok, 0, 'c2 NOT OK';
is $g->issue($c3)->is_ok, 0, 'c3 NOT OK';
is $g->issue($c4)->is_ok, 0, 'c4 NOT OK';


# is $g->lock_main_database, 1, '210 locked';
# is $g->lock_main_database, 0, 'ERROR 600 Can lock database';
# is $g->lock_main_database, 0, 'CODE_CMD_ERROR';
# is $g->lock_main_database, 0, 'CODE_CMD_ERROR';

done_testing();
