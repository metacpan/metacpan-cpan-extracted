use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.019

use Test::More tests => 4;

SKIP: {
    eval { +require Module::Runtime::Conflicts; Module::Runtime::Conflicts->check_conflicts };
    skip('no Module::Runtime::Conflicts module found', 1) if not $INC{'Module/Runtime/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via Module::Runtime::Conflicts';
}

SKIP: {
    eval { +require Moose::Conflicts; Moose::Conflicts->check_conflicts };
    skip('no Moose::Conflicts module found', 1) if not $INC{'Moose/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via Moose::Conflicts';
}

SKIP: {
    eval { +require Package::Stash::Conflicts; Package::Stash::Conflicts->check_conflicts };
    skip('no Package::Stash::Conflicts module found', 1) if not $INC{'Package/Stash/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via Package::Stash::Conflicts';
}

pass 'no x_breaks data to check';
