use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'MojoX::Log::Rotate' ) || print "Bail out!\n";
}

diag( "Testing MojoX::Log::Rotate $MojoX::Log::Rotate::VERSION, Perl $], $^X" );

done_testing;