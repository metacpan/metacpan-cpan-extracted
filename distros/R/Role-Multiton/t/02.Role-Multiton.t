use Test::More tests => 5;

package MyMoo;
use Moo;
has cow => ( is => 'rw' );
with 'Role::Multiton';

package main;

diag("Testing Role::Multiton $Role::Multiton::VERSION");

isnt( MyMoo->new(), MyMoo->new(), 'new() gives a new object each time' );

my $m1 = MyMoo->multiton( 'cow' => 42 );
is( $m1, MyMoo->multiton( 'cow' => 42 ), 'multiton() subsequently returns same object w/ same args (args no in hashref)' );
is( $m1, MyMoo->multiton( { 'cow' => 42 } ), 'multiton() subsequently returns same object w/ same args (args in hashref)' );

my $m2 = MyMoo->multiton();
is( $m2, MyMoo->instance(), 'instance() returns same object as multiton()' );

isnt( $m1, MyMoo->new( 'cow' => 42 ), 'new() still gives a new object even after there is a multiton in the class' );
