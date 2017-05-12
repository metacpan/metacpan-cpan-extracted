use strict;
use warnings;

use Test::More tests => 5;
use Scalar::Util qw/ refaddr /;

use lib 't/lib';

use Foo;

my $foo = Foo->new( thingy => 'toaster', this => 'stuff' );

is $foo->thingy => 'toaster', '$foo->thingy';

is $foo->bar->thingy => 'toaster', 'thingy() via bar';

is $foo->this => 'stuff', 'this()';
is $foo->bar->that => 'stuff', 'that()';

is refaddr( $foo->bar->parent ) => refaddr( $foo ), 'parent';
