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
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "418 CODE_INVALID_QUERY_FORMAT\r\n",
                   );

my $g = Net::Gnats::Session
  ->new(username => 'madmin', password => 'madmin')
  ->gconnect;

my $c1 = Net::Gnats::Command->qfmt;
my $c2 = Net::Gnats::Command->qfmt(format => 'full');
my $c3 = Net::Gnats::Command->qfmt(format => 'summary');

is $g->issue($c1)->is_ok, 0, 'c1 NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 OK';
is $g->issue($c3)->is_ok, 1, 'c3 OK';


# is $g->qfmt, 1, 'defaults to STANDARD';
# is $g->qfmt('full'), 1, 'FULL is OK';
# is $g->qfmt('summary'), 1, 'SUMMARY is OK';
# is $g->qfmt(''), 0, 'HIT CODE_CMD_ERROR';
# is $g->qfmt('%R%E%DEGFHF'), 0, 'bogus format error';

done_testing();

