#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

sub has { }
sub extends { }
sub with { }
sub around { }
sub after { }
sub before { }

BEGIN {
    use_ok( 'MooX::LazierAttributes' ) || print "Bail out!\n";
}

diag( "Testing MooX::LazierAttributes $MooX::LazierAttributes::VERSION, Perl $], $^X" );
