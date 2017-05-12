#!/usr/bin/env perl

use 5.008003;
use utf8;
use strict;
use warnings;

use Module::Used qw< modules_used_in_string modules_used_in_files modules_used_in_modules >;

use Test::Deep qw< bag cmp_deeply >;
use Test::More tests => 22;


{
    my $code;


    $code = 'say $x;';  ## no critic (RequireInterpolationOfMetachars)
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        [],
        $code,
    );


    $code = 'use strict;';
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        [ qw< strict > ],
        $code,
    );


    $code = 'use 5.006;';
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        [],
        $code,
    );


    $code = q< use A; require B; no C; >;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< A B C > ),
        'use require no',
    );


    $code = q<use base>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< base > ),
        $code,
    );


    $code = q<use base 2.13;>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< base > ),
        $code,
    );


    $code = q<use base 'A';>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< A base > ),
        $code,
    );

    cmp_deeply(
        [ modules_used_in_modules( 'Module::Used' ) ],
        bag(
            qw<
                Const::Fast
                English
                Exporter
                Module::Path
                PPI::Document
                strict
                utf8
                version
                warnings
            >
        ),
        'Module::Used',
    );


    $code = q<use base 'A', "B", q[C], qq[D::E];>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< A B C D::E base > ),
        $code,
    );


    $code = q<use parent 'A', qw[ B C D::E ];>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< A B C D::E parent > ),
        $code,
    );


    $code = q<use base 2.13 'A';>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< A base > ),
        $code,
    );


    cmp_deeply(
        [ modules_used_in_files( __FILE__ ) ],
        bag( qw< utf8 strict warnings Module::Used Test::Deep Test::More > ),
        $code,
    );


    $code = q<with 'Bar', 'Baz'>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( qw< > ),
        $code,
    );
}


_test_moose_sugar('extends', 'Moose');
_test_moose_sugar('with', 'Moose');
_test_moose_sugar('with', 'Moose::Role');


sub _test_moose_sugar {
    my ($sugar, $module) = @_;

    my $code = qq<package Foo; use $module; with 'Bar', 'Baz'>;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( $module, qw< Bar Baz > ),
        $code,
    );


    $code = qq<package Foo; use $module; with qw[ Bar Baz ] >;
    cmp_deeply(
        [ modules_used_in_string( $code ) ],
        bag( $module, qw< Bar Baz > ),
        $code,
    );


    TODO: {
        local $TODO = q<Don't handle nested structures yet.>;

        $code = qq<package Foo; use $module; with ( ('Bar'), qw[ Baz ] ) >;
        cmp_deeply(
            [ modules_used_in_string( $code ) ],
            bag( $module, qw< Bar Baz > ),
            $code,
        );
    }

    return;
} # end _test_moose_sugar()


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
