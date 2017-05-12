use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings qw( warnings );

## no critic (Modules::ProhibitMultiplePackages)

{
    package Foo;

    our $VERSION = '0.03';

    use Exporter qw( import );

    our @EXPORT_OK = qw( exported );

    use Package::DeprecationManager -deprecations => {
        'Foo::foo' => '0.02',
    };

    sub foo {
        deprecated();
    }

    sub exported {
        return 'exported';
    }
}

{
    package Bar;

    Foo->import( 'exported', -api_version => '0.01' );

    ::is_deeply(
        [ ::warnings { Foo::foo() } ],
        [],
        'no warning for foo with api_version = 0.01'
    );

    ::is(
        exported(),
        'exported',
        'sub exported by Foo was imported and work as expected'
    );
}

done_testing();
