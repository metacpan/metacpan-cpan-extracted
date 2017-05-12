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
    package ControllerRole;
    use Moose::Role -traits => 'MethodAttributes';
    use namespace::autoclean;

    sub not_attributed : Local {} # This method should _not_ get composed.
}
{
    package roles::Controller::Foo;
    use Moose;
    BEGIN { extends 'Catalyst::Controller'; }

    with 'ControllerRole';

    sub load : Chained('base') PathPart('') CaptureArgs(1) { }

    sub base : Chained('/') PathPart('foo') CaptureArgs(0) { }

    sub entry : Chained('load') PathPart('') CaptureArgs(0) { }

    sub some_page : Chained('entry') { }

    sub not_attributed {}
}

use Test::More tests => 10;

my $meta = roles::Controller::Foo->meta;
my %expected = (
    base => ["Chained('/')", "PathPart('foo')", "CaptureArgs(0)"],
    load => ["Chained('base')", "PathPart('')", "CaptureArgs(1)"],
    entry => ["Chained('load')", "PathPart('')", "CaptureArgs(0)"],
    some_page => ["Chained('entry')"],
    not_attributed => [],
);
foreach my $method_name (keys %expected) {
    my $method = $meta->get_method($method_name);
    ok $method, "Have method $method_name";
    my $attrs = $meta->get_method_attributes($method->body);
    is_deeply $attrs, $expected{$method_name},
        "Attributes on $method_name as expected";
}

