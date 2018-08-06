use strict;
use warnings;

use Test::More;

use Term::Caca;

my $driver = $ENV{CACA_DRIVER} || join '', grep { /^null$/ } Term::Caca->drivers;

plan skip_all => 'no driver available to run the tests' unless $driver;

my $t = Term::Caca->new( driver => $driver );

$t->circle( [ 10, 10 ], 5, 'x' );

$t->refresh;

for ( qw/ caca ansi text html html3 irc ps svg tga / ) {
    $t->export( $_ ); # in most cases return nothing because 'null' driver
    pass "export to $_";
}

done_testing;
