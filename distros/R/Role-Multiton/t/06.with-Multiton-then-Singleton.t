use Test::More tests => 3;

package MyMoo;
use Moo;
has cow => ( is => 'rw' );
with 'Role::Multiton';
with 'Role::Singleton';

package main;

my $n = MyMoo->new();
my $s = MyMoo->singleton();
my $m = MyMoo->multiton();
my $i = MyMoo->instance();

is( $i, $m, 'w/ both roles: instance() is multiton() when Role::Multiton is with()d first' );
isnt( $i, $s, 'w/ both roles: instance() when Role::Multiton is with()d first: instance() is not singleton()' );
isnt( $i, $n, 'w/ both roles: instance() when Role::Multiton is with()d first: instance() is not new()' );
