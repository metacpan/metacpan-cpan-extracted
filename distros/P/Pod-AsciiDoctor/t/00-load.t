#!perl -T
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN
{
    # TEST
    use_ok('Pod::AsciiDoctor') || print "Bail out!\n";
}

diag("Testing Pod::AsciiDoctor $Pod::AsciiDoctor::VERSION, Perl $], $^X");
