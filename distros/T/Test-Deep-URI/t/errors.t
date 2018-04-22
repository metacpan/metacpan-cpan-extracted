# vim: set ft=perl
use strict;
use warnings;

# This test checks various permutations of bad input.

use Test::Tester;

use Test::More tests => 10;
use Test::Warnings 'warnings';
use Test::Deep;
use Test::Deep::URI;

my $scheme = 'http';
my $host = 'everythingis.awesome';
my $path = 'this/is/the/path';
my $params = 'a=1&b=2&a=3';
my $fragment = 'final countdown';

my $test_uri = "$scheme://$host/$path?$params#$fragment";

subtest 'wrong scheme' => sub {
    my @tests = ( "https://$host/$path?$params#$fragment" );

    check_test
        sub { cmp_deeply( $test_uri, uri($tests[0])) },
        {
            ok => 0,
            diag => <<EOTXT
Compared \$data->[1]->scheme
   got : 'http'
expect : 'https'
EOTXT
        };
};

subtest 'wrong host' => sub {
    my @tests = (
        "$scheme://badhost/$path?$params#$fragment",
        "//badhost/$path?$params#$fragment",
    );

    foreach my $expected (@tests) {
        # Because of the host kludge, we can expect two
        # different responses
        my ($premature, @results) = run_tests(
            sub {
                cmp_deeply(
                    $test_uri,
                    uri($expected),
                );
            }
        );

        cmp_deeply(
            [ $premature, @results ],
            [
                bool(0),
                superhashof({
                    diag => re(
                        qr/
                            ^Compared\ \$data->(\[1\]->host|\[2\])\n
                            \s+got\ :\ 'everythingis\.awesome'\n
                            expect\ :\ 'badhost'$
                        /x),
                    ok => bool(0),
                })
            ],
            'Got error message for wrong host'
        );
    }
};

subtest 'wrong path' => sub {
    my @tests = (
        "$scheme://$host/meh?$params#$fragment",
        "//$host/meh?$params#$fragment",
        "/meh?$params#$fragment",
    );

    foreach my $expected (@tests) {
        check_test
            sub { cmp_deeply($test_uri, uri($expected)) },
            {
                ok => 0,
                diag => <<EOTXT
Compared \$data->[1]->path
   got : '/$path'
expect : '/meh'
EOTXT
            };
    }
};

subtest 'wrong cgi params (extra param)' => sub {
    my @tests = (
        "$scheme://$host/$path?$params&yarr=23#$fragment",
        "//$host/$path?$params&yarr=23#$fragment",
        "/$path?$params&yarr=23#$fragment",
    );

    foreach my $expected (@tests) {
        check_test
            sub { cmp_deeply($test_uri, uri($expected)) },
            {
                ok => 0,
                diag => <<EOTXT
Comparing hash keys of \$data->[0]
Missing: 'yarr'
EOTXT
            };
    }
};

#my $params = 'a=1&b=2&a=3';
subtest 'wrong cgi params (wrong singular param)' => sub {
    my @tests = (
        "$scheme://$host/$path?a=1&b=20&a=3#$fragment",
        "//$host/$path?a=1&b=20&a=3#$fragment",
        "/$path?a=1&b=20&a=3#$fragment",
    );

    foreach my $expected (@tests) {
        check_test
            sub { cmp_deeply($test_uri, uri($expected)) },
            {
                ok => 0,
                diag => <<EOTXT
Compared \$data->[0]{"b"}
   got : '2'
expect : '20'
EOTXT
            };
    }
};

subtest 'wrong cgi params (list too long)' => sub {
    my @tests = (
        "$scheme://$host/$path?a=1&b=2&a=3&a=4#$fragment",
        "//$host/$path?a=1&b=2&a=3&a=4#$fragment",
        "/$path?a=1&b=2&a=3&a=4#$fragment",
    );

    foreach my $expected (@tests) {
        check_test
            sub { cmp_deeply($test_uri, uri($expected)) },
            {
                ok => 0,
                diag => <<EOTXT
Compared array length of \$data->[0]{"a"}
   got : array with 2 element(s)
expect : array with 3 element(s)
EOTXT
            };
    }
};

subtest 'wrong cgi params (list in wrong order)' => sub {
    my @tests = (
        "$scheme://$host/$path?a=3&b=2&a=1#$fragment",
        "//$host/$path?a=3&b=2&a=1#$fragment",
        "/$path?a=3&b=2&a=1#$fragment",
    );

    foreach my $expected (@tests) {
        check_test
            sub { cmp_deeply($test_uri, uri($expected)) },
            {
                ok => 0,
                diag => <<EOTXT
Compared \$data->[0]{"a"}[0]
   got : '1'
expect : '3'
EOTXT
            };
    }
};

subtest 'wrong fragment' => sub {
    my @tests = (
        "$scheme://$host/$path?$params#not final",
        "//$host/$path?$params#not final",
        "/$path?$params#not final",
    );

    foreach my $expected (@tests) {
        check_test
            sub { cmp_deeply($test_uri, uri($expected)) },
            {
                ok => 0,
                diag => <<EOTXT
Compared \$data->[1]->fragment
   got : 'final%20countdown'
expect : 'not%20final'
EOTXT
            };
    }
};

subtest 'missing arg to uri()' => sub {
    my @results;
    my @warnings = warnings {
        @results = run_tests(sub { cmp_deeply($test_uri, uri()) });
    };

    cmp_deeply(\@warnings, [ re(qr/Missing argument to uri\(\)/) ], 'Warned about missing argument');
    cmp_deeply(\@results,
        [
            bool(0), # premature = false
            superhashof({
                    ok => bool(0),
                }),
        ],
        'undef failed to match a real URI',
    );
};

