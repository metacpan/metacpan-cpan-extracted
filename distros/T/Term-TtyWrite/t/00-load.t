#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Term::TtyWrite') || print "Bail out!\n";
}

diag("Testing Term::TtyWrite $Term::TtyWrite::VERSION, Perl $], $^X");
