# Test what happens when a callback-enabled role is applied to a class

use strict;
use warnings;

use Test::More;
use Moose::Util;

use FindBin qw( $Bin );
use lib "$Bin/lib";
use TestRole;

my $callback_args;
TestRole::included(sub {
    $callback_args = \@_;
    return;
});

subtest 'class' => sub {
    undef $callback_args;

    my $class = Moose::Meta::Class->create_anon_class(
        roles => ['TestRole']
    );

    ok($callback_args, 'callback should be called when the role is included');
    is($callback_args->[0], TestRole->meta, 'first arg to the callback should be $meta');
    is($callback_args->[1], $class, 'second arg to the callback should be $class->meta');

    my $obj = $class->new_object();
    ok($obj->from_the_role, 'roles should still be applied normally');
};

subtest 'class instance' => sub {
    undef $callback_args;

    my $bare_meta = Moose::Meta::Class->create_anon_class();
    my $bare_obj = $bare_meta->new_object();
    ok(!$bare_obj->can('from_the_role')); #sanity check

    Moose::Util::apply_all_roles($bare_obj, 'TestRole');

    ok($callback_args, 'callback should be called when the role is included');
    is($callback_args->[0], TestRole->meta, 'first arg to the callback should be $meta');
    is($callback_args->[1], $bare_obj->meta, 'second arg to the callback should be $class->meta');
};

done_testing();
