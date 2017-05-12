use lib './lib';
use lib './t/lib';

use Test::More qw/no_plan/;

use Peco::Container;

my $c = Peco::Container->new;
ok( $c, 'constructed a container' );
$c->register( 'key1', 'Test::Class', undef, 'new' );
my $obj1 = $c->service('key1');
ok( $obj1 );
$c->register( 'key2', 'Test::Class', [ ], 'new' );
my $obj2 = $c->service('key2');
ok( $obj2 );

ok( $obj1 == $c->service('key1') );
ok( $obj2 != $c->service('key1') );
