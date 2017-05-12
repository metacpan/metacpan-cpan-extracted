use strict;
use warnings;

use Test::More;
use Test::Moose;

# a set of tests to ensure that my understanding of this part of the MOP is
# correct, and that it stays correct :)

{
    package TestClassA;
    use Moose;
    use namespace::autoclean;

    has one => (is => 'ro', lazy => 1, default => sub { 'original default' });
}
{
    package TestClassB;
    use Moose;
    use namespace::autoclean;

    extends 'TestClassA';

    sub one { 'new default!' }
}

my $A = TestClassA->new();
my $B = TestClassB->new();

meta_ok $_ for $A, $B;

# attribute, locally defined method
is $A->one, 'original default';
is $B->one, 'new default!';

has_attribute_ok($_, 'one') for 'TestClassA', 'TestClassB';

TestClassB->meta->remove_method('one');

# attribute, ancestor attribute
is $A->one, 'original default';
is $B->one, 'original default';

done_testing;
