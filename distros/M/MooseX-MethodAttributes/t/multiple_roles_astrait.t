use strict;
use warnings;
use MooseX::MethodAttributes ();

use Test::More tests => 2;

# This tests the 'old' form of using MooseX::MethodAttributes with -traits => 'MethodAttributes'
# The new (and nicer) way is to just say use MooseX::MethodAttributes::Role

{
    package Bar;
    use Moose::Role -traits => 'MethodAttributes';
    use namespace::autoclean;

    sub item :Chained(/app/root) PathPrefix CaptureArgs(1) { }
}

{
    package Foo;
    use Moose::Role -traits => 'MethodAttributes';
    use namespace::autoclean;

    sub live :Chained(item) PathPart Args(0) { }
    sub foo :Attr { }
    sub other :Attr { }
}

{
    package Catalyst::Controller;
    use Moose;
    use namespace::autoclean;

    with 'MooseX::MethodAttributes::Role::AttrContainer::Inheritable';
}

use Moose::Util;
use Moose::Meta::Class;;

Moose::Meta::Class->create("MyClass",
    superclasses => [qw/Catalyst::Controller/],
    roles => ["Bar", "Foo"],
);


ok MyClass->meta->can('get_all_methods_with_attributes')
    or skip 'Role combination and method attributes known broken', 1;

my @methods;
for my $method (sort { $a->name cmp $b->name } MyClass->meta->get_all_methods_with_attributes) {
    push(@methods, $method->name . " :" . join("|", @{ $method->attributes }));
}

is_deeply \@methods, [
    'foo :Attr',
    'item :Chained(/app/root)|PathPrefix|CaptureArgs(1)',
    'live :Chained(item)|PathPart|Args(0)',
    'other :Attr',
], 'methods with expected attributes found';

