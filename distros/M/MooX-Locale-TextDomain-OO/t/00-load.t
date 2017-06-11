#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;
use Moo;

BEGIN
{
    use_ok('MooX::Locale::TextDomain::OO') || print "Bail out!\n";
}

diag("Testing MooX::Locale::TextDomain::OO $MooX::Locale::TextDomain::OO::VERSION, Perl $], $^X");

done_testing();
