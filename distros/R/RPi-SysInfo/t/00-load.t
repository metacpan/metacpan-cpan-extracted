use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::SysInfo' ) || print "Bail out!\n";
}

diag( "Testing RPi::SysInfo $RPi::SysInfo::VERSION, Perl $], $^X" );
