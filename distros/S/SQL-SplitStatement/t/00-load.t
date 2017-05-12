#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'SQL::SplitStatement' ) || print "Bail out!
";
}

diag(
    "Testing SQL::SplitStatement $SQL::SplitStatement::VERSION, Perl $], $^X"
);
