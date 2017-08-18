#!perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Foo::Bar;

my $foo = Foo::Bar->new;
ok( $foo->isa( 'Foo::Bar' ), '... the object is from class Foo' );
ok( $foo->isa( 'Moxie::Object' ), '... the object is derived from class Object' );
ok( $foo->isa( 'UNIVERSAL::Object' ), '... the object is derived from base Object' );

done_testing;
