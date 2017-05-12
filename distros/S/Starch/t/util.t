#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

use Starch::Util qw(
    load_prefixed_module
    apply_method_proxies
    call_method_proxy
    is_method_proxy
);

subtest load_prefixed_module => sub{
    my $prefix = 'Starch';
    my $suffix = '::Test::LoadPrefixedModule';
    my $package = $prefix . $suffix;
    like(
        exception { load_prefixed_module( $prefix, $package ) },
        qr{Can't locate},
        'load_prefixed_module failed on non-existing module',
    );

    eval "package $package; use Moo";

    is(
        load_prefixed_module( $prefix, $package ),
        'Starch::Test::LoadPrefixedModule',
        'load_prefixed_module on absolute package name',
    );

    is(
        load_prefixed_module( $prefix, $suffix ),
        'Starch::Test::LoadPrefixedModule',
        'load_prefixed_module on relative package name',
    );
};

subtest is_method_proxy => sub{
    ok(
        is_method_proxy( ['&proxy', 'foo'] ),
        'valid method proxy',
    );

    ok(
        (!is_method_proxy( ['&proxyy', 'foo'] )),
        'invalid method proxy',
    );
};

{
    package Starch::Test::CallMethodProxy;
    use Moo;
    sub foo { shift; return @_ }
}

my $package = 'Starch::Test::CallMethodProxy';
my $method = 'foo';

subtest call_method_proxy => sub{
    like(
        exception { call_method_proxy() },
        qr{not an array ref},
        'no arguments errored',
    );

    like(
        exception { call_method_proxy([]) },
        qr{"&proxy"},
        'empty array ref errored',
    );

    like(
        exception { call_method_proxy(['foobar']) },
        qr{"&proxy"},
        'array ref without "&proxy" at the start errored',
    );

    like(
        exception { call_method_proxy(['&proxy']) },
        qr{package is undefined},
        'missing package errored',
    );

    like(
        exception { call_method_proxy(['&proxy', $package]) },
        qr{method is undefined},
        'missing method errored',
    );

    like(
        exception { call_method_proxy(['&proxy', '    ', $method]) },
        qr{not a valid package},
        'invalid package errored',
    );

    like(
        exception { call_method_proxy(['&proxy', "Unknown::$package", $method]) },
        qr{Can't locate},
        'non-existing package errored',
    );

    like(
        exception { call_method_proxy(['&proxy', $package, "unknown_$method"]) },
        qr{does not support the .* method},
        'non-existing method errored',
    );

    is(
        exception { call_method_proxy(['&proxy', $package, $method]) },
        undef,
        'proxy did not error',
    );

    is_deeply(
        [ call_method_proxy([ '&proxy', $package, $method, 'bar' ]) ],
        [ 'bar' ],
        'proxy worked',
    );
};

subtest apply_method_proxies => sub{
    my $complex_data_in = {
        foo => 'FOO',
        bar => [ '&proxy', $package, $method, 'BAR' ],
        ary => [
            'one',
            [ '&proxy', $package, $method, 'two' ],
            'three',
        ],
        hsh => {
            this => 'that',
            those => [ '&proxy', $package, $method, 'these' ],
        },
    };

    my $complex_data_out = {
        foo => 'FOO',
        bar => 'BAR',
        ary => ['one', 'two', 'three'],
        hsh => { this=>'that', those=>'these' },
    };

    my $data = apply_method_proxies( $complex_data_in );

    is_deeply(
        $data,
        $complex_data_out,
        'worked',
    );
};

done_testing;
