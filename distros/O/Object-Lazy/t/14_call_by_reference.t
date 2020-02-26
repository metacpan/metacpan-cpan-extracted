#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Object::Lazy');
}

{
    package MyClass;
    sub new { return bless {}, $_[0] }
    sub store { $_[1] = 'mouse' }
}

my $object = Object::Lazy->new( sub { return MyClass->new } );
$object->store( my $lazy_out );

is
    $lazy_out,
    'mouse',
    'call by reference';
