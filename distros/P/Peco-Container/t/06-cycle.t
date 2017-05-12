use lib './lib';
use lib './t/lib';

use Test::More qw/no_plan/;

use Peco::Container;

my $c = Peco::Container->new;
ok( $c, 'constructed a container' );
ok( $c->is_empty );
ok( $c->count == 0 );

$c->register( 'key1', 'Test::Class', [ 'key0' ] );
$c->register( 'key2', 'Test::Class', [ 'key1' ] );
$c->register( 'key0', 'Test::Class', [ 'key2' ] );

eval { $c->service('key1') };
ok( $@ and $@ =~ /cyclic dependency detected/ );
