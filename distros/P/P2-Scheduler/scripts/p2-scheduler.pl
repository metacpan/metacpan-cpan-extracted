#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: schedule-of-month.pl
#
#  DESCRIPTION: an experiments scheduler for P2.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marco Masetti (), marco.masetti@sky.uk
# ORGANIZATION: SKY uk
#      VERSION: 1.0
#      CREATED: 05/05/2020 23:57:20
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use Getopt::Long qw( GetOptions );
use P2::Scheduler;
use YAML::Syck  qw(Dump LoadFile);

my ( $month, $year, @experiments_files, $spare_days_per_month);
my $starting_from = 1;
my $weights = "2,1,1";
my $num_week_days = 5;
my $selected_week_days_str="1,2,3,4,5";
my $hour_slots_str="1,2,3,4,5";
my $context;
my $fixed_intervals;

GetOptions(
    "month=i"           => \$month,
    "year=i"            => \$year,
    "exp_files=s"       => \@experiments_files,
    "spare_days=i"      => \$spare_days_per_month,
    "starting_from=i"   => \$starting_from,
    "weights=s"         => \$weights,
    "num_week_days=i"   => \$num_week_days,
    "selected_week_days=s"  => \$selected_week_days_str,
    "hour_slots=s"      => \$hour_slots_str,
    "fixed_intervals"   => \$fixed_intervals,
    "context=s"         => \$context
);

die "------------------------------------------------------------------------------
Usage: $0 
    -month [1..12]          :not mandatory 
    -year <year>            :mandatory
    -context <context>      :K8s context (mandatory)
    -exp_files              :yaml-encoded files with experiments sorted by priority
    -spare_days <#>         :number of business days to leave free per month
    -starting_from <#>      :day of each month to start with
    -weights 'x,y,z'        :a comma-separated string with the 3 weights for the
                             priorities starting from highest.
    -num_week_days          :number of business days to consider starting from Monday
                             defauts to 5
    -selected_week_days     :list of business days ids to consider:
                                1 => Monday,..., 5 => Friday
                             for example the string '2,3,4' would set tests to run only
                             between Tuesdays and Thursdays
    -hour_slots             :list of hours of the test shift, separate by commas
    -fixed_intervals        :if experiments times should be strictly scheduled in 
                             fixed intervals or randomly allocated
    -------------------------------------------------------------------------------"
        unless $year && scalar @experiments_files;

my @selected_week_days = split(/,/, $selected_week_days_str);
my @hour_slots = split(/,/, $hour_slots_str);

foreach (@experiments_files) {
    die "experiments file $_ not found or not readable" unless -f $_;
}

my $experiments = [];

foreach my $file ( @experiments_files ) {
    my $exp = LoadFile ( $file );
    for (my $priority=0;$priority<=2;$priority++) {
        next unless $exp->[$priority];
        push @{$experiments->[$priority]}, @{$exp->[$priority]};
    }
}

my $schedule = P2::Scheduler->new(
        experiments         => $experiments,
        weight              => [split(',',$weights)],
        spare_days_per_month=> $spare_days_per_month,
        starting_from       => $starting_from,
        year                => $year,
        num_week_days       => $num_week_days,
        selected_week_days  => \@selected_week_days,
        hour_slots          => \@hour_slots,
        fixed_intervals     => $fixed_intervals,
        context             => $context
);

my @report = ( $month ) ? $schedule->month_schedule( $month ) : $schedule->year_schedule();
print Dump ( [ @report ] );
