use strict;
use warnings;
use Test::More;

{

    package Some::Parametric::Role::With::Parameter::And::No::Role::Block;
    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter foo => ( is => 'ro' );

    1;
}

{

    package Some::Class::For::Tests::With::Role::Without::Role::Block;

    use Moo;
    use MooX::Role::Parameterized::With;

    with 'Some::Parametric::Role::With::Parameter::And::No::Role::Block'
      ;    # throw error

    1;
}

my $object = Some::Class::For::Tests::With::Role::Without::Role::Block->new();

isa_ok $object, 'Some::Class::For::Tests::With::Role::Without::Role::Block';

done_testing;
