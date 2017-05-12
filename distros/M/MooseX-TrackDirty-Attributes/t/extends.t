use strict;
use warnings;

{ package TestClass::First; use Moose; has foo => (is => 'rw'); }
{
    package TestClass;
    use Moose;
    use MooseX::TrackDirty::Attributes;

    extends 'TestClass::First';

    has '+foo' => (
        traits  => [ TrackDirty ],
    );
}

use Test::More skip_all => 'needs _process_options() to be called';
use Test::Moose::More 0.005;

require 't/funcs.pm' unless eval { require funcs };

validate_class 'TestClass::First' => (

    attributes => [ 'foo' ],
    methods    => [ 'foo' ],
);

validate_class TestClass => (

    attributes => [ 'foo' ],
    methods    => [ 'foo', 'foo_is_dirty' ],
);

done_testing;
