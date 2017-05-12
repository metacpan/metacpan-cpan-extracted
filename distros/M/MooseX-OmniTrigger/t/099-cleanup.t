use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::More;

my $demolished;

{ package MyClass; use Moose; use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', omnitrigger => sub {});

    sub DEMOLISH { $demolished++ }
}

TEST: {

    $demolished = 0;

    {
        my $obj1 = MyClass->new;
        my $obj2 = MyClass->new;

        cmp_ok(keys(%{MooseX::OmniTrigger::State->singleton->_test_me}) + 0, '==', 2, "there's a state entry for each of two existing objects");

        undef($obj2);

        cmp_ok(keys(%{MooseX::OmniTrigger::State->singleton->_test_me}) + 0, '==', 1, 'only one state entry remains following the destruction of one of two objects');
    }

    cmp_ok($demolished, '==', 2, 'objects were demolished on time');

    MyClass->meta->make_immutable, redo TEST if MyClass->meta->is_mutable;
}

done_testing;
