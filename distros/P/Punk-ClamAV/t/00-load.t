use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Punk::ClamAV')          || print "Bail out!\n";
    use_ok('Punk::Plugin::ClamAV')  || print "Bail out!\n";
}

diag("Testing Punk::ClamAV $Punk::ClamAV::VERSION, Perl $], $^X");
