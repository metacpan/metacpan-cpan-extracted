#!perl -w
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('PerlIO::fgets');
}

diag("PerlIO::fgets $PerlIO::fgets::VERSION, Perl $], $^X");

