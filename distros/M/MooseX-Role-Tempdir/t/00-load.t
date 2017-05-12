#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Role::Tempdir' ) || print "Bail out!\n";
}

diag( "Testing MooseX::Role::Tempdir $MooseX::Role::Tempdir::VERSION, Perl $], $^X" );
