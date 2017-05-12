use strict;
use warnings;

use lib 't/lib';

use Moose::Util qw/does_role/;

use Test::More tests => 4;

use MooseX::MethodAttributes ();

use ClassUsingRoleWithAttributes;

my $meta = ClassUsingRoleWithAttributes->meta;
isa_ok($meta, 'Moose::Meta::Class');
my @methods = $meta->get_all_methods_with_attributes;
ok scalar(@methods), 'Have methods with attributes';

my $foo = $meta->get_method('foo');
ok $foo, 'Got foo method';
ok does_role($foo, 'MooseX::MethodAttributes::Role::Meta::Method'),
    'foo method meta instance does the attribute decorated method role';

