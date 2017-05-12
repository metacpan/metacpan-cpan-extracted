use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose::Role;
    sub role_method {}
}

{
    package BaseClass;
    use Moose;
    BEGIN { with 'MooseX::MethodAttributes::Role::AttrContainer::Inheritable' }
}

# FIXME - This now works with later Moose versions, but needs a
#         bisect and a version bump to work out when it started working!
TODO: {
    package Bar;
    use Test::More;
    BEGIN { $TODO = "Known broken" }
    use Moose;
    BEGIN { ::ok(!Bar->meta->has_method('role_method')) }
    BEGIN { ::ok(!Bar->can('role_method')) }
    BEGIN { extends 'BaseClass'; with 'Foo' }
    BEGIN { ::ok( Bar->meta->has_method('role_method')) }
    BEGIN { ::ok( Bar->can('role_method')) }
    use namespace::autoclean;
    BEGIN { ::ok( Bar->meta->has_method('role_method')) }
    BEGIN { ::ok( Bar->can('role_method')) }
    sub foo : Bar {}
    BEGIN { ::ok( Bar->meta->has_method('role_method')) }
    BEGIN { ::ok( Bar->can('role_method')) }
    ::ok( Bar->meta->has_method('role_method'));
    ::ok( Bar->can('role_method'));
}

done_testing;
