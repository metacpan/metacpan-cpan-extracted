use lib './lib';
use lib './t/lib';

use Test::More qw/no_plan/;

use Test::MySpec;
use Peco::Container;

my $c = Peco::Container->new;
ok( $c, 'constructed a container' );

$c->register( 'foo', 42 );
ok( $c->service('foo') == 42 );

$c->register( 'key1', 'Test::MySpec', [ 'foo' ] );
my $obj1 = $c->service('key1');
ok($obj1);
ok($obj1->isa('Peco::Spec'));
ok(ref($obj1) eq 'Test::MySpec');
ok($obj1->{foo} == $c->service('foo'));
