use Test::Most tests => 4;

use lib "t/lib";

use RoleLess;
use Role::Tiny::MonkeyPatch qw/RoleLess/;

use Mojo::Util qw/dumper/;

$\ = "\n";
$, = "\t";

my $img = RoleLess->new()->with_roles("+Something");

ok($img->can("with_roles"), "can with roles");

ok($img->can("foo"), "can from role");

ok( $img->foo(12), "set from role");

is( $img->foo, 12, "get from role" );
