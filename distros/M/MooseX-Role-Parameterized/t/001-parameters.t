use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use MooseX::Role::Parameterized::Parameters;

my $p = MooseX::Role::Parameterized::Parameters->new;
can_ok($p => 'meta');

do {
    package MyRole::NoParameters;
    use MooseX::Role::Parameterized;
};

my $parameters_metaclass = MyRole::NoParameters->meta->parameters_metaclass;
is($parameters_metaclass->get_all_attributes, 0, "no parameters");

do {
    package MyRole::LengthParameter;
    use MooseX::Role::Parameterized;

    parameter length => (
        isa      => 'Int',
        required => 1,
    );
};

$parameters_metaclass = MyRole::LengthParameter->meta->parameters_metaclass;
is($parameters_metaclass->get_all_attributes, 1, "exactly one parameter");

my $parameter = ($parameters_metaclass->get_all_attributes)[0];
is($parameter->name, 'length', "parameter name");
ok($parameter->is_required, "parameter is required");

ok(MyRole::LengthParameter->meta->has_parameter('length'), 'has_parameter');
ok(!MyRole::LengthParameter->meta->has_parameter('kjhef'), 'has_parameter');

like( exception {
    MyRole::LengthParameter->meta->construct_parameters;
}, qr/^Attribute \(length\) is required/);

$p = MyRole::LengthParameter->meta->construct_parameters(
    length => 5,
);

is($p->length, 5, "correct length");

like( exception {
    $p->length(10);
}, qr/^Cannot assign a value to a read-only accessor/);

do {
    package MyRole::LengthParameter;
    use MooseX::Role::Parameterized;

    parameter ['first_name', 'last_name'] => (
        is  => 'rw',
        isa => 'Str',
    );
};

$parameters_metaclass = MyRole::LengthParameter->meta->parameters_metaclass;
is($parameters_metaclass->get_all_attributes, 3, "three parameters");

for my $param_name ('first_name', 'last_name') {
    my $param = $parameters_metaclass->get_attribute($param_name);
    is($param->type_constraint, 'Str', "$param_name type constraint");
    ok(!$param->is_required, "$param_name is optional");
}

done_testing;
