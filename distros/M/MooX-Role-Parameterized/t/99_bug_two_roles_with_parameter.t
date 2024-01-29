use strict;
use warnings;
use Test::More;

{

    package Some::Parametric::Role::With::Parameter;
    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter foo => ( is => 'ro' );

    role {};

    1;
}

{

    package Some::Class::For::Tests;

    use Moo;
    use MooX::Role::Parameterized::With;

    with 'Some::Parametric::Role::With::Parameter';

    1;
}

{

    package Another::Parametric::Role::With::Parameter;
    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter bar => ( is => 'ro' );

    role {

    };
    1;
}

my $object = Some::Class::For::Tests->new();

isa_ok $object, 'Some::Class::For::Tests';

done_testing;
