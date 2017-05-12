use strict;
use warnings;

use lib 't/lib';

use Moose::Util qw/find_meta does_role/;

use Test::More tests => 4;

use MooseX::MethodAttributes ();

use RoleWithAttributes;

my $meta = find_meta('RoleWithAttributes');
isa_ok($meta, 'Moose::Meta::Role');
ok does_role($meta, 'MooseX::MethodAttributes::Role::Meta::Role'),
    'Role metaclass does the role for metaclasses with attribute decorated methods';

my $foo = $meta->get_method('foo');
ok $foo, 'Got foo method';
ok does_role($foo, 'MooseX::MethodAttributes::Role::Meta::Method'),
    'foo method meta instance does the attribute decorated method role';

