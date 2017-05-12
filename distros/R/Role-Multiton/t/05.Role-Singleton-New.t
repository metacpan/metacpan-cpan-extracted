use Test::More tests => 9;
use Test::Exception;

package MyMoo;
use Moo;
has cow => ( is => 'rw' );
with 'Role::Singleton::New';

package main;

diag("Testing Role::Singleton::New $Role::Singleton::New::VERSION");

my $o = MyMoo->new();
my $n = MyMoo->new();
isnt( $o, $n, 'initially new() gives a different object each time' );

is( $o->turn_new_into_singleton(), $o, 'turn_new_into_singleton() returns object' );

is( MyMoo->new(), MyMoo->new(), 'new() gives a the same object each time' );

my $s = MyMoo->new( 'cow' => 42 );

is( $s, MyMoo->new(), 'new() subsequently returns same object (regardless of args)' );

is( $s, MyMoo->new(), 'new() still gives a new object even after there is a singleton in the class' );

throws_ok { MyMoo->turn_new_into_singleton } qr/turn_new_into_singleton\(\) must be called by an object/, 'turn_new_into_singleton() as non object caught OK';
Role::Tiny->apply_roles_to_package( 'MyMoo', 'Role::Multiton::New' );
throws_ok { $o->turn_new_into_multiton } qr/turn_new_into_multiton\(\) can not be called after turn_new_into_singleton\(\)/, 'turn_new_into_singleton() then turn_new_into_multiton() caught OK';

is( $n->turn_new_into_singleton(), $n,           'turn_new_into_singleton() on a different object/same class returns the new object' );
is( $n,                            MyMoo->new(), 'new() subsequently returns the new object' );
