use Test::More tests => 3;

package MyMoo;
use Moo;
has cow => ( is => 'rw' );
with 'Role::Singleton';
with 'Role::Multiton';

package main;

my $n = MyMoo->new();
my $s = MyMoo->singleton();
my $m = MyMoo->multiton();
my $i = MyMoo->instance();

is( $i, $s, 'w/ both roles: instance() is singleton() when Role::Singleton is with()d first' );
isnt( $i, $m, 'w/ both roles: instance() when Role::Singleton is with()d first: instance() is not multiton()' );
isnt( $i, $n, 'w/ both roles: instance() when Role::Singleton is with()d first: instance() is not new()' );
