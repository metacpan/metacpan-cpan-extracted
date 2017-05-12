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
                     "212 Ok, send field text now.\r\n",
                     "210 Ok.\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin')->gconnect;
my $field = Net::Gnats::FieldInstance->new( name => 'foo', value => 'bar' );

my $c1 = Net::Gnats::Command->vfld;
my $c2 = Net::Gnats::Command->vfld(field => $field);

is $c1->as_string, undef, 'c1 command is undef';
is $c2->as_string, 'VFLD foo', 'c2 command is fine';

is $g->issue($c1)->is_ok, 0, 'c1 NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 OK';


# is $g->validate_field, undef, 'req 2 param, got none';
# is $g->validate_field('fld'), undef, 'req 2 param, got one';
# is $g->validate_field('unk','foo'), undef, 'req 2 param, fld is unknown';
# is $g->validate_field('fld','foo'), 1, 'req 2 param, fld is good';

done_testing();
