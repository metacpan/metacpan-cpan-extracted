use lib './lib';
use lib './t/lib';

use Test::More qw/no_plan/;

use Peco::Container;

my $c = Peco::Container->new;
ok( $c, 'constructed a container' );

my $counter = 0;
my $coderef = sub { ++$counter };

$c->register( 'key1', $coderef );
ok( $c->service('key1') == 1 );
ok( $c->service('key1') == 2 );
ok( $c->service('key1') == 3 );
ok( $counter == 3 );

$c->register( 'const', 5 );
$c->register( 'key2', sub {
    my $cont = shift;
    $counter * $cont->service('const');
});

ok( $c->service('key2') == 15 );
