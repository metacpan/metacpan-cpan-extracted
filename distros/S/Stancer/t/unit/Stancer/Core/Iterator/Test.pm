package Stancer::Core::Iterator::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Core::Iterator;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(4) {
    my $callback = sub {};
    my $object = Stancer::Core::Iterator->new($callback);

    isa_ok($object, 'Stancer::Core::Iterator', 'Stancer::Core::Iterator->new($callback)');
    is($object->{callback}, $callback, 'Should have the callback');

    is($object->_create_element, undef, 'Void method (_create_element)');
    is($object->_element_key, undef, 'Void method (_element_key)');
}

sub end : Tests(5) {
    my $called = 0;
    my @returns = (
        random_string(10),
        random_string(10),
    );
    my $callback = sub {
        my $value = $returns[$called];

        $called++;

        return $value;
    };
    my $object = Stancer::Core::Iterator->new($callback);

    is($object->next, $returns[0], 'First call returns first element');
    is($object->end, $object, '$iterator->end should return itself');
    is($object->next, undef, 'Next call returns undef');

    is($object->next, $returns[1], 'Allow to continue if wanted');
    is($object->next, undef, 'Last call still returns undef');
}

sub next : Tests(3) { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $called = 0;
    my @returns = (
        random_string(10),
        random_string(10),
    );
    my $callback = sub {
        my $value = $returns[$called];

        $called++;

        return $value;
    };
    my $object = Stancer::Core::Iterator->new($callback);

    is($object->next, $returns[0], 'First call returns first element');
    is($object->next, $returns[1], 'Second call returns next one');
    is($object->next, undef, 'Last call returns undef');
}

sub search : Tests(2) {
    my $id = random_string(20);

    isa_ok(Stancer::Core::Iterator->search(id => $id), 'Stancer::Core::Iterator', 'Stancer::Core::Iterator->search(id => $id)');
    isa_ok(Stancer::Core::Iterator->search({id => $id}), 'Stancer::Core::Iterator', 'Stancer::Core::Iterator->search({id => $id})');
}

1;
