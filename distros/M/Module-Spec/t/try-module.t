
use Test::More 0.88;
use Test::Fatal;

use Module::Spec::V1 ();

BEGIN {
    *try_module = \*Module::Spec::V1::try_module;
}

use lib qw(t/lib);

# Successful loads
{
    my $m = try_module('Foo');
    is $m, 'Foo', 'simple try_module';
}
{
    my $m = try_module('Foo~0.1.2');
    is $m, 'Foo', 'try_module with version';
}
{
    my $m = try_module('Foo~0.1.0');
    is $m, 'Foo', 'try_module with version';
}
{
    my $m = try_module('Foo~0');
    is $m, 'Foo', 'try_module("M~0")';
}
{
    my $m = try_module('NoVersion');
    is $m, 'NoVersion', 'try_module("M") on module with no version';
}
{
    my $m = try_module('NoVersion~0');
    is $m, 'NoVersion', 'try_module("M~0") on module with no version';
}
{
    my ( $m, $v ) = try_module('Foo');
    is_deeply [ $m, $v ], [ 'Foo', Foo->VERSION ],
      'simple try_module in list context';
}
{
    my ( $m, $v ) = try_module('Foo~0.1.2');
    is_deeply [ $m, $v ], [ 'Foo', Foo->VERSION ],
      'try_module with version in list context';
}
{
    my ( $m, $v ) = try_module('Foo~0.1.0');
    is_deeply [ $m, $v ], [ 'Foo', Foo->VERSION ],
      'try_module with version in list context';
}
{
    my ( $m, $v ) = try_module('NoVersion');
    is_deeply [ $m, $v ], [ 'NoVersion', NoVersion->VERSION ],
      'try_module("M") on module with no version - list context';
}

# Sucessful loads - with {require => $r}
{

    package FooFoo;    # Inline package, should not be required
    our $VERSION = '3.4';
    sub do_foo { }
}
{
    my $m = try_module( 'FooFoo', { require => 0 } );
    is $m, 'FooFoo', 'try_module with disabled "require"';
}
{
    my $m = try_module( 'FooFoo~3', { require => 0 } );
    is $m, 'FooFoo', 'try_module with version + disabled "require"';
}
{
    my $m = try_module( 'FooFoo~3',
        { require => sub { !shift->can('do_foo') }, } );
    is $m, 'FooFoo', 'try_module with version + dynamic "require"';
}

# Failed loads
{
    my $m = try_module('NonExisting');
    is $m, undef, 'try_module returns undef on missing module';
}
{
    my $m = try_module('Foo~0.2.0');
    is $m, undef, 'try_module returns undef on bad version';
}
{
    my @mv = try_module('Foo~0.2.0');
    is @mv, 0, 'try_module returns empty list on bad version';
}
{
    my $m = try_module( 'FooFoo~4', { require => 0 } );
    ok !$m,
      'try_module with version + disabled "require" returns undef on bad version';
}
{
    my @mv = try_module( 'FooFoo~4', { require => 0 } );
    is @mv, 0,
      'try_module with version + disabled "require" returns empty list on bad version';
}

# Failed requires
{
    like(
        exception { try_module('BadFoo') },
        qr/^Not good\b/,
        'try_module rethrows on failed compilation'
    );
}
{
    like(
        exception { try_module('BadBadFoo') },
        qr/^BadBadFoo.pm did not return a true value\b/,
        'try_module rethrows on failed compilation'
    );
}
{
    like(
        exception { try_module('BadBadBadFoo') },
        qr/^Missing right curly or square bracket\b/,
        'try_module rethrows on failed compilation'
    );
}
{
    like(
        exception { try_module('NoVersion~1') },
        qr/^NoVersion does not define \$NoVersion::VERSION\b/,
        'try_module M~V rethrows on module with no version'
    );
}

done_testing;
