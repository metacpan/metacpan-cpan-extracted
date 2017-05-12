use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::Command::ADMV;
use Net::Gnats::Session;

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                     "351-The current user access level is:\r\n",
                     "350 admin\r\n",
                   );

my $g = Net::Gnats::Session->new(no_schema => 1);
isa_ok $g->gconnect, 'Net::Gnats::Session';

isa_ok my $a = Net::Gnats::Command::ADMV->new, 'Net::Gnats::Command::ADMV';
isa_ok my $b = Net::Gnats::Command::ADMV->new( field_name => 'foo',
                                               key => 'bar'), 'Net::Gnats::Command::ADMV';
isa_ok my $c = Net::Gnats::Command->admv, 'Net::Gnats::Command::ADMV';

is $b->as_string, 'ADMV foo bar';

done_testing;
