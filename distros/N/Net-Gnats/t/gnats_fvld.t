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
                     "301 Valid values follow.\r\n",
                     ".\r\n",
                     "301 Valid values follow.\r\n",
                     "regexp1\r\n",
                     "regexp2\r\n",
                     ".\r\n",
                     "301 Valid values follow.\r\n",
                     ".\r\n",
                     "301 Valid values follow.\r\n",
                     "regexp1\r\n",
                     "regexp2\r\n",
                     ".\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
isa_ok $g->gconnect, 'Net::Gnats::Session';

my $c1 = Net::Gnats::Command->fvld;
my $c2 = Net::Gnats::Command->fvld(field => 'FieldA');
my $c3 = Net::Gnats::Command->fvld(field => 'FieldB');

is $g->issue($c1)->is_ok, 0, 'c1 is NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 is OK';
is $g->issue($c3)->is_ok, 1, 'c3 is OK';

is_deeply $g->issue($c2)->response->as_list, [], 'c2 list is OK';
is_deeply $g->issue($c3)->response->as_list, ['regexp1','regexp2'], 'c3 list is OK';

# is $g->get_field_validators, 0, 'field not passed';
# is $g->get_field_validators('badfield'), 0, 'unknown field';
# is_deeply $g->get_field_validators('goodfield'), [], 'returned array of validators';
# is_deeply $g->get_field_validators('goodfield'), ['regexp1','regexp2'], 'returned array of validators';
# is $g->get_field_validators('garbage'), 0, 'garbage';

done_testing();
