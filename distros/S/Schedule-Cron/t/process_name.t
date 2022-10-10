#!/usr/bin/perl

# Test the process naming options: processname, processprefix, and nostatus.

use Test::More tests => 6;
use Schedule::Cron;
use strict;
use warnings;

my $orig_proc_name = $0;

my $dispatch_1 = sub {
    my $test_msg = 'process name suffixed with debug status by default';
    my $process_name_rx = '^Schedule::Cron MainLoop - next: '.scalar(localtime).'$';
    if ($0 =~ /$process_name_rx/) {
        die "1-$test_msg\n";
    }
    else {
        die "0-$test_msg\n";
    }
};
my $cron = Schedule::Cron->new(
    $dispatch_1,
    nofork => 1,
);
$cron->add_entry('* * * * * 0-59');
eval {
    $cron->run();
};
my $error = $@;
chomp $error;
my ($ok, $msg) = split '-', $error, 2;
ok $ok, $msg;
$0 = $orig_proc_name;

my $dispatch_2 = sub {
    my $test_msg = q(process name doesn't change with nostatus);
    if ($0 eq $orig_proc_name) {
        die "1-$test_msg\n";
    }
    else {
        die "0-$test_msg\n";
    }
};
$cron = Schedule::Cron->new(
    $dispatch_2,
    nofork => 1,
    nostatus => 1
);
$cron->add_entry('* * * * * 0-59');
eval {
    $cron->run();
};
$error = $@;
chomp $error;
($ok, $msg) = split '-', $error, 2;
ok $ok, $msg;
$0 = $orig_proc_name;

my $dispatch_3 = sub {
    my $test_msg = 'nostatus overrides processprefix';
    if ($0 eq $orig_proc_name) {
        die "1-$test_msg\n";
    }
    else {
        print "\$0 = $0\n";
        die "0-$test_msg\n";
    }
};
$cron = Schedule::Cron->new(
    $dispatch_3,
    nofork => 1,
    nostatus => 1,
    processprefix => 'foo'
);
$cron->add_entry('* * * * * 0-59');
eval {
    $cron->run();
};
$error = $@;
chomp $error;
($ok, $msg) = split '-', $error, 2;
ok $ok, $msg;
$0 = $orig_proc_name;

my $dispatch_4 = sub {
    my $test_msg = 'process name prefixed with string when using processprefix';
    my $rx = '^foo MainLoop - next: '.scalar(localtime).'$';
    if ($0 =~ /$rx/) {
        die "1-$test_msg\n";
    }
    else {
        die "0-test_msg\n";
    }
};
$cron = Schedule::Cron->new(
    $dispatch_4,
    nofork => 1,
    processprefix => 'foo'
);
$cron->add_entry('* * * * * 0-59');
eval {
    $cron->run();
};
$error = $@;
chomp $error;
($ok, $msg) = split '-', $error, 2;
ok $ok, $msg;
$0 = $orig_proc_name;

my $dispatch_5 = sub {
    my $test_msg = 'process name set to constant string when using processname';
    if ($0 eq 'foo') {
        die "1-$test_msg\n";
    }
    else {
        die "0-$test_msg\n";
    }
};
$cron = Schedule::Cron->new(
    $dispatch_5,
    nofork => 1,
    processname => 'foo'
);
$cron->add_entry('* * * * * 0-59');
eval {
    $cron->run();
};
$error = $@;
chomp $error;
($ok, $msg) = split '-', $error, 2;
ok $ok, $msg;
$0 = $orig_proc_name;

my $dispatch_6 = sub {
    my $test_msg = 'processname overrides nostatus and processprefix';
    if ($0 eq 'foo') {
        die "1-$test_msg\n";
    }
    else {
        die "0-$test_msg\n";
    }
};
$cron = Schedule::Cron->new(
    $dispatch_6,
    nofork => 1,
    processname => 'foo',
    nostatus => 1,
    processprefix => 'bar'
);
$cron->add_entry('* * * * * 0-59');
eval {
    $cron->run();
};
$error = $@;
chomp $error;
($ok, $msg) = split '-', $error, 2;
ok $ok, $msg;
$0 = $orig_proc_name;
