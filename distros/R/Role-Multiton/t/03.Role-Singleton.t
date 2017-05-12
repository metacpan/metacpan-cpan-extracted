use Test::More tests => 4;

package MyMoo;
use Moo;
has cow => ( is => 'rw' );
with 'Role::Singleton';

package main;

diag("Testing Role::Singleton $Role::Singleton::VERSION");

isnt( MyMoo->new(), MyMoo->new(), 'new() gives a new object each time' );

my $s = MyMoo->singleton( 'cow' => 42 );

is( $s, MyMoo->singleton(), 'singleton() subsequently returns same object (regardless of args)' );

is( $s, MyMoo->instance(), 'instance() returns same object as singleton()' );

isnt( $s, MyMoo->new(), 'new() still gives a new object even after there is a singleton in the class' );
