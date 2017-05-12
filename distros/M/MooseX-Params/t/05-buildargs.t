use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params;

    sub test
        :Args(self: Int first)
        :BuildArgs(_buildargs_test)
    { $_{first} }

    sub _buildargs_test { shift, 42 }

    sub test_fail
        :Args(self: Int first)
        :CheckArgs
    { $_{first} }

    sub _checkargs_test_fail { die unless $_{first} > 30 }
}

my $object = TestExecute->new;

is($object->test(24), 42, 'buildargs');
dies_ok { $object->test_fail(24) } 'checkargs dies';
lives_ok { $object->test_fail(42) } 'checkargs lives';

done_testing;
