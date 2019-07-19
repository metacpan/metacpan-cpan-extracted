use strict;
use warnings;
use Test::More 0.88;

use Test::Needs {
    'MooseX::Role::WithOverloading' => '0.14',
};

do {
    package MyParameterizedRole;

    BEGIN { MooseX::Role::WithOverloading->import }
    use MooseX::Role::Parameterized;

    use overload q{""} => '_stringify';

    parameter default => ( required => 1 );

    role {
        my $p   = shift;
        my %foo = @_;

        has foo => (
            is      => 'ro',
            isa     => 'Str',
            default => $p->default(),
        );
    };

    sub _stringify { $_[0]->foo() }
};

do {
    package MyClass;
    use Moose;
    with 'MyParameterizedRole' => { default => 'string' };
};

my $object = MyClass->new();

is(
    $object->foo(),
    'string',
    'MyClass object has foo attribute with default passed to parameterized role'
);

is(
    "$object",
    'string',
    'MyClass object stringifies to value of foo attribute'
);

done_testing();
