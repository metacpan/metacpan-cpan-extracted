#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;
use Devel::Size 'total_size';
use Benchmark ':all', ':hireswallclock';
use Devel::Size 'total_size';

my $tap;
{
        local $/;
        open (TAP, "< xt/regexp-common.tap") or die "Cannot read xt/regexp-common.tap";
        $tap = <TAP>;
        close TAP;
}

foreach my $usebitsets (0..1) {
        my $tapdata;

        my $count = 1;
        my $t = timeit ($count, sub { $tapdata = TAP::DOM->new( tap => $tap, usebitsets => $usebitsets ) });
        my $n = $t->[5];
        my $throughput = $n / $t->[0];

        #diag Dumper($tapdata);
        is($tapdata->{tests_run},      41499,     "tests_run -- usebitsets = $usebitsets");
        is($tapdata->{tests_planned},  41499,     "tests_planned -- usebitsets = $usebitsets");
        is($tapdata->{version},        12,        "version -- usebitsets = $usebitsets");
        is($tapdata->{plan},          "1..41499", "plan -- usebitsets = $usebitsets");

        is($tapdata->{lines}[41483]{number},  41483,     "[2] number -- usebitsets = $usebitsets");
        ok($tapdata->{lines}[41483]->is_test,     "[2] is_test -- usebitsets = $usebitsets");
        ok($tapdata->{lines}[41483]->is_ok,     "[2] is_ok -- usebitsets = $usebitsets");
        is($tapdata->{lines}[41483]{description},  '- "-----Another /* comment\n"              ([SB/F/NM] ZZT-OOP)', "[41483] description -- usebitsets = $usebitsets");
        is($tapdata->{lines}[41483]{raw}, 'ok 41483 - "-----Another /* comment\n"              ([SB/F/NM] ZZT-OOP)', "[41483] raw -- usebitsets = $usebitsets");

        ok(1, "benchmark -- usebitsets = $usebitsets");
        print "  ---\n";
        print "  benchmark:\n";
        print "    timestr:    ".timestr($t), "\n";
        print "    wallclock:  $t->[0]\n";
        print "    usr:        $t->[1]\n";
        print "    sys:        $t->[2]\n";
        print "    throughput: $throughput\n";
        print "  total_size:   ".total_size ($tapdata)."\n";
        print "  ...\n";
}
done_testing;
