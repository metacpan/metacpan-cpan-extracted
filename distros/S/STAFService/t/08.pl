#!/usr/bin/perl -w
use strict;
use PLSTAF;
use FindBin;
use Config;
use lib "./t";
use TestSubs;

# Testing multi-threaded service

$| = 1;

my $uselib = $FindBin::Bin;
my $dll = $FindBin::Bin . "/../PERLSRV.$Config{'so'}";

if (my ($slave) = grep m/^-slave=/, @ARGV) {
    my ($slave_id) = $slave =~ m/^-slave=(\d+)$/;
    slave($slave_id);
} else {
    master();
}

sub slave {
    my $slave_id = shift;
    my $handle = staf_register("Test_08_".$slave_id);
    my $max_loops = 3;
    my $status = "OK";
    for my $cycle (1..$max_loops) {
        my $sleep_time = int(rand(8)) + 10;
        my $between_sleeps = int(rand(7)) + 3;
        my $start = time;
        my $result = send_request($handle, "SleepTest", "$sleep_time", 0, "slept well");
        my $end = time;
        my $period = $end - $start;
        # warn "Loop: period = $period, \$sleep_time = $sleep_time";
        if ($result != 1 or $period < $sleep_time-1 or $period > $sleep_time + 3) {
            $status = "NotOK";
        }
        last if $cycle == $max_loops;
        sleep($between_sleeps);
    }
    print $status;
}

sub master {
    print "A long test - please wait...\n";
    my $handle = staf_register("Test_08");
    my_submit($handle, "SERVICE", "ADD SERVICE SleepTest LIBRARY $dll EXECUTE SleepService OPTION USELIB=\"$uselib\"");
    open my $fh1, "-|", "$Config{'perlpath'} t/08.pl -slave=1";
    open my $fh2, "-|", "$Config{'perlpath'} t/08.pl -slave=2";
    open my $fh3, "-|", "$Config{'perlpath'} t/08.pl -slave=3";
    my $slave1 = <$fh1>;
    my $slave2 = <$fh2>;
    my $slave3 = <$fh3>;
    my_submit($handle, "SERVICE", "REMOVE SERVICE SleepTest");
    $handle->unRegister();
    if ($slave1 =~ /^OK/ and $slave2 =~ /^OK/ and $slave3 =~ /^OK/) {
        print "Test - OK\n";
    } else {
        print "Test - NOT OK\n";
    }
}
