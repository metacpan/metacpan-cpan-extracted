#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use version; our $VERSION = qv('v0.0.5');

plan tests => 1;

BEGIN {
    use_ok('Test::Approvals') || print "Bail out!\n";
}

diag("Testing Test::Approvals $Test::Approvals::VERSION, Perl $], $^X");
