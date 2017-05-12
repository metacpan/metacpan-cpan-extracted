#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 6 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new(\&TestSample::create_object);
my_sub($object);
sub my_sub {
    my $object = shift;
    is(
        ref $object,
        'Object::Lazy',
        'ref object in sub is Object::Lazy',
    );
    is(
        $object->method,
        'method output',
        'check method output',
    );
    is(
        ref $object,
        'TestSample',
        'ref object in sub is TestSample now',
    );
}
is(
    ref $object,
    'Object::Lazy',
    'ref object is Object::Lazy',
);
$object->method,
is(
    ref $object,
    'TestSample',
    'ref object is TestSample now',
);

#-----------------------------------------------------------------------------

package TestSample;

sub new {
    return bless {}, shift;
}

sub method {
    return 'method output';
}

# it's a sub, not a method
sub create_object {
    return TestSample->new;
}
