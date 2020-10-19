use v5.18;
use strict;
use warnings;
use Test::More;
use Data::Printer;

BEGIN {
    use_ok( 'P2::Scheduler' ) || print "Bail out!\n";
}

diag( "Testing P2::Scheduler $P2::Scheduler::VERSION, Perl $], $^X" );
ok( my $o = P2::Scheduler->new(
        resource_type => 'namespace',
        resources => [[qw(
                res-1-1
                res-1-2
                res-1-3
                res-1-4
                res-1-5
                res-1-6
                res-1-7
            )],[qw(
                res-2-1
                res-2-2
                res-2-3
                res-2-4
                res-2-5
            )],[qw(
                res-3-1
                res-3-2
                res-3-3
                a-quite-long-resource-name-that-should-exceed-fourty-characters
            )]],
        weight => [3,2,1],
        spare_days_per_month => 2,
        num_week_days => 2,
        starting_from => 6,
        year  => 2020,
        hour_slots => [12,13,14,15],
        fixed_intervals => 1,
        context => 'test context',
        label => 'scale-down-up',
        action => 'Scale all deployments down and up again',
    ), 'new');

ok( my @business_days = $o->_get_business_days_of_month( 5 ) );
p @business_days;

ok( my @year_schedule = $o->year_schedule(), 'year_schedule');
diag "Year schedule";
p @year_schedule;

ok( my @month_schedule = $o->month_schedule(5), 'month schedule');
diag "Month schedule";
p @month_schedule;

done_testing();
