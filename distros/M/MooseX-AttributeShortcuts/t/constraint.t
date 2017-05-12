use strict;
use warnings;

# test our new constraint option
#
# this test is perhaps a bit redundnant, given t/inline_*.t, but it's kinda
# where I'd like to see it go when Test::Moose::More is retrofitted with
# isa/type_constraint checking support.

use Test::More;
use Test::Moose::More;
use Moose::Util;
use Moose::Util::TypeConstraints;

my $shortcuts;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    $shortcuts = Shortcuts;

    has foo => (
        is         => 'rw',
        isa        => 'Str',
        constraint => sub { /^Hi/ },
    );

}

my $tc =
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint('Str')
    ->create_child_type(constraint => sub { /^Hi/ })
    ;

validate_class TestClass => (
    attributes => [
        foo => {
            -does           => [ $shortcuts ],
            accessor        => 'foo',
            original_isa    => 'Str',
            type_constraint => $tc,
            isa             => $tc,
        },
    ],
);

done_testing;
