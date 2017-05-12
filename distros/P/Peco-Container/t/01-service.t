use lib './lib';
use lib './t/lib';

use Test::More qw/no_plan/;

use Peco::Container;

my $c = Peco::Container->new;
ok( $c, 'constructed a container' );
ok( $c->is_empty );
ok( $c->count == 0 );

$c->register( 'key1', 'Test::Class' );
my $obj1 = $c->service('key1');
ok( $obj1 );
is( ref($obj1), 'Test::Class' );
ok( not defined $obj1->{foo} );
ok( not defined $obj1->{bar} );
ok( not defined $obj1->{baz} );

$c->register( 'foo', 42 );
$c->register( 'bar', 69 );
$c->register( 'key2', 'Test::Class', [ 'foo', 'bar' ] );

ok( $c->service('foo') == 42 );
ok( $c->service('bar') == 69 );
my $obj2 = $c->service('key2');
ok( $obj2 );
ok( $obj2->{foo} == 42 );
ok( $obj2->{bar} == 69 );
