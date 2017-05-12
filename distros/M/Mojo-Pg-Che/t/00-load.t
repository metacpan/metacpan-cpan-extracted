#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

#~ plan tests => 0;

BEGIN {
    use_ok( 'Mojo::Pg::Che' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Pg::Che $Mojo::Pg::Che::VERSION, Perl $], $^X" );
done_testing();