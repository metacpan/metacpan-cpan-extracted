## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;

## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
eval <<'EOF';
{
    package Foo;
    use MooseX::Params::Validate;
}
EOF

is(
    $@,
    q{},
    'loading MX::Params::Validate in a non-Moose class does not blow up'
);
ok(
    Foo->can('validated_hash'),
    'validated_hash() sub was added to Foo package'
);

done_testing();
