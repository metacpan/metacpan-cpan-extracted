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
                     # not issued
                     "350 A default value\r\n",
                     "350-A default value for field1\r\n",
                     "350 A default value for field2\r\n",
                     "350 A default value\r\n",
                     "350-A default value for field1\r\n",
                     "350 A default value for field2\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->inputdefault;
my $c2 = Net::Gnats::Command->inputdefault(fields => ['field']);
my $c3 = Net::Gnats::Command->inputdefault(fields => ['field1', 'field2']);

is $g->issue($c1)->is_ok, 0, 'c1 is NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 is OK';
is $g->issue($c3)->is_ok, 1, 'c3 is OK';

is_deeply $g->issue($c2)->response->as_list, ['A default value'], 'c2 list is OK';
is_deeply $g->issue($c3)->response->as_list, ['A default value for field1','A default value for field2'], 'c3 list is OK';

done_testing();
