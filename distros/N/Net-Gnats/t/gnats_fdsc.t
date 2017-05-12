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
                     # nothing issued
                     "350 Description for field\r\n",
                     "350-Description for field1\r\n",
                     "350 Description for field2\r\n",
                     "350 Description for field\r\n",
                     "350-Description for field1\r\n",
                     "350 Description for field2\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->fdsc;
my $c2 = Net::Gnats::Command->fdsc(fields => ['field'] );
my $c3 = Net::Gnats::Command->fdsc(fields => ['field1', 'field2']);

is $c1->as_string, undef, 'c1 command is undef';
is $c2->as_string, 'FDSC field', 'c2 command single';
is $c3->as_string, 'FDSC field1 field2', 'c3 command multi';

is $g->issue($c1)->is_ok, 0, 'c1 NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 IS OK';
is $g->issue($c3)->is_ok, 1, 'c3 IS OK';

is_deeply $g->issue($c2)->response->as_list, ['Description for field'], 'c2 list IS OK';
is_deeply $g->issue($c3)->response->as_list, ['Description for field1','Description for field2'], 'c3 list IS OK';

#is_deeply $g->get_field_desc('field'), ['Description for field'], 'Single field';
#is_deeply $g->get_field_desc(['field1','field2']), ['Description for field1','Description for field2'], 'Multi field';
#is $g->get_field_desc, 0, 'ERROR 600';
#is $g->get_field_desc, 0, 'CODE_CMD_ERROR';
#is $g->get_field_desc, 0, 'CODE_CMD_ERROR';

done_testing();
