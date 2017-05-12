#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 5 + 1;
use Test::NoWarnings;
use version;

BEGIN { use_ok('Object::Lazy') }

{
    $TestSample::VERSION = '123';

    my $object = Object::Lazy->new({
    build   => \&TestSample::create_object,
        VERSION => qv('1.2.3'),
    });
    is(
        $object->VERSION,
        qv('1.2.3'),
        'VERSION',
    );

    is(
        ref $object,
        'Object::Lazy',
        'ref object is Obejct::Lazy',
    );
}

{
    $TestSample::VERSION = '123';

    my $object = Object::Lazy->new({
        build        => \&TestSample::create_object,
        version_from => 'TestSample',
    });
    is(
        $object->VERSION,
        '123',
        'version_from',
    );

    is(
        ref $object,
        'Object::Lazy',
        'ref object is Obejct::Lazy too',
    );
}

#-----------------------------------------------------------------------------

package TestSample;

sub new {
    return bless {}, shift;
}

# it's a sub, not a method
sub create_object {
    return TestSample->new;
}
