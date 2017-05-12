use strict;
use warnings;
use MooseX::MethodAttributes ();

{
    package FirstRole;
    use Moose::Role -traits => 'MethodAttributes';
    use namespace::autoclean;

    our $FOO_CALLED = 0;
    sub foo : Local { $FOO_CALLED++; }

    our $BAR_CALLED = 0;
    sub bar : Local { $BAR_CALLED++; }

    our $BEFORE_BAR_CALLED = 0;
    before 'bar' => sub { $BEFORE_BAR_CALLED++; };

    our $BAZ_CALLED = 0;
    sub baz : Local { $BAZ_CALLED++; }

    our $QUUX_CALLED = 0;
    sub quux : Local { $QUUX_CALLED++; }
}
{
    package SecondRole;
    use Moose::Role;
    use namespace::autoclean;
    with 'FirstRole';
    our $BEFORE_BAZ_CALLED = 0;
    before 'baz' => sub { $BEFORE_BAZ_CALLED++ };
}
{
    package MyClass;
    use Moose;
    use namespace::autoclean;

    with 'SecondRole';
    our $BEFORE_QUUX_CALLED = 0;
    before 'quux' => sub { $BEFORE_QUUX_CALLED++; };
}

use Test::More tests => 25;
use Test::Fatal;

my @method_names = qw/foo bar baz quux/;

foreach my $class (qw/FirstRole SecondRole MyClass/) {
    foreach my $method_name (@method_names) {
        my $method = $class->meta->get_method($method_name);
        ok(
            (
                $method->meta->does_role('MooseX::MethodAttributes::Role::Meta::Method')
                or $method->meta->does_role('MooseX::MethodAttributes::Role::Meta::Method::MaybeWrapped')
            ),
            sprintf(
                'Method metaclass for %s in %s does role'
                => $method_name, $class
            )
        );
    }
}

foreach my $method_name (@method_names) {
    is exception {
        MyClass->$method_name();
    }, undef, "Call $method_name method";
}

is $FirstRole::FOO_CALLED, 1, '->foo called once';
is $FirstRole::BAR_CALLED, 1, '->bar called once';
is $FirstRole::BAZ_CALLED, 1, '->baz called once';
is $FirstRole::QUUX_CALLED, 1, '->quux called once';

is $FirstRole::BEFORE_BAR_CALLED, 1, 'modifier for ->bar called once';
is $SecondRole::BEFORE_BAZ_CALLED, 1, 'modifier for ->baz called once';
is $MyClass::BEFORE_QUUX_CALLED, 1, 'modifier for ->quux called once';

{
    my @methods = MyClass->meta->get_all_methods_with_attributes;
    my @local_methods = MyClass->meta->get_method_with_attributes_list;
    is @methods, 4;
    is @local_methods, 4;
}

