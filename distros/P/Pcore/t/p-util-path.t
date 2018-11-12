#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;

our $TESTS = 0;

my $parse_tests = [    #
    [ undef,                                   path => '.',               dirname => '.',           filename => undef,  suffix => undef ],
    [ '',                                      path => '.',               dirname => '.',           filename => undef,  suffix => undef ],
    [ '.',                                     path => '.',               dirname => '.',           filename => undef,  suffix => undef ],
    [ '..',                                    path => '..',              dirname => '..',          filename => undef,  suffix => undef ],
    [ '/',                                     path => '/',               dirname => '/',           filename => undef,  suffix => undef ],
    [ '/.',                                    path => '/',               dirname => '/',           filename => undef,  suffix => undef ],
    [ '/..',                                   path => '/',               dirname => '/',           filename => undef,  suffix => undef ],
    [ 'aaa/bbb/1.pl',                          path => 'aaa/bbb/1.pl',    dirname => 'aaa/bbb',     filename => '1.pl', suffix => 'pl' ],
    [ '/aaa/bbb/1.pl',                         path => '/aaa/bbb/1.pl',   dirname => '/aaa/bbb',    filename => '1.pl', suffix => 'pl' ],
    [ '1.pl',                                  path => '1.pl',            dirname => '.',           filename => '1.pl', suffix => 'pl' ],
    [ '/1.pl',                                 path => '/1.pl',           dirname => '/',           filename => '1.pl', suffix => 'pl' ],
    [ 'aaa/bbb/',                              path => 'aaa/bbb',         dirname => 'aaa/bbb',     filename => undef,  suffix => undef ],
    [ '/aaa/bbb/',                             path => '/aaa/bbb',        dirname => '/aaa/bbb',    filename => undef,  suffix => undef ],
    [ '/aaa/bbb/..//\\./ddddd/../111.pl\\...', path => '/aaa/111.pl/...', dirname => '/aaa/111.pl', filename => '...',  suffix => undef ],

    # volume
    [   'c:/../aaa/bbb/',
        path    => $MSWIN ? 'c:/aaa/bbb' : 'aaa/bbb',
        volume  => $MSWIN ? 'c'          : undef,
        dirname => $MSWIN ? 'c:/aaa/bbb' : 'aaa/bbb',
        filename => undef,
        suffix   => undef
    ],

    # volume
    [   '/c:/../aaa/bbb/',
        path     => '/aaa/bbb',
        volume   => undef,
        dirname  => '/aaa/bbb',
        filename => undef,
        suffix   => undef
    ],
];

for my $test ( $parse_tests->@* ) {
    my $path = P->path( shift $test->@* );

    my %args = $test->@*;

    for my $arg ( sort keys %args ) {
        $TESTS++;

        if ( !defined $args{$arg} ) {
            ok( !defined $path->{$arg}, 'parse' ) or printf qq[path: "%s", %s "%s" != "%s"\n], $path, $arg, $path->{$arg} // 'undef', 'undef';
        }
        else {
            no warnings qw[uninitialized];

            ok( $path->{$arg} eq $args{$arg}, 'parse' ) or printf qq[path: "%s", %s "%s" != "%s"\n], $path, $arg, $path->{$arg} // 'undef', $args{$arg};
        }
    }
}

plan tests => $TESTS;
done_testing $TESTS;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 12                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
