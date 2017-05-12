use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::Session;

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "212 Ok.",  # send text
                     "210 Ok.",  # accept text
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
isa_ok $g->gconnect, 'Net::Gnats::Session';

my $field = Net::Gnats::FieldInstance->new( name => 'foo', value => 'bar' );

my $c1 = Net::Gnats::Command->appn;
my $c2 = Net::Gnats::Command->appn( pr_number => '5' );
my $c3 = Net::Gnats::Command->appn( field => $field );
my $c4 = Net::Gnats::Command->appn( pr_number => '5', field => $field );

is $g->issue($c1)->is_ok, 0, 'c1 NOT OK';
is $g->issue($c2)->is_ok, 0, 'c2 NOT OK';
is $g->issue($c3)->is_ok, 0, 'c3 NOT OK';
is $g->issue($c4)->is_ok, 1, 'c4 OK';

done_testing();
