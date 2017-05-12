use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params;

    sub test_isa :Args(self: Int first) { $_{first} }

    sub test_required :Args(self: first) { $_{first} }

    sub test_slurpy :Args(self: Str join, ArrayRef[Int] *all)
    {
        join $_{join}, @{$_{all}}
    }

    subtype 'ArrayRefOfInt' => as 'ArrayRef[Int]';

    coerce 'ArrayRefOfInt'
        => from 'Int'
        => via { [ $_ ] };

    sub test_transform
        :Args(self: &ArrayRefOfInt first, ArrayRefOfInt second, ArrayRefOfInt third = _build_param_third)
    {
        @_{qw(first second third)}
    }

    sub _build_param_third { [42] }
}

my $object = TestExecute->new;

lives_ok { $object->test_isa(5)      } 'isa ok';
dies_ok  { $object->test_isa('Five') } 'isa fail';
lives_ok { $object->test_required(5) } 'required ok';
dies_ok  { $object->test_required()  } 'required fail';

is($object->test_slurpy('-', qw(1 2 3)), '1-2-3', 'slurpy');

my ($first, $second, $third) = $object->test_transform(42, [42]);

is($$first[0], 42, 'coerce');
is($$third[0], 42, 'default');

done_testing();

