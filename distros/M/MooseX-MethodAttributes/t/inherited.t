use strict;
use warnings;
use Test::More tests => 9;

use lib 't/lib';

use Moose::Util qw/does_role/;

BEGIN { use_ok 'SubClass'; }
BEGIN { use_ok 'SubClassUseBaseAndUseMoose'; }

my $meta = SubClass->meta;
my $meta2 = SubClassUseBaseAndUseMoose->meta;

ok( does_role(
        BaseClass->meta->method_metaclass
        => 'MooseX::MethodAttributes::Role::Meta::Method'
    ) => 'BaseClass does method meta role'
);
ok( does_role(
        $meta->method_metaclass
        => 'MooseX::MethodAttributes::Role::Meta::Method'
    ) => 'SubClass does method meta role'
);
ok( does_role(
        $meta2->method_metaclass
        => 'MooseX::MethodAttributes::Role::Meta::Method'
    ) => 'SubClassUseBaseAndUseMoose does method meta role'
);

is_deeply(
    $meta2->get_method('bar')->attributes,
    ['Bar'],
);

is_deeply(
    $meta->get_method('bar')->attributes,
    ['Bar'],
);

is_deeply(
    $meta->find_method_by_name('foo')->attributes,
    ['Foo'],
);

is_deeply(
    [map { [$_->name => $_->attributes] } SubClass->meta->get_all_methods_with_attributes],
    [['affe', ['Birne']],
     ['foo', ['Foo']],
     ['moo', ['Moo']],
     ['bar', ['Bar']]],
);
