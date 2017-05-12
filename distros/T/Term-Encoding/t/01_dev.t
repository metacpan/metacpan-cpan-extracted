use strict;
use Test::More 'no_plan';

use Term::Encoding qw(term_encoding);

my $expect = $ENV{DEV_MIYAGAWA_UNIX}  ? 'euc-jp'
           : $ENV{DEV_MIYAGAWA_WIN32} ? 'cp932'
           :                             undef;

SKIP: {
    skip 'DEV_* is not set', 1 unless $expect;
    is term_encoding(), $expect;
}



