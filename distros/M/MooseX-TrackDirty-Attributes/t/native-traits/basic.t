use strict;
use warnings;

{
    package TestClass;
    use Moose;
    use MooseX::TrackDirty::Attributes;

    has foo => (

        traits  => [ TrackDirty, 'String' ],
        is      => 'rw',
        isa     => 'Str',
        clearer => 'clear_foo',
        default => q{},
        handles => {

            foo_length => 'length',
            foo_append => 'append',
        },
    );

}

use Test::More;
use Test::Moose::More 0.005;

require 't/funcs.pm' unless eval { require funcs };

with_immutable { do_tests() } 'TestClass';

done_testing;
