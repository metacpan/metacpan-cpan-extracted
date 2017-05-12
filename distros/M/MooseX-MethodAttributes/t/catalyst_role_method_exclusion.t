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

    sub excluded : Local {}
}
{
    package roles::Controller::Foo;
    use Moose;
    BEGIN { extends 'Catalyst::Controller'; }

    with 'ControllerRole' => { -excludes => 'not_attributed' };
}

use Test::More tests => 1;

my $meta = roles::Controller::Foo->meta;
TODO: {
    local $TODO = 'Aliasing and exclusion does not work';
    ok !$meta->get_method('excluded');
}
