## no critic (Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Test::More 0.96;

{
    package Foo;

    use parent 'Specio::Exporter';
    use Specio::Declare;
    use Specio::Library::Builtins -reexport;

    declare(
        'FooType',
        parent => t('Str'),
    );

    sub foo {42}

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _also_export {'foo'}
}

{
    package Bar;

    Foo->import;

    ::ok(
        t('FooType'),
        'FooType type was exported by Foo package',
    );

    ::ok(
        t('Str'),
        'built-in types were exported by Foo package',
    );

    ::ok(
        Bar->can('foo'),
        'foo sub was exported by Foo package'
    );

    ::is(
        Bar->foo, 42,
        'Bar->foo returns expected value'
    );
}

done_testing();
