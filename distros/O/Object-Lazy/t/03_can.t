#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 3 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new(\&TestSample::create_object);
ok(
    $object->can('method'),
    'can method',
);
is(
    ref $object,
    'TestSample',
    'ref object is TestSample',
);

#-----------------------------------------------------------------------------

package TestSample;

sub new {
    return bless {}, shift;
}

sub method {
    return;
}

# it's a sub, not a method
sub create_object {
    return TestSample->new;
}
