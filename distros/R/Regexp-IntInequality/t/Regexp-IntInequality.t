#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Regexp::IntInequality>.

=head1 Author, Copyright, and License

Copyright (c) 2024 Hauke Daempfling (haukex@zero-g.net).

This file is part of the "Regular Expression Integer Inequalities" library.

This library is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License
along with this program. If not, see L<https://www.gnu.org/licenses/>

=cut

use Test::More tests => 9;
use FindBin ();
use File::Spec::Functions qw/ catfile /;
use JSON::PP;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)

diag "This is Perl $] at $^X on $^O";
BEGIN { use_ok 'Regexp::IntInequality', 're_int_ineq' }
is $Regexp::IntInequality::VERSION, '0.90', 'version matches tests';

my $TESTCASES_FILE = catfile($FindBin::Bin,'testcases.json');
open my $fh, '<:raw:encoding(UTF-8)', $TESTCASES_FILE
    or die "$TESTCASES_FILE: $!";  ## no critic (RequireCarping)
my $TESTCASES = JSON::PP->new->utf8->decode(do { local $/=undef; <$fh> });
close $fh;

subtest 'manual tests' => sub {
    my @TESTS = grep {ref} @{ $TESTCASES->{manual_tests} };
    plan tests => 0+@TESTS;
    for my $t (@TESTS)
        { is re_int_ineq(@$t[0..3]), $$t[4], "$$t[0] $$t[1] "
            .($$t[2]?'Z':'N').($$t[3]?'':' no anchor')." => $$t[4]" }
} or BAIL_OUT("manual tests failed");

subtest 'extraction' => sub {
    my @TESTS = grep {ref} @{ $TESTCASES->{extraction} };
    plan tests => 0+@TESTS;
    for my $t (@TESTS) {
        my $re = re_int_ineq(@$t[0..3]);
        my @got = $$t[4]=~/$re/g;
        is_deeply \@got, [ @$t[5..$#$t] ], "extraction with $re"
            or diag explain [$t, $re, \@got];
    }
} or BAIL_OUT("extraction tests failed");

subtest 'zeroes' => sub {
    my @NEVERMATCH = map {("0$_","00$_","-0$_","-00$_")}
        @{ $TESTCASES->{zeroes_nevermatch} };
    my @TESTS = @{ $TESTCASES->{zeroes} };
    plan tests => (2+@NEVERMATCH)*@TESTS
                + (2+@NEVERMATCH)*@TESTS/2;  # assumes array is symmetric
    for my $t (@TESTS) {
        my ($op,$n,$mz) = @$t;
        if ( $n!~/^-/ ) {
            my $rn = re_int_ineq($op, $n);
            if ($mz) {  like '0', qr/\A$rn\z/, "N $op$n: $rn should match 0" }
            else { unlike '0', qr/\A$rn\z/, "N $op$n: $rn shouldn't match 0" }
            unlike '-0', qr/\A$rn\z/, "N $op$n: $rn shouldn't match -0";
            unlike   $_, qr/\A$rn\z/, "N $op$n: $rn shouldn't match $_"
                for @NEVERMATCH;
        }
        my $rz = re_int_ineq($op, $n, 1);
        if ($mz) {
            like  '0', qr/\A$rz\z/, "Z $op$n: $rz should match 0";
            like '-0', qr/\A$rz\z/, "Z $op$n: $rz should match -0";
        } else {
            unlike  '0', qr/\A$rz\z/, "Z $op$n: $rz shouldn't match 0";
            unlike '-0', qr/\A$rz\z/, "Z $op$n: $rz shouldn't match -0";
        }
        unlike $_, qr/\A$rz\z/, "N $op$n: $rz shouldn't match $_"
            for @NEVERMATCH;
    }
} or BAIL_OUT("zeroes tests failed");

subtest 'error cases' => sub {
    my @TESTS = grep {ref} @{ $TESTCASES->{errorcases} };
    plan tests => 0+@TESTS;
    for my $t (@TESTS)
        { ok exception { re_int_ineq(@$t) }, "error on args (@$t)" }
};

diag "The final two test cases can take a few seconds...";

subtest 'non-negative integers (N)' => sub {
    my @TESTS = map {( $$_[0] .. ($$_[1]-1) )}
        @{ $TESTCASES->{nonneg_testranges} };
    plan tests => 1 + 6*@TESTS**2;
    is run_rangetests(0, @TESTS), 0, 'seen_negzero as expected';
};

subtest 'all integers (Z)' => sub {
    my @TESTS = map {($_,"-$_")} map {( $$_[0] .. ($$_[1]-1) )}
        @{ $TESTCASES->{allint_testranges} };
    plan tests => 1 + 6*@TESTS**2;
    is run_rangetests(1, @TESTS), 1+@TESTS, 'seen_negzero as expected';
};

sub run_rangetests {
    my ($ai, @testcases) = @_;
    my $nz = $ai ? 'Z' : 'N';
    # double-check that Perl's string/number conversion didn't clobber "-0":
    my $seen_negzero = 0;
    for my $n (@testcases) {
        my ($lt, $le, $gt, $ge, $ne, $eq) =
            map {re_int_ineq($_,$n,$ai)} '<','<=','>','>=','!=','==';
        my ($rlt, $rle, $rgt, $rge, $rne, $req) =
            map {qr/\A$_\z/} $lt, $le, $gt, $ge, $ne, $eq;
        note "$nz n=$n lt=$lt le=$le gt=$gt ge=$ge";
        for my $i (@testcases) {
            if ( $i< $n ) { like $i, $rlt, "$nz $i is    <  $n and =~ $lt" }
            else        { unlike $i, $rlt, "$nz $i isn't <  $n and !~ $lt" }
            if ( $i<=$n ) { like $i, $rle, "$nz $i is    <= $n and =~ $le" }
            else        { unlike $i, $rle, "$nz $i isn't <= $n and !~ $le" }
            if ( $i> $n ) { like $i, $rgt, "$nz $i is    >  $n and =~ $gt" }
            else        { unlike $i, $rgt, "$nz $i isn't >  $n and !~ $gt" }
            if ( $i>=$n ) { like $i, $rge, "$nz $i is    >= $n and =~ $ge" }
            else        { unlike $i, $rge, "$nz $i isn't >= $n and !~ $ge" }
            if ( $i!=$n ) { like $i, $rne, "$nz $i is    != $n and =~ $ne" }
            else        { unlike $i, $rne, "$nz $i isn't != $n and !~ $ne" }
            if ( $i==$n ) { like $i, $req, "$nz $i is    == $n and =~ $eq" }
            else        { unlike $i, $req, "$nz $i isn't == $n and !~ $eq" }
            $seen_negzero++ if $i=~/\A-0\z/;
        }
        $seen_negzero++ if $n=~/\A-0\z/;
    }
    return $seen_negzero;
}

# This is a special test case needed for the Perl implementation.
subtest 'anchor argument' => sub { plan tests=>5;
    is re_int_ineq('<=', 0),       '(?<![0-9])0(?![0-9])', 'anchor implicit on 1';
    is re_int_ineq('<=', 0, 0),    '(?<![0-9])0(?![0-9])', 'anchor implicit on 2';
    is re_int_ineq('<=', 0, 0, 1), '(?<![0-9])0(?![0-9])', 'anchor explicit on';
    is re_int_ineq('<=', 0, 0, 0), '0',                    'anchor explicit off 1';
    is re_int_ineq('<=', 0, 0, undef), '0',                'anchor explicit off 2';
};

done_testing;
