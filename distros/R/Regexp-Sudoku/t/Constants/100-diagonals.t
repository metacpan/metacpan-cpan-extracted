#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../../lib];
use experimental 'signatures';

use Test::More 0.88;

my $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku::Constants qw [:Diagonals];

my %aliases = qw [
    MAIN          SUPER0
    MINOR         MINOR_SUPER0
    SUB0          SUPER0
    MINOR_SUB0    MINOR_SUPER0
    SUPER         SUPER1
    SUB           SUB1
    MINOR_SUPER   MINOR_SUPER1
    MINOR_SUB     MINOR_SUB1
    CROSS         CROSS0
    DOUBLE        CROSS1
    SUB0          SUPER0
    MINOR_SUB0    MINOR_SUPER0
];

my %sets = (
    TRIPLE    => [qw [CROSS CROSS1]],
    ARGYLE    => [qw [CROSS1 CROSS4]],
    CROSS0    => [qw [SUB0 MINOR_SUB0]],
);
foreach my $i (1 .. 34) {
    $sets {"CROSS$i"} = ["SUB$i", "SUPER$i", "MINOR_SUB$i", "MINOR_SUPER$i"];
}

my      @base   =  map {("SUB$_", "SUPER$_")} 0 .. 34;
push    @base   => map {"MINOR_$_"} @base;

        @base   =  grep {!$aliases {$_}} @base;

my      @tokens =  @base;
#
# Aliases
#
push    @tokens => keys %aliases;
#
# Sets
#
push    @tokens => keys %sets;

foreach my $token (@tokens, "ALL_DIAGONALS") {
    no strict 'refs';
    ok defined $$token, "\$$token set";
}


for (my $i = 0; $i < @base; $i ++) {
    for (my $j = $i + 1; $j < @base; $j ++) {
        no strict 'refs';
        ok +(${$tokens [$i]} &. ${$tokens [$j]}) =~ /^\0*$/,
             sprintf '$%s and $%s share no bits', $tokens [$i], $tokens [$j];
    }
}


foreach my $token (@tokens) {
    no strict 'refs';
    is $$token, $$token &. $::ALL_DIAGONALS,
     "\$$token is contained in \$ALL_DIAGONALS";
}



print <<"--";
#
# Checking aliases
#
--

foreach my $alias (sort keys %aliases) {
    my $source = $aliases {$alias};
    no strict 'refs';
    is $$alias, $$source, "\$$alias is an alias for \$$source";
}


print <<"--";
#
# Checking sets
#
--

foreach my $name (sort keys %sets) {
    my $elements = $sets {$name};
    my $test_name = "\$$name combines " . join ", " => map {"\$$_"} @$elements;
       $test_name =~ s/.*\K, / and /;
    no strict 'refs';
    my $result = ${shift @$elements};
    while (@$elements) {
        $result |.= ${shift @$elements};
    }
    is $$name, $result, $test_name;
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
