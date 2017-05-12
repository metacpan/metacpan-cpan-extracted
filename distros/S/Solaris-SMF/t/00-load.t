#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Solaris::SMF');
}

diag("Testing Solaris::SMF $Solaris::SMF::VERSION, Perl $], $^X");

