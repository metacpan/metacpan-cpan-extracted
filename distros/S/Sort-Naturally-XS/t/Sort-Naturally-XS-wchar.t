#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Sort::Naturally::XS qw/nsort ncmp sorted/;
use List::Util qw/first/;
use utf8;
use Config;

my $ar_mixed_utf8 = [qw/Як-100 Ка-8 Ми-20 Ка-10 Ка-26 Ка-15 Ка-25 Ми-4 Ми-6 Ми-8 Ка-31 Ми-14 Ми-24 Ка-18 Ка-22 Ми-26
    Ми-30 Ми-171 Як-24 Як-60 Ка-27 Ка-29 Ка-32 Ка-126 Ми-10 Ми-1/];
my $ar_mixed_utf8__expected = [qw/Ка-8 Ка-10 Ка-15 Ка-18 Ка-22 Ка-25 Ка-26 Ка-27 Ка-29 Ка-31 Ка-32 Ка-126 Ми-1 Ми-4 Ми-6
    Ми-8 Ми-10 Ми-14 Ми-20 Ми-24 Ми-26 Ми-30 Ми-171 Як-24 Як-60 Як-100/];
ok(eq_array($ar_mixed_utf8__expected, [nsort(@{$ar_mixed_utf8})]), "Wide characters in input of 'nsort'");

ok(eq_array($ar_mixed_utf8__expected, [sort {ncmp($a, $b)} @{$ar_mixed_utf8}]), "Wide characters in input of 'ncmp'");

ok(eq_array($ar_mixed_utf8__expected, sorted($ar_mixed_utf8)), "Wide characters in input of 'sorted'");

# issue-2 example
{
    no utf8;

    my @issue_2_list = ( qq(\x{2603}), q(abc) );
    my @issue_2_list__expected = ( q(abc), qq(\x{2603}) );
    my @issue_2_list__actual = nsort(@issue_2_list);

    ok(eq_array(\@issue_2_list__expected, \@issue_2_list__actual), "Wide character (not letter) in input of 'nsort'");

    @issue_2_list__actual = sort {ncmp($a, $b)} @issue_2_list;
    ok(eq_array(\@issue_2_list__expected, \@issue_2_list__actual), "Wide character (not letter) in input of 'ncmp'");

    ok(eq_array(\@issue_2_list__expected, sorted(\@issue_2_list)), "Wide character (not letter) in input of 'sorted'");
}

done_testing();
