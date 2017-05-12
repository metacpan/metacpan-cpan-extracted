use strict;
use warnings;
{
    package Catalyst::Controller;
    use Moose;
    use namespace::autoclean;
    use MooseX::MethodAttributes;
    with 'MooseX::MethodAttributes::Role::AttrContainer::Inheritable';
}
{
    package TestApp::ControllerRole;
    use Moose::Role -traits => 'MethodAttributes';
    use namespace::autoclean;

    sub get_attribute : Local { $TestApp::Controller::Moose::GET_ATTRIBUTE_CALLED++ }

    sub get_foo : Local { $TestApp::Controller::Moose::GET_FOO_CALLED++ }

    # Exactly the same as last test except for modifier here
    before 'get_foo' => sub { $TestApp::Controller::Moose::BEFORE_GET_FOO_CALLED++ };
    sub other : Local {}
}
{
    package TestApp::Controller::Moose;
    use Moose;
    use namespace::autoclean;
    BEGIN { extends qw/Catalyst::Controller/; }

    our $GET_ATTRIBUTE_CALLED = 0;
    our $GET_FOO_CALLED = 0;
    our $BEFORE_GET_FOO_CALLED = 0;

    with 'TestApp::ControllerRole';
}
{
    package TestApp::Controller::Moose::MethodModifiers;
    use Moose;
    use namespace::autoclean;
    BEGIN { extends qw/TestApp::Controller::Moose/; }

    our $GET_ATTRIBUTE_CALLED = 0;
    after get_attribute => sub { $GET_ATTRIBUTE_CALLED++; }; # Wrapped only, should show up

    sub other : Local {}
    after other => sub {}; # Wrapped, wrapped should show up.
}

use Test::More tests => 21;
use Test::Fatal;

{
    my $method = TestApp::Controller::Moose->meta->get_method('get_foo');
    ok $method->meta->does_role('MooseX::MethodAttributes::Role::Meta::Method::MaybeWrapped'), 'Method metaclass for get_foo in ::Moose does role MaybeWrapped';

    $method = TestApp::Controller::Moose::MethodModifiers->meta->get_method('other');
    ok $method->meta->does_role('MooseX::MethodAttributes::Role::Meta::Method::MaybeWrapped'), 'Method metaclass for other in ::Moose::MethodModifiers does role MaybeWrapped'
}

{
    my @methods = TestApp::Controller::Moose->meta->get_all_methods_with_attributes;
    my @local_methods = TestApp::Controller::Moose->meta->get_method_with_attributes_list;
    is @methods, 3;
    is @local_methods, 3;
}


{
    my @methods = TestApp::Controller::Moose::MethodModifiers->meta->get_all_methods_with_attributes;
    my @local_methods = TestApp::Controller::Moose::MethodModifiers->meta->get_method_with_attributes_list;
    is @methods, 3;
    is @local_methods, 1;
}

my @methods;
is exception {
    @methods = TestApp::Controller::Moose::MethodModifiers->meta->get_nearest_methods_with_attributes;
}, undef, 'Can get nearest methods';

is @methods, 3;

my $method = (grep { $_->name eq 'get_attribute' } @methods)[0];
ok $method;
is $method->body, \&TestApp::Controller::Moose::MethodModifiers::get_attribute;
is $TestApp::Controller::Moose::GET_ATTRIBUTE_CALLED, 0;
is $TestApp::Controller::Moose::MethodModifiers::GET_ATTRIBUTE_CALLED, 0;
is $TestApp::Controller::Moose::GET_FOO_CALLED, 0;
is $TestApp::Controller::Moose::BEFORE_GET_FOO_CALLED, 0;

is
    exception { $method->body->() },
    undef,
    'can call $method->body sub';

is
    exception { (grep { $_->name eq 'get_foo' } @methods)[0]->body->(); },
    undef,
    'can find get_foo method';

is $TestApp::Controller::Moose::GET_ATTRIBUTE_CALLED, 1;
is $TestApp::Controller::Moose::MethodModifiers::GET_ATTRIBUTE_CALLED, 1;
is $TestApp::Controller::Moose::GET_FOO_CALLED, 1;
is $TestApp::Controller::Moose::BEFORE_GET_FOO_CALLED, 1;

my $other = (grep { $_->name eq 'other' } @methods)[0];
ok $other;

