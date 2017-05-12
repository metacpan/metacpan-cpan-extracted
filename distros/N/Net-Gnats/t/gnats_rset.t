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
                     "210 Reset state.\r\n",
                     "600 unknown\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->rset;

is $g->issue($c1)->is_ok, 1, '210 reset';
is $g->issue($c1)->is_ok, 0, '600 unknown';
is $g->issue($c1)->is_ok, 0, '440 CODE_CMD_ERROR';

done_testing();
