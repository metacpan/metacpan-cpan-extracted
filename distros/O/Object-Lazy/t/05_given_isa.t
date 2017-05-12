#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 3 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new({
    build => \&TestSample::create_object,
    isa   => [qw(NotExists TestSample)],
});
isa_ok(
    $object,
    'NotExists',
    'parameter isa is qw(NotExists TestSample)',
);

# ask class about isa
@TestSample::ISA = qw(TestBase);
isa_ok(
    $object,
    'TestBase',
    'base class of TestSample',
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

#-----------------------------------------------------------------------------

package TestBase;
