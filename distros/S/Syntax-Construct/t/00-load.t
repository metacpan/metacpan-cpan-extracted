#!/usr/bin/perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    require_ok('Syntax::Construct') or print "Bail out!\n";

}

diag("Testing Syntax::Construct $Syntax::Construct::VERSION, Perl $], $^X");
