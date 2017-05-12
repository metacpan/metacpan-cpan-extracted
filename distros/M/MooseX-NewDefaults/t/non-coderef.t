
use strict;
use warnings;

use Test::More;
use Test::Moose;

# make sure non-coderefs work

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
    use MooseX::NewDefaults;

    extends 'TestClassA';

    default_for one => 'new default!';
}

my $A = TestClassA->new();
my $B = TestClassB->new();

# note the following _passes_ for TestClassB
meta_ok $_ for $A, $B;

has_attribute_ok($_, 'one') for 'TestClassA', 'TestClassB';

can_ok 'TestClassB', 'one';

# attribute defaults
is $A->one, 'original default', 'A has correct default';
is $B->one, 'new default!',     'B has correct default';

my $m = TestClassB->meta->get_method('one');

note blessed $m;
is $m->package_name          , 'TestClassB'                     , 'one() from B';
is $m->original_package_name , 'TestClassB'                     , 'one() originally from B';
isa_ok $m                    , 'Moose::Meta::Method';
isa_ok $m                    , 'Moose::Meta::Method::Accessor';

# check that our one is an attribute now in B
my $att = TestClassB->meta->get_attribute('one');
meta_ok $att;
isa_ok $att, 'Moose::Meta::Attribute';

done_testing;
