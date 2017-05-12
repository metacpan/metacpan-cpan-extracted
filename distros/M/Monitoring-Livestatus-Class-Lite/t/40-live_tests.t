use strict;
use warnings;
use Test::More;
use Data::Dumper;
unless ( $ENV{MONITORING_LIVESTATUS_CLASS_TEST_PEER} ) {
    plan skip_all => 'no MONITORING_LIVESTATUS_CLASS_TEST_PEER configured';
}

use_ok('Monitoring::Livestatus::Class');

my $class = Monitoring::Livestatus::Class->new( peer => $ENV{MONITORING_LIVESTATUS_CLASS_TEST_PEER}, );
my $hosts = $class->table('hosts');

my $got_statment =
  $hosts->columns('display_name')->filter( { display_name => { '-or' => [qw/test_host_47 test_router_3/] } } )
  ->hashref_array();

my $expected_statment = [ { 'display_name' => 'test_host_47' }, { 'display_name' => 'test_router_3' } ];

is_deeply( $got_statment, $expected_statment, "Simple filter live test" );

my $services = $class->table('services');

$got_statment = $services->stats( { state => [qw/0 1 2 3/] } )->hashref_array();
$expected_statment = [
    {
        'state = 3' => '29',
        'state = 0' => '392',
        'state = 2' => '48',
        'state = 1' => '31'
    }
];

is_deeply( $got_statment, $expected_statment, "Simple filter stats test" );

done_testing(3);
