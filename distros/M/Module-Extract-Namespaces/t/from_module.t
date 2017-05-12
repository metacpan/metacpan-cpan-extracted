use strict;
use warnings;

use File::Spec;

use Test::More 'no_plan';

my $class  = 'Module::Extract::Namespaces';
my $method = 'from_module';

use_ok( $class );
can_ok( $class, $method );

my $rc = eval { $class->$method( $class, 'blib/lib' ) };
ok( defined $rc, "Eval returns defined value for method $method");
is( $rc, $class, "Scalar context returns $class" );

my @rc = sort $class->$method( $class, 'blib/lib' );
ok( @rc == 2, 'Eval returns list of two items' );
is( $rc[0], $class, "List context returns $class as the first item" );
is( $rc[1], 'PPI::Lexer', "List context returns PPI::Lexer as the second item" );
