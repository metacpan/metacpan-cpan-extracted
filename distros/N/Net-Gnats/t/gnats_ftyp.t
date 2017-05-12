use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth conn user schema1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "350 Text\r\n",
                     "350 Enum\r\n",
                     "350-Text\r\n",
                     "350 Enum\r\n",
                     "350 Text\r\n",
                     "350 Enum\r\n",
                     "350-Text\r\n",
                     "350 Enum\r\n",
                     #
                     # Do same thing, but through Net::Gnats
                     #
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     "350 Text\r\n",
                     "350 Enum\r\n",
                     "350-Text\r\n",
                     "350 Enum\r\n",
                     "410 Invalid field name.\r\n",
                     );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->ftyp;
my $c2 = Net::Gnats::Command->ftyp(fields => ['fieldA'] );
my $c3 = Net::Gnats::Command->ftyp(fields => ['fieldB'] );
my $c4 = Net::Gnats::Command->ftyp(fields => ['field1', 'field2']);

is $g->issue($c1)->is_ok, 0, 'c1 command NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 command OK';
is $g->issue($c3)->is_ok, 1, 'c3 command OK';
is $g->issue($c4)->is_ok, 1, 'c4 command OK';

is_deeply $g->issue($c2)->response->as_list, ['Text'], 'c2 list OK';
is_deeply $g->issue($c3)->response->as_list, ['Enum'], 'c3 list OK';
is_deeply $g->issue($c4)->response->as_list, ['Text', 'Enum'], 'c4 list OK';

#---- via Net::Gnats
my $gnats = Net::Gnats->new;
$gnats->gnatsd_connect;
$gnats->login('default', 'madmin', 'madmin');
is $gnats->get_field_type, 0,     'field not passed';
is @{$gnats->get_field_type('Release')}[0], 'Text',     'isa text field';
is @{$gnats->get_field_type('Class')}[0],   'Enum',     'isa enum field';
is_deeply $gnats->get_field_type(['Release','Class']), ['Text', 'Enum'],
  'two fields';
is $gnats->get_field_type('Invalid'), 0, 'invalid field';

done_testing();
