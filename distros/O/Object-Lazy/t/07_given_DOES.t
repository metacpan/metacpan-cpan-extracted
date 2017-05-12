#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    UNIVERSAL->can('DOES')
        or plan( skip_all => 'UNIVERSAL 1.04 (Perl 5.10) required for method DOES' );
    plan( tests => 3 + 1 );
}
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new({
    build => \&TestSample::create_object,
    DOES  => [qw(NotExists TestSample)],
});
ok(
    $object->DOES('NotExists'),
    'parameter DOES is qw(NotExists TestSample)',
);

# ask class about DOES
@TestSample::ISA = qw(TestBase);
ok(
    $object->DOES('TestBase'),
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
