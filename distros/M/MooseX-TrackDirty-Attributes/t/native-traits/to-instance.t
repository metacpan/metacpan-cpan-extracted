use strict;
use warnings;

my $trait_name;

{
    package TestClass;
    use Moose;
    use MooseX::TrackDirty::Attributes;

    has foo => (

        traits  => [ 'String' ],
        is      => 'rw',
        isa     => 'Str',
        clearer => 'clear_foo',
        default => q{},
        handles => {

            foo_length => 'length',
            foo_append => 'append',
        },
    );

    $trait_name = TrackDirty;
}

use Test::More skip_all => 'needs _process_options() to be called';
use Test::Moose::More 0.005;

use Class::Load;
use Moose::Util;
use MooseX::TrackDirty::Attributes::Util ':all';

require 't/funcs.pm' unless eval { require funcs };

subtest 'check attribute meta and apply to instance' => sub {

    # some little checks
    my $meta = TestClass->meta->get_attribute('foo');
    isa_ok($meta, 'Moose::Meta::Attribute');
    does_ok $meta, 'Moose::Meta::Attribute::Native::Trait::String';

    # then, apply... and check
    note $trait_name;
    Class::Load::load_class($trait_name);
    Moose::Util::apply_all_roles($meta, $trait_name);
    does_ok($meta, $trait_name);
    does_ok($meta, TrackDirtyNativeTrait);
    has_method_ok 'TestClass', 'foo_is_dirty';
};

with_immutable { do_tests() } 'TestClass';

done_testing;
