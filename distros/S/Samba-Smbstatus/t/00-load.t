#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Samba::Smbstatus' ) || print "Bail out!\n";
}

diag( "Testing Samba::Smbstatus $Samba::Smbstatus::VERSION, Perl $], $^X" );
