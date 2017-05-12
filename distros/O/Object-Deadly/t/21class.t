use Test::More tests => 3;
use Object::Deadly;
use Scalar::Util 'blessed';
use overload ();

my $obj = Object::Deadly->new;
ok( overload::Overloaded( $obj ), '$obj is overloaded' );

ok( ref( $obj )->can( 'can' ), 'Class ->can( can )');
ok( ref( $obj )->can( '()' ), 'Class ->can( () )' );
