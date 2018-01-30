
use Test::More 0.88;
use Test::Fatal;

use Module::Spec::V2 ();

BEGIN {
    *need_module = \*Module::Spec::V2::need_module;
}

use lib qw(t/lib);

{
    my $m = need_module('Foo');
    is $m, 'Foo', 'simple need_module';
}
{
    my $m = need_module('Foo~0.1.2');
    is $m, 'Foo', 'need_module with version';
}
{
    my $m = need_module('Foo~0.1.0');
    is $m, 'Foo', 'need_module with version';
}
{
    my $m = need_module('Foo~0');
    is $m, 'Foo', 'need_module("M~0")';
}
{
    my $m = need_module('NoVersion');
    is $m, 'NoVersion', 'need_module("M") on module with no version';
}
{
    my $m = need_module('NoVersion~0');
    is $m, 'NoVersion', 'need_module("M~0") on module with no version';
}
{
    my ( $m, $v ) = need_module('Foo');
    is_deeply [ $m, $v ], [ 'Foo', Foo->VERSION ],
      'simple need_module in list context';
}
{
    my ( $m, $v ) = need_module('Foo~0.1.2');
    is_deeply [ $m, $v ], [ 'Foo', Foo->VERSION ],
      'need_module with version in list context';
}
{
    my ( $m, $v ) = need_module('Foo~0.1.0');
    is_deeply [ $m, $v ], [ 'Foo', Foo->VERSION ],
      'need_module with version in list context';
}
{
    my ( $m, $v ) = need_module('NoVersion');
    is_deeply [ $m, $v ], [ 'NoVersion', NoVersion->VERSION ],
      'need_module("M") on module with no version - list context';
}
{
    like exception { need_module('NonExisting') },
      qr/^Can't locate NonExisting.pm\b/,
      'need_module with missing module fails';
}
{
    like exception { need_module('Foo~0.2.0') },
      qr/^Foo version v0.2.0 required--this is only version v0.1.2\b/,
      'need_module with version fails on bad version';
}
{

    package FooFoo;    # Inline package, should not be required
    our $VERSION = '3.4';
    sub do_foo { }
}
{
    my $m = need_module( 'FooFoo', { require => 0 } );
    is $m, 'FooFoo', 'need_module with disabled "require"';
}
{
    my $m = need_module( 'FooFoo~3', { require => 0 } );
    is $m, 'FooFoo', 'need_module with version + disabled "require"';
}
{
    like exception { need_module( 'FooFoo~4', { require => 0 } ) },
      qr/^FooFoo version 4 required--this is only version 3.4\b/,
      'need_module with version + disabled "require" fails on bad version';
}
{
    my $m = need_module( 'FooFoo~3',
        { require => sub { !shift->can('do_foo') }, } );
    is $m, 'FooFoo', 'need_module with version + dynamic "require"';
}
{
    like(
        exception { need_module('NoVersion~1') },
        qr/^NoVersion does not define \$NoVersion::VERSION\b/,
        'need_module M~V rethrows on module with no version'
    );
}

done_testing;
