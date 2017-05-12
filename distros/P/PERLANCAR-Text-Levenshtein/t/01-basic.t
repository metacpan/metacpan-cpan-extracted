#!perl

use PERLANCAR::Text::Levenshtein;

use Test::More;

# just some sanity checks
is(PERLANCAR::Text::Levenshtein::editdist("foo","foo"),0);
is(PERLANCAR::Text::Levenshtein::editdist("foo","food"),1);
is(PERLANCAR::Text::Levenshtein::editdist("foo","bar"),3);

done_testing;
