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
                     "440 CODE_CMD_ERROR\r\n",
                     "210 PR 5 unlocked.\r\n",
                     "433 CODE_PR_NOT_LOCKED\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

# this method just requires and ID when in fact it _should_ be a PR
# instance.

my $c1 = Net::Gnats::Command->unlk;
my $c2 = Net::Gnats::Command->unlk( pr_number => '5' );

is $g->issue($c1)->is_ok, 0, 'c1 NOT OK';
is $g->issue($c2)->is_ok, 0, 'c2 CODE_CMD_ERROR';
is $g->issue($c2)->is_ok, 1, 'c2 CODE_OK';
is $g->issue($c2)->is_ok, 0, 'c2 CODE_PR_NOT_LOCKED';


# my $p = 1;

# is $g->unlock_pr, 0, 'must pass a pr';
# is $g->unlock_pr($p), 0, '440 CODE_CMD_ERROR';
# is $g->unlock_pr($p), 1, '210 CODE_OK';
# is $g->unlock_pr($p), 0, '433 CODE_PR_NOT_LOCKED';

done_testing();
