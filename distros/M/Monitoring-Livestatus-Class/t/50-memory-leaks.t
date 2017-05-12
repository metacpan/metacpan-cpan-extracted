#!perl

use Test::More;


eval "use Devel::LeakGuard::Object";
plan skip_all => "Devel::LeakGuard::Object required for testing Leaks" if $@;

eval "use Test::Memory::Cycle";
plan skip_all => "Test::Memory::Cycle required for testing Leaks" if $@;

unless ( $ENV{MONITORING_LIVESTATUS_CLASS_TEST_PEER} ) {
    plan skip_all => 'no MONITORING_LIVESTATUS_CLASS_TEST_PEER configured';
}

plan tests => 5;

use_ok('Monitoring::Livestatus::Class');

Devel::LeakGuard::Object->import(qw(leakguard));

my $class = Monitoring::Livestatus::Class->new(peer => $ENV{'MONITORING_LIVESTATUS_CLASS_TEST_PEER'});

my $hosts = $class->table('hosts');
my @data = $hosts->columns('display_name')->filter(
    { display_name => { '-or' => [qw/test_host_47 test_router_3/] } }
)->hashref_array();

memory_cycle_ok($class, 'memory cycle');
weakened_memory_cycle_ok($class, 'weakened memory cycle');

memory_cycle_ok($hosts, 'memory cycle');
weakened_memory_cycle_ok($hosts, 'weakened memory cycle');



leakguard {
    my $table = $class->table('hosts');
    my @data = $table->columns('display_name')->filter(
        { display_name => { '-or' => [qw/test_host_47 test_router_3/] } }
    )->hashref_array();
}
on_leak => sub {
    my $report = shift;
    for my $pkg ( sort keys %$report ) {
        fail(sprintf "%s leaks %d objects", $pkg, ($report->{$pkg}->[1]-$report->{$pkg}->[0]));
    }
};
