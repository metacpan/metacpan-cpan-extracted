## no critic (Modules::ProhibitMultiplePackages, Moose::RequireCleanNamespace, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::Needs {
    Moose => '2.1207',
};

use Test::Fatal;
use Test::More 0.96;

{
    package RoleA;

    use Specio::Library::Builtins;
    use Moose::Role;

    has 'A' => (
        is  => 'rw',
        isa => t('HashRef'),
    );

    package RoleB;
    use Moose::Role;
    with 'RoleA';

    package ClassA;
    use Moose;

    # The fact that RoleB _already_ has RoleA triggers Moose's internal Role
    # summation algorithm. That in turn attempts to compare each attribute of
    # the roles for equality. This requires that the types passed for "isa" in
    # the attribute definition implement equality comparison overloading if
    # they are objects.
    ::is(
        ::exception { with 'RoleA', 'RoleB' },
        undef,
        'no exception consuming RoleA and RoleB',
    );
}

done_testing();
