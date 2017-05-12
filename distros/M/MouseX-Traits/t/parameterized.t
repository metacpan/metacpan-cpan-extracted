use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    plan 'skip_all', 'testing parameterized roles requires MouseX::Role::Parameterized 0.13'
      unless eval {
        require MouseX::Role::Parameterized;
        MouseX::Role::Parameterized->VERSION('0.13');
      };

    plan tests => 11;
}

{
    package Role;
    use Mouse::Role;

    has 'gorge' => (
        is       => 'ro',
        required => 1,
    );
}

{
    package PRole;
    use MouseX::Role::Parameterized;

    parameter 'foo' => (
        is       => 'ro',
        required => 1,
    );

    role {
        my $p = shift;

        has $p->foo => (
            is       => 'ro',
            required => 1,
        );
    }
}

{
    package Class;
    use Mouse;

    with 'MouseX::Traits';
}

lives_ok {
    Class->new;
} 'making class is OK';

lives_ok {
    Class->new_with_traits;
} 'making class with no traits is OK';

my $a;

lives_ok {
    $a = Class->new_with_traits(
        traits => ['PRole' => { foo => 'OHHAI' }],
        OHHAI  => 'I FIXED THAT FOR YOU',
    );
} 'prole is applied OK';

isa_ok $a, 'Class';
is $a->OHHAI, 'I FIXED THAT FOR YOU', 'OHHAI accessor works';

lives_ok {
    undef $a;
    $a = Class->new_with_traits(
        traits => ['PRole' => { foo => 'OHHAI' }, 'Role'],
        OHHAI  => 'I FIXED THAT FOR YOU',
        gorge  => 'three rivers',
    );
} 'prole is applied OK along with a normal role';

can_ok $a, 'OHHAI', 'gorge';

lives_ok {
    undef $a;
    $a = Class->new_with_traits(
        traits => ['Role', 'PRole' => { foo => 'OHHAI' }],
        OHHAI  => 'I FIXED THAT FOR YOU',
        gorge  => 'columbia river',
    );
} 'prole is applied OK along with a normal role (2)';

can_ok $a, 'OHHAI', 'gorge';

lives_ok {
    undef $a;
    $a = Class->new_with_traits(
        traits => ['Role' => { bullshit => 'params', go => 'here' }],
        gorge  => 'i should have just called this foo',
    );
} 'regular roles with args can be applied, but args are ignored';

can_ok $a, 'gorge';
