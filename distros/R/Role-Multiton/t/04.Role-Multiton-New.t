use Test::More tests => 12;
use Test::Exception;

package MyMoo;
use Moo;
has cow => ( is => 'rw' );
with 'Role::Multiton::New';

package main;

diag("Testing Role::Multiton::New $Role::Multiton::New::VERSION");

my $_x = MyMoo->new();
my $n  = MyMoo->new();
isnt( $_x, $n, 'initially new() gives a different object each time' );

my $_m = MyMoo->new( 'cow' => 78 );
is( $_m->turn_new_into_multiton( 'cow' => 78 ), $_m, 'turn_new_into_singleton() returns object' );
is( $_m, MyMoo->new( 'cow' => 78 ), 'turn_new_into_multiton() next new w/ same args returns same object' );

my $no = MyMoo->new();
is( $no, MyMoo->new(), 'new() w/ no args returns same object' );

my $m1 = MyMoo->new( 'cow' => 42 );
is( $m1, MyMoo->new( 'cow' => 42 ), 'new() w/ same args returns same object (args no in hashref)' );
is( $m1, MyMoo->new( { 'cow' => 42 } ), 'new() w/ same args returns same object (args in hashref)' );

isnt( $m1, $no, 'new() w/ different args give different object' );

throws_ok { MyMoo->turn_new_into_multiton } qr/turn_new_into_multiton\(\) must be called by an object/, 'turn_new_into_multiton() as non object caught OK';
Role::Tiny->apply_roles_to_package( 'MyMoo', 'Role::Singleton::New' );
throws_ok { $_x->turn_new_into_singleton } qr/turn_new_into_singleton\(\) can not be called after turn_new_into_multiton\(\)/, 'turn_new_into_multiton() then turn_new_into_singleton() caught OK';

is( $n->turn_new_into_multiton(), $n,           'turn_new_into_multiton() on a different object/same class returns the new object' );
is( $n,                           MyMoo->new(), 'new() subsequently returns the new object' );
isnt( $n, $no, 'sanity: new object is not the previous one' );
