use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'MojoX::AlmostJSON' ) || print "Bail out!\n";
}

diag( "Testing MojoX::AlmostJSON $MojoX::AlmostJSON::VERSION, Perl $], $^X" );

done_testing;