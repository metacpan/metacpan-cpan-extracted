use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 4;

use MooseX::MethodAttributes ();

# Note - these test classes say use MooseX::MethodAttributes::Role, which is the new 'nicer'
#        way of doing things.

use UsesMultipleRoles;

my $meta = UsesMultipleRoles->meta;

my $foo = $meta->get_method('foo');
ok $foo, 'Got foo method';

my $bar = $meta->get_method('bar');
ok $bar, 'Got bar method';

my $foo_attrs = $meta->get_method_attributes($foo->body);
ok @$foo_attrs, 'foo method has some attributes';

my $bar_attrs = $meta->get_method_attributes($bar->body);
ok @$bar_attrs, 'bar method has some attributes';

