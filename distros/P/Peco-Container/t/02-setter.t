use lib './lib';
use lib './t/lib';

use Test::More qw/no_plan/;

use Peco::Container;

my $c = Peco::Container->new;
ok( $c );

$c->register( 'foo', 42 );
$c->register( 'key1', 'Test::Class', [ 'foo' ], undef, { bar => 'baz' } );

my $obj1 = $c->service('key1');
ok( $obj1 );
ok( $obj1->{foo} == 42 );
ok( $obj1->{bar} eq 'baz' );
