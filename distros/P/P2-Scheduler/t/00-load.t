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
        experiments => [[qw(
                exp-1-1
                exp-1-2
                exp-1-3
                exp-1-4
                exp-1-5
                exp-1-6
                exp-1-7
            )],[qw(
                exp-2-1
                exp-2-2
                exp-2-3
                exp-2-4
                exp-2-5
            )],[qw(
                exp-3-1
                exp-3-2
                exp-3-3
            )]],
        weight => [3,2,1],
        spare_days_per_month => 2,
        num_week_days => 2,
        starting_from => 6,
        year  => 2020,
        hour_slots => [12,13,14,15],
        fixed_intervals => 1,
        context => 'test context'
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
