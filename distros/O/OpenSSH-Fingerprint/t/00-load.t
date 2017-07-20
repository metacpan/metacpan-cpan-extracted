#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenSSH::Fingerprint' ) || print "Bail out!\n";
}

diag( "Testing OpenSSH::Fingerprint $OpenSSH::Fingerprint::VERSION, Perl $], $^X" );
