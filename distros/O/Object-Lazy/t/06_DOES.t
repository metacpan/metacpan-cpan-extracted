#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    UNIVERSAL->can('DOES')
        or plan( skip_all => 'UNIVERSAL 1.04 (Perl 5.10) required for method DOES' );
    plan( tests => 4 + 1 );
}
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new(\&TestSample::create_object);
isa_ok(
    $object,
    'TestSample',
    'the lazy object is a TestSample too',
);
is(
    ref $object,
    'Object::Lazy',
    'ref object is Object::Lazy',
);
$object->DOES('TestSample');
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

# it's a sub, not a method
sub create_object {
    return TestSample->new;
}
