#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;
use Moo;

BEGIN
{
    use_ok('MooX::Locale::Passthrough') || print "Bail out!\n";
}

diag("Testing MooX::Locale::Passthrough $MooX::Locale::Passthrough::VERSION, Perl $], $^X");

done_testing();
