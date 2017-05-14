#!perl -T
package test;

use Moose;

use Project::Euler::Lib::Types qw/ :all /;

has 'aPosInt'      => (is => 'rw', isa => PosInt);
has 'aNegInt'      => (is => 'rw', isa => NegInt);

has 'aPosIntArray' => (is => 'rw', isa => PosIntArray);
has 'aNegIntArray' => (is => 'rw', isa => NegIntArray);

has 'aMyDateTime'  => (is => 'rw', isa => MyDateTime, coerce=>1);

no Moose;



package main;

use strict;
use warnings;
use autodie;
use Test::More;
use Test::Exception;

my @posints = qw/ 1  2  4  6  324  13212312 /;
my @negints = map {$_ * -1} @posints;


my $tester = test->new();
my %tests = (
    aPosInt => {
        sub => sub{$tester->aPosInt(shift)},
        ok  => \@posints,
        nok => [0, @negints],
    },
    aNegInt => {
        sub => sub{$tester->aNegInt(shift)},
        ok  => \@negints,
        nok => [0, @posints],
    },
    aPosIntArray => {
        sub => sub{$tester->aPosIntArray(shift)},
        ok  => [[@posints]],
        nok => [[0, @posints], [@negints]],
    },
    aNegIntArray => {
        sub => sub{$tester->aNegIntArray(shift)},
        ok  => [[@negints]],
        nok => [[0, @negints], [@posints]],
    },
    aMyDateTime => {
        sub => sub{$tester->aMyDateTime(shift)},
        ok  => ['05 October 2001', '2001-01-01', 'September 23, 1984 13:54'],
        nok => ['2001-13-01', 'September 34, 1984'],
    }
);


my $sum;
for  my $check  (keys %tests) {
    my $ok  = $tests{$check}->{ok};
    my $nok = $tests{$check}->{nok};

    for  my $test  (grep {defined $_} ($ok, $nok)) {
        $sum += scalar @$test;
    }
}
plan tests => $sum;
diag('Moose types checks');


for  my $check  (keys %tests) {
    my $sub = $tests{$check}->{sub};
    my $ok  = $tests{$check}->{ok};
    my $nok = $tests{$check}->{nok};

    if (defined $ok) {
        for  my $val  (@$ok) {
            ok($sub->($val), sprintf('Attribute %s failed for value %s', $check, $val));
        }
        for  my $val  (@$nok) {
            dies_ok {$sub->($val)} sprintf('Attribute %s failed for value %s', $check, $val);
        }
    }
}
