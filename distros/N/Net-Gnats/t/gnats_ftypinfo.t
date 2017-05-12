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
                     "350 ':' ';'\r\n",
                     "350 ':' ';'\r\n",
                     "350 ':' ';'\r\n",
                     "350 ':' ';'\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->ftypinfo;
my $c2 = Net::Gnats::Command->ftypinfo(field => 'fieldA' );
my $c3 = Net::Gnats::Command->ftypinfo(field => 'fieldB' );

is $g->issue($c1)->is_ok, 0, 'c1 is NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 is OK';
is $g->issue($c3)->is_ok, 1, 'c3 is OK';

is $g->issue($c2)->response->as_string, q{':' ';'}, 'c2 response is OK';
is $g->issue($c3)->response->as_string, q{':' ';'}, 'c3 response is OK';

# is $g->get_field_type_info, 0,     'Not enough args';
# is $g->get_field_type_info('field'), q{':' ';'},     'OK';
# is $g->get_field_type_info('field','myprop'),  q{':' ';'},     'OK';
# is $g->get_field_type_info, 0, 'ERROR 600 Unknown';
# is $g->get_field_type_info, 0, 'CODE_CMD_ERROR';
# is $g->get_field_type_info, 0, 'CODE_CMD_ERROR';

done_testing();
