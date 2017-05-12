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
                     "350 FLAG\r\n",
                     "350-FLAG1\r\n",
                     "350 FLAG2\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->fieldflags;
my $c2 = Net::Gnats::Command->fieldflags(fields => ['field'] );
my $c3 = Net::Gnats::Command->fieldflags(fields => ['field1', 'field2']);

is $g->issue($c1)->is_ok, 0, 'not enough arguments';
is $g->issue($c2)->is_ok, 1, 'c2 okay';
is $g->issue($c3)->is_ok, 1, 'c3 okay';

#   get_field_flags, 0,     'Not enough args';
# is_deeply $g->get_field_flags('field'), ['FLAG'],     'OK';
# is_deeply $g->get_field_flags(['field1','field2']), ['FLAG1','FLAG2'], 'OK';
# is $g->get_field_flags, 0, '440 CODE_CMD_ERROR';
# is $g->get_field_flags, 0, '431 CODE_CMD_ERROR';

done_testing();
