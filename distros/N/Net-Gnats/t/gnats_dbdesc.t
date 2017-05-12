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
                     "440 One database name required.\r\n",
                     "350 Bug database\r\n",
                     "350 Bug database\r\n",
                     "417 No such database as `defaulter'\r\n",
                     "417 No such database as `defaulter'\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c_noname = Net::Gnats::Command->dbdesc();
my $c_name = Net::Gnats::Command->dbdesc(name => 'default');
my $c_badname = Net::Gnats::Command->dbdesc(name => 'defaulter');

is $g->issue($c_noname)->is_ok, 0, 'return 440 on no name';
is $g->issue($c_name)->is_ok, 1, 'return 350 on good name';
is $g->issue($c_name)->response->as_string, 'Bug database', 'got the description';
is $g->issue($c_badname)->is_ok, 0, 'return 417 on bad name';
is $g->issue($c_badname)->response->as_string, q{No such database as `defaulter'},
  'return error on bad name';

done_testing();
