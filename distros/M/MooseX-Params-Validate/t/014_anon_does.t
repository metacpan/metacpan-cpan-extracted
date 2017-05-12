## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

# This test tries to find breakage caused by the bug reported in
# https://rt.cpan.org/Ticket/Display.html?id=101988
#
# It turns out that despite the typo in the code, there is no bug, because
# even though _is_tc() checks the wrong thing, the subsequent call to
# find_type_constraint _also_ checks whether the argument is a
# Moose::Meta::TypeConstraint object! I fixed the bug and left the _is_tc()
# check in because the docs for find_type_constraint() don't actually specify
# this particular behavior.

{
    package Role;
    use Moose::Role;
}

{
    package DoesRole;
    use Moose;
    with 'Role';
}

{
    package Foo;
    use Moose;
    use Moose::Meta::TypeConstraint::Role;
    use MooseX::Params::Validate;

    my $role_type = Moose::Meta::TypeConstraint::Role->new(
        role => 'Role',
    );

    sub foo {
        my ( $self, $other ) = validated_list(
            \@_,
            other => { does => $role_type },
        );

        return;
    }
}

is(
    exception { Foo->new->foo( other => DoesRole->new ) },
    undef,
    'no exception when does is given a TC object that is not registered'
);

done_testing();
