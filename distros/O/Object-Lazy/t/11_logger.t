#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $object = Object::Lazy->new({
    build => \&TestSample::create_object,
    isa   => [qw(NotExists TestSample)],
});

# logger
$object = Object::Lazy->new({
    build  => \&TestSample::create_object,
    logger => sub {
        like
            +shift,
            qr{\A\Qobject built at}xms,
            'test log message',
    },
});
$object->method;

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
