use strict;
use warnings;

use Test::More;

{
    package Role;

    use Moose::Role;
    use MooseX::ClassAttribute;

    class_has 'CA' => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );
}

{
    package Role2;
    use Moose::Role;
}

{
    package Bar;
    use Moose;

    with 'Role2', 'Role';
}

ok(
    Bar->can('CA'),
    'Class attributes are preserved during role composition'
);

{
    package Role3;
    use Moose::Role;
    with 'Role';
}

{
    package Baz;
    use Moose;

    with 'Role3';
}

ok(
    Baz->can('CA'),
    'Class attributes are preserved when role is applied to another role'
);

{
    package Role4;
    use Moose::Role;

    use MooseX::ClassAttribute;

    class_has 'CA2' => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );
}

{
    package Buz;
    use Moose;

    with 'Role', 'Role4';
}

ok(
    Buz->can('CA'),
    'Class attributes are merged from two roles (CA)'
);

ok(
    Buz->can('CA2'),
    'Class attributes are merged from two roles (CA2)'
);

{
    package Role5;
    use Moose::Role;
    with 'Role', 'Role4';
}

{
    package Quux;
    use Moose;

    with 'Role5';
}

ok(
    Quux->can('CA'),
    'Class attributes are merged from two roles (CA)'
);

ok(
    Quux->can('CA2'),
    'Class attributes are merged from two roles (CA2)'
);

done_testing();
