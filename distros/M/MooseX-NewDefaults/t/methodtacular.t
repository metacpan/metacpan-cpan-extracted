use strict;
use warnings;

use Test::More;
use Test::Moose;

use Scalar::Util 'blessed';

# define two classes, and make sure our meta method works

{
    package TestClassA;
    use Moose;
    use namespace::autoclean;

    has one => (is => 'ro', lazy => 1, default => sub { 'original default' });

    has three => (is => 'ro', default => 'just to make sure');
}
{
    package TestClassB;
    use Moose;
    use namespace::autoclean;
    use MooseX::NewDefaults::Magic;

    extends 'TestClassA';

    sub one { 'new default!' }

    sub two { 'twoooooooooo' }

    # sanity check to make sure this is exported as we expect
    default_for three => 'Something else';
}

my $A = TestClassA->new();
my $B = TestClassB->new();

# note the following _passes_ for TestClassB
meta_ok $_ for $A, $B;

# attribute, locally defined method
is $A->one, 'original default', 'A has correct default';
is $B->one, 'new default!',     'B has correct default';

has_attribute_ok($_, 'one') for 'TestClassA', 'TestClassB';

# B has a local method named 'one'
can_ok 'TestClassB', 'one';

my $m = TestClassB->meta->get_method('one');

note blessed $m;
isa_ok $m                                    , 'Moose::Meta::Method';
is $m->package_name                          , 'TestClassB'                   , 'one() from B';
is $m->original_package_name                 , 'TestClassB'                   , 'one() originally from B';
ok !$m->isa('Moose::Meta::Method::Generated') , 'one isnota generated method';
ok !$m->isa('Moose::Meta::Method::Accessor')  , 'one isnotan accessor';

TestClassB->meta->make_immutable;

# attribute, ancestor attribute
is $A->one, 'original default', 'A has correct default';
is $B->one, 'new default!',     'B has correct default';

# no more local method
can_ok 'TestClassB', 'one';

# make sure our one() is now an accessor
$m = TestClassB->meta->get_method('one');
note blessed $m;
is $m->package_name          , 'TestClassB'                     , 'one() from B';
is $m->original_package_name , 'TestClassB'                     , 'one() originally from B';
isa_ok $m                    , 'Moose::Meta::Method';
isa_ok $m                    , 'Moose::Meta::Method::Accessor';

# check that our one is an attribute now in B
my $att = TestClassB->meta->get_attribute('one');
meta_ok $att;
isa_ok $att, 'Moose::Meta::Attribute';

# make sure we haven't messed with two()
$m = TestClassB->meta->get_method('two');
note blessed $m;
isa_ok $m                                    , 'Moose::Meta::Method';
is $m->package_name                          , 'TestClassB'                   , 'two() from B';
is $m->original_package_name                 , 'TestClassB'                   , 'two() originally from B';
ok !$m->isa('Moose::Meta::Method::Generated') , 'two isnota generated method';
ok !$m->isa('Moose::Meta::Method::Accessor')  , 'two isnotan accessor';
done_testing;
