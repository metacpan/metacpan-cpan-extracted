use strict;
use warnings;

use Test::More;

BEGIN { plan skip_all => 'This test fails with a syntax error' }

{
    package MooseX::Foo;

    use strict;
    use warnings;

    use Moose::Exporter;
    use MooseX::ClassAttribute ();

    Moose::Exporter->setup_import_methods(
        also => ['MooseX::ClassAttribute'],
    );
}

{
    package MyClass;

    use Moose;

    # use MooseX::Foo;  # normal use
    MooseX::Foo->import;

    # Now theoretically, this should work -- the 'class_has' method
    # should have been imported via the MooseX package above.
    class_has attr => (
        is      => 'ro', isa => 'Str',
        default => 'foo',
    );
}

my $obj = MyClass->new();

is( $obj->attr(), 'foo', 'class attribute is properly created' );

done_testing();
