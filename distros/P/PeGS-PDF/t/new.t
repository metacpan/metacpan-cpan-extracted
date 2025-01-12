use Test::More 'no_plan';

my $class = 'PeGS::PDF';
my $method = 'new';

use_ok( $class );
can_ok( $class, $method );

my $pdf = $class->$method();
isa_ok( $pdf, $class );
