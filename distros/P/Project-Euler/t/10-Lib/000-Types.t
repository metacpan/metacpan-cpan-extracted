#!perl -T
package test;

use Moose;

use Project::Euler::Lib::Types qw/ :all /;

has 'aProblemName' => (is => 'rw', isa => ProblemName);
has 'aProblemLink' => (is => 'rw', isa => ProblemLink);

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

my $ok_names  = [
    '0123456789',
    '01234567890123456789012345678901234567890123456789012345678901234567890123456789',
    'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    q{filler-_!@#$%^&*(){}[]<>,.\\/?;:'" },
];
my $nok_names = [
    '012345678',
    '012345678901234567890123456789012345678901234567890123456789012345678901234567890',
    'filler áéíóú',
    "0123456789\n",
    "0123456789\r",
    "0123456789\t",
    'filler filler «',
    '',
    undef,
];

my $posints = [qw/ 1  2  4  6  324  13212312 /];
my $negints = [map {$_ * -1} @$posints];

use constant  PROBLEM_BASE => 'http://projecteuler.net/index.php?section=problems&id=';
my $ok_links  = [PROBLEM_BASE.'1', PROBLEM_BASE.1, map {PROBLEM_BASE.$_} @$posints];
my $nok_links = [PROBLEM_BASE, PROBLEM_BASE.'1 ', ' '.PROBLEM_BASE.1, map {PROBLEM_BASE.$_} @$negints];

my $ok_dates  = ['05 October 2001', '2001-01-01', 'September 23, 1984 13:54'];
my $nok_dates = ['2001-13-01', 'September 34, 1984'];


my $tester = test->new();
my %tests = (
    aProblemName => {
        sub => sub{$tester->aProblemName(shift)},
        ok  => $ok_names,
        nok => $nok_names,
    },
    aProblemLink => {
        sub => sub{$tester->aProblemLink(shift)},
        ok  => $ok_links,
        nok => $nok_links,
    },
    aPosInt => {
        sub => sub{$tester->aPosInt(shift)},
        ok  => $posints,
        nok => [0, @$negints],
    },
    aNegInt => {
        sub => sub{$tester->aNegInt(shift)},
        ok  => $negints,
        nok => [0, @$posints],
    },
    aPosIntArray => {
        sub => sub{$tester->aPosIntArray(shift)},
        ok  => [$posints],
        nok => [[0, @$posints], $negints],
    },
    aNegIntArray => {
        sub => sub{$tester->aNegIntArray(shift)},
        ok  => [$negints],
        nok => [[0, @$negints], $posints],
    },
    aMyDateTime => {
        sub => sub{$tester->aMyDateTime(shift)},
        ok  => $ok_dates,
        nok => $nok_dates,
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


for  my $check  (keys %tests) {
    my $sub = $tests{$check}->{sub};
    my $ok  = $tests{$check}->{ok};
    my $nok = $tests{$check}->{nok};

    if (defined $ok) {
        for  my $val  (@$ok) {
            lives_ok {$sub->($val)} sprintf("Attribute %s shouldn't failed for value '%s'", $check, $val);
        }
        for  my $val  (@$nok) {
            dies_ok  {$sub->($val)} sprintf("Attribute %s should failed for value '%s'", $check, $val // '#UNDEFINED#');
        }
    }
}
