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
                     "210 CODE_OK\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
isa_ok $g->gconnect, 'Net::Gnats::Session';

my $c1 = Net::Gnats::Command->chdb;
my $c2 = Net::Gnats::Command->chdb(database => 'foo');

is $g->issue($c1)->is_ok, 0, 'c1 is NOT OK';
is $g->issue($c2)->is_ok, 1, 'c2 is OK';

# is( $g->login('foo', 'bar', 'baz'), 1,     '200 Login OK' );
# is( $g->login('foo', 'bar', 'baz'), undef, 'ERROR 422 BAD USERNAME PASSWORD' );
# is( $g->login('foo', 'bar', 'baz'), undef, 'ERROR UNK GARBAGE' );
# is( $g->login('foo', 'bar', 'baz'), undef, 'ERROR 417 BAD DATABASE');

done_testing();
