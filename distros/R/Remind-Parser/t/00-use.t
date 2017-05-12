use Test::More 'tests' => 2;

use_ok( 'Remind::Parser' );

my $obj = Remind::Parser->new;

isa_ok( $obj, 'Remind::Parser' );

