use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth conn conn_bad user schema1);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_true( 'close' );
$module->set_series( 'getline',
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     "201 CODE_CLOSING\r\n",
                     @{ conn_bad() },
                     "201 CODE_CLOSING\r\n",
                     @{ conn_bad() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     "201 CODE_CLOSING\r\n",
                     );

isa_ok my $g1 = Net::Gnats->new(), 'Net::Gnats';
is $g1->gnatsd_connect, 1, 'init using gnatsd_connect';
is $g1->login('default', 'madmin', 'madmin'), 1, 'login using Net::Gnats login()';
is $g1->disconnect, 1, 'logout using Net::Gnats disconnect()';

isa_ok my $g2 = Net::Gnats->new(), 'Net::Gnats';
is $g2->gnatsd_connect, 0, 'Net::Gnats gnatsd_connect fails on unsupported version';  # unsupported version

isa_ok my $g3 = Net::Gnats->new(), 'Net::Gnats';
is $g3->skip_version_check(1), 1, 'Set skip_version_check';
is $g3->gnatsd_connect, 1, 'init using gnatsd_connect with skip_version_check';  # version override
is $g3->login('default', 'madmin', 'madmin'), 1, 'login using madmin-madmin';
is $g3->disconnect, 1, 'quit session';

done_testing;
