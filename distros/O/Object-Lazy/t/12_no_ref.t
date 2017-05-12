#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 3 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new({
    build => \&TestSample::create_object,
    isa   => [qw(NotExists TestSample)],
});

throws_ok(
    sub {
        $object = Object::Lazy->new({
            build => \&TestSample::create_object,
            ref   => 'MyClass',
        });
    },
    qr{\Qdepends use Object::Lazy::Ref}xms,
    'error at paramater ref',
);
$object = Object::Lazy->new({
    build => \&TestSample::create_object,
});
is(
    ref $object,
    'Object::Lazy',
    'ref is Object::Lazy',
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
