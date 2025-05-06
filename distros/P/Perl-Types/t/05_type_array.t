#!/usr/bin/env perl

# [[[ PRE-HEADER ]]]
# suppress 'WEXRP00: Found multiple perl executables' due to blib/ & pre-existing installation(s)
BEGIN { $ENV{PERL_WARNINGS} = 0; }

# [[[ HEADER ]]]
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.011_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitStringySplit ProhibitInterpolationOfLiterals)  # DEVELOPER DEFAULT 2: allow string test values
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Test::More tests => 232;
#use Test::More tests => 155;  # TMP DEBUG PERLOPS_PERLTYPES & CPPOPS_PERLTYPES
#use Test::More tests => 78;    # TMP DEBUG, ONE MODE ONLY
use Test::Exception;
use Test::Number::Delta;
use Perl::Structure::Array::SubTypes1D qw(arrayref_integer_typetest0 arrayref_integer_typetest1 arrayref_number_typetest0 arrayref_number_typetest1 arrayref_string_typetest0 arrayref_string_typetest1);
use perltypes;  # types_enable()

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag('[[[ Beginning Array Type Pre-Test Loading, Perl Type System ]]]');
    }
    lives_and( sub { use_ok('Perl::Types'); }, q{use_ok('Perl::Types') lives} );
    lives_and( sub { use_ok('Perl::Structure::Array_cpp'); }, q{use_ok('Perl::Structure::Array_cpp') lives} );
}

# [[[ PRIMARY RUNLOOP ]]]
# [[[ PRIMARY RUNLOOP ]]]
# [[[ PRIMARY RUNLOOP ]]]

# loop 3 times, once for each mode: PERLOPS_PERLTYPES, PERLOPS_CPPTYPES, CPPOPS_CPPTYPES
foreach my integer $mode_id ( sort keys %{$Perl::MODES} ) {
#for my $mode_id ( 0 .. 0 ) {  # TMP DEBUG, PERLOPS_PERLTYPES ONLY
#for my $mode_id ( 1 .. 1 ) {  # TMP DEBUG, CPPOPS_PERLTYPES ONLY
#for my $mode_id ( 0 .. 1 ) {  # TMP DEBUG, PERLOPS_PERLTYPES & CPPOPS_PERLTYPES
#for my $mode_id ( 2 .. 2 ) {  # TMP DEBUG, CPPOPS_CPPTYPES ONLY

    # [[[ MODE SETUP ]]]
    #    Perl::diag("in 05_type_array.t, top of for() loop, have \$mode_id = $mode_id\n");
# NEED UPGRADE: allow this array tests file to depend on hash data types for scalartype::hashref below
#    my scalartype::hashref $mode = $Perl::MODES->{$mode_id};
    my $mode = $Perl::MODES->{$mode_id};
    my $ops                 = $mode->{ops};
    my $types               = $mode->{types};
    my string $mode_tagline = $ops . 'OPS_' . $types . 'TYPES';
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag( '[[[ Beginning Perl Array Type Tests, ' . $ops . ' Operations & ' . $types . ' Data Types' . ' ]]]' );
    }

    lives_ok( sub { perltypes::types_enable($types) }, q{mode '} . $ops . ' Operations & ' . $types . ' Data Types' . q{' enabled} );

    if ( $ops eq 'PERL' ) {
        lives_and( sub { use_ok('Perl::Structure::Array'); }, q{use_ok('Perl::Structure::Array') lives} );
    }
    else {
        if ( $types eq 'CPP' ) {

            # force reload
            delete $main::{'Perl__Structure__Array__MODE_ID'};
        }

        # C++ use, load, link
        lives_and( sub { require_ok('Perl::Structure::Array_cpp'); }, q{require_ok('Perl::Structure::Array_cpp') lives} );
        lives_ok( sub { Perl::Structure::Array_cpp::cpp_load(); }, q{Perl::Structure::Array_cpp::cpp_load() lives} );
    }

    foreach my string $type (qw(Type__Integer Type__Number Type__String Structure__Array)) {
        lives_and(
            sub {
                is( $Perl::MODES->{ main->can( 'Perl__' . $type . '__MODE_ID' )->() }->{ops},
                    $ops, 'main::Perl__' . $type . '__MODE_ID() ops returns ' . $ops );
            },
            'main::Perl__' . $type . '__MODE_ID() lives'
        );
        lives_and(
            sub {
                is( $Perl::MODES->{ main->can( 'Perl__' . $type . '__MODE_ID' )->() }->{types},
                    $types, 'main::Perl__' . $type . '__MODE_ID() types returns ' . $types );
            },
            'main::Perl__' . $type . '__MODE_ID() lives'
        );
    }

    # [[[ ARRAY REF INTEGER TESTS ]]]
    # [[[ ARRAY REF INTEGER TESTS ]]]
    # [[[ ARRAY REF INTEGER TESTS ]]]

    throws_ok(    # TAVRVIV00
        sub { arrayref_integer_to_string() },
        "/(EAVRVIV00.*$mode_tagline)|(Usage.*arrayref_integer_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{TAVRVIV00 arrayref_integer_to_string() throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV01
        sub { arrayref_integer_to_string(undef) },
        "/EAVRVIV00.*$mode_tagline/",
        q{TAVRVIV01 arrayref_integer_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV02
        sub { arrayref_integer_to_string(2) },
        "/EAVRVIV01.*$mode_tagline/",
        q{TAVRVIV02 arrayref_integer_to_string(2) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV03
        sub { arrayref_integer_to_string(2.3) },
        "/EAVRVIV01.*$mode_tagline/",
        q{TAVRVIV03 arrayref_integer_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV04
        sub { arrayref_integer_to_string('2') },
        "/EAVRVIV01.*$mode_tagline/",
        q{TAVRVIV04 arrayref_integer_to_string('2') throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV05
        sub { arrayref_integer_to_string( { a_key => 23 } ) },
        "/EAVRVIV01.*$mode_tagline/",
        q{TAVRVIV05 arrayref_integer_to_string({a_key => 23}) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV10
        sub {
            arrayref_integer_to_string( [ 2, 2_112, undef, 23, -877, -33, 1_701 ] );
        },
        "/EAVRVIV02.*$mode_tagline/",
        q{TAVRVIV10 arrayref_integer_to_string([ 2, 2_112, undef, 23, -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV11
        sub {
            arrayref_integer_to_string( [ 2, 2_112, 42, 23.3, -877, -33, 1_701 ] );
        },
        "/EAVRVIV03.*$mode_tagline/",
        q{TAVRVIV11 arrayref_integer_to_string([ 2, 2_112, 42, 23.3, -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV12
        sub {
            arrayref_integer_to_string( [ 2, 2_112, 42, '23', -877, -33, 1_701 ] );
        },
        "/EAVRVIV03.*$mode_tagline/",
        q{TAVRVIV12 arrayref_integer_to_string([ 2, 2_112, 42, '23', -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV13
        sub {
            arrayref_integer_to_string( [ 2, 2_112, 42, [ 23 ], -877, -33, 1_701 ] );
        },
        "/EAVRVIV03.*$mode_tagline/",
        q{TAVRVIV13 arrayref_integer_to_string([ 2, 2_112, 42, [ 23 ], -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVIV14
        sub {
            arrayref_integer_to_string( [ 2, 2_112, 42, { a_subkey => 23 }, -877, -33, 1_701 ] );
        },
        "/EAVRVIV03.*$mode_tagline/",
        q{TAVRVIV14 arrayref_integer_to_string([ 2, 2_112, 42, {a_subkey => 23}, -877, -33, 1_701 ]) throws correct exception}
    );
    lives_and(                                                                 # TAVRVIV20
        sub {
            is( arrayref_integer_to_string( [ 23 ] ), '[ 23 ]', q{TAVRVIV20 arrayref_integer_to_string([ 23 ]) returns correct value} );
        },
        q{TAVRVIV20 arrayref_integer_to_string([ 23 ]) lives}
    );
    lives_and(                                                                 # TAVRVIV21
        sub {
            is( arrayref_integer_to_string( [ 2, 2_112, 42, 23, -877, -33, 1_701 ] ),
                '[ 2, 2_112, 42, 23, -877, -33, 1_701 ]',
                q{TAVRVIV21 arrayref_integer_to_string([ 2, 2_112, 42, 23, -877, -33, 1_701 ]) returns correct value}
            );
        },
        q{TAVRVIV21 arrayref_integer_to_string([ 2, 2_112, 42, 23, -877, -33, 1_701 ]) lives}
    );
    throws_ok(                                                                 # TAVRVIV30
        sub { arrayref_integer_typetest0() },
        "/(EAVRVIV00.*$mode_tagline)|(Usage.*arrayref_integer_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{TAVRVIV30 arrayref_integer_typetest0() throws correct exception}
    );
    throws_ok(                                                                  # TAVRVIV31
        sub { arrayref_integer_typetest0(2) },
        "/EAVRVIV01.*$mode_tagline/",
        q{TAVRVIV31 arrayref_integer_typetest0(2) throws correct exception}
    );
    throws_ok(                                                                  # TAVRVIV32
        sub {
            arrayref_integer_typetest0( [ 2, 2_112, undef, 23, -877, -33, 1_701 ] );
        },
        "/EAVRVIV02.*$mode_tagline/",
        q{TAVRVIV32 arrayref_integer_typetest0([ 2, 2_112, undef, 23, -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                  # TAVRVIV33
        sub {
            arrayref_integer_typetest0( [ 2, 2_112, 42, 'abcdefg', -877, -33, 1_701 ] );
        },
        "/EAVRVIV03.*$mode_tagline/",
        q{TAVRVIV33 arrayref_integer_typetest0([ 2, 2_112, 42, 'abcdefg', -877, -33, 1_701 ]) throws correct exception}
    );
    lives_and(                                                                  # TAVRVIV34
        sub {
            is( arrayref_integer_typetest0( [ 2, 2_112, 42, 23, -877, -33, 1_701 ] ),
                '[ 2, 2_112, 42, 23, -877, -33, 1_701 ]' . $mode_tagline,
                q{TAVRVIV34 arrayref_integer_typetest0([ 2, 2_112, 42, 23, -877, -33, 1_701 ]) returns correct value}
            );
        },
        q{TAVRVIV34 arrayref_integer_typetest0([ 2, 2_112, 42, 23, -877, -33, 1_701 ]) lives}
    );
    lives_and(                                                                  # TAVRVIV40
        sub {
            is_deeply( arrayref_integer_typetest1(5), [ 0, 5, 10, 15, 20 ], q{TAVRVIV40 arrayref_integer_typetest1(5) returns correct value} );
        },
        q{TAVRVIV40 arrayref_integer_typetest1(5) lives}
    );

    # [[[ ARRAY REF NUMBER TESTS ]]]
    # [[[ ARRAY REF NUMBER TESTS ]]]
    # [[[ ARRAY REF NUMBER TESTS ]]]

    throws_ok(    # TAVRVNV00
        sub { arrayref_number_to_string() },
        "/(EAVRVNV00.*$mode_tagline)|(Usage.*arrayref_number_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{TAVRVNV00 arrayref_number_to_string() throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV01
        sub { arrayref_number_to_string(undef) },
        "/EAVRVNV00.*$mode_tagline/",
        q{TAVRVNV01 arrayref_number_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV02
        sub { arrayref_number_to_string(2) },
        "/EAVRVNV01.*$mode_tagline/",
        q{TAVRVNV02 arrayref_number_to_string(2) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV03
        sub { arrayref_number_to_string(2.3) },
        "/EAVRVNV01.*$mode_tagline/",
        q{TAVRVNV03 arrayref_number_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV04
        sub { arrayref_number_to_string('2') },
        "/EAVRVNV01.*$mode_tagline/",
        q{TAVRVNV04 arrayref_number_to_string('2') throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV05
        sub { arrayref_number_to_string( { a_key => 23 } ) },
        "/EAVRVNV01.*$mode_tagline/",
        q{TAVRVNV05 arrayref_number_to_string({a_key => 23}) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV10
        sub {
            arrayref_number_to_string( [ 2, 2_112, undef, 23, -877, -33, 1_701 ] );
        },
        "/EAVRVNV02.*$mode_tagline/",
        q{TAVRVNV10 arrayref_number_to_string([ 2, 2_112, undef, 23, -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV11
        sub {
            arrayref_number_to_string( [ 2, 2_112, 42, '23', -877, -33, 1_701 ] );
        },
        "/EAVRVNV03.*$mode_tagline/",
        q{TAVRVNV11 arrayref_number_to_string([ 2, 2_112, 42, '23', -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV12
        sub {
            arrayref_number_to_string( [ 2, 2_112, 42, [ 23 ], -877, -33, 1_701 ] );
        },
        "/EAVRVNV03.*$mode_tagline/",
        q{TAVRVNV12 arrayref_number_to_string([ 2, 2_112, 42, [ 23 ], -877, -33, 1_701 ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVNV13
        sub {
            arrayref_number_to_string( [ 2, 2_112, 42, { a_subkey => 23 }, -877, -33, 1_701 ] );
        },
        "/EAVRVNV03.*$mode_tagline/",
        q{TAVRVNV13 arrayref_number_to_string([ 2, 2_112, 42, {a_subkey => 23}, -877, -33, 1_701 ]) throws correct exception}
    );
    lives_and(                                                                # TAVRVNV20
        sub {
            is( arrayref_number_to_string( [ 23 ] ), '[ 23 ]', q{TAVRVNV20 arrayref_number_to_string([ 23 ]) returns correct value} );
        },
        q{TAVRVNV20 arrayref_number_to_string([ 23 ]) lives}
    );
    lives_and(                                                                # TAVRVNV21
        sub {
            is( arrayref_number_to_string( [ 2, 2_112, 42, 23, -877, -33, 1_701 ] ),
                '[ 2, 2_112, 42, 23, -877, -33, 1_701 ]',
                q{TAVRVNV21 arrayref_number_to_string([ 2, 2_112, 42, 23, -877, -33, 1_701 ]) returns correct value}
            );
        },
        q{TAVRVNV21 arrayref_number_to_string([ 2, 2_112, 42, 23, -877, -33, 1_701 ]) lives}
    );
    lives_and(                                                                # TAVRVNV22
        sub {
            is( arrayref_number_to_string( [ 23.2 ] ), '[ 23.2 ]', q{TAVRVNV22 arrayref_number_to_string([ 23.2 ]) returns correct value} );
        },
        q{TAVRVNV22 arrayref_number_to_string([ 23.2 ]) lives}
    );
    lives_and(                                                                # TAVRVNV23
        sub {
            is( arrayref_number_to_string( [ 2.1, 2_112.2, 42.3, 23, -877, -33, 1_701 ] ),
                '[ 2.1, 2_112.2, 42.3, 23, -877, -33, 1_701 ]',
                q{TAVRVNV23 arrayref_number_to_string([ 2.1, 2_112.2, 42.3, 23, -877, -33, 1_701 ]) returns correct value}
            );
        },
        q{TAVRVNV23 arrayref_number_to_string([ 2.1, 2_112.2, 42.3, 23, -877, -33, 1_701 ]) lives}
    );

    # NEED DELETE OLD CODE
#    lives_and(                                                                # TAVRVNV24
#        sub {
#            is( arrayref_number_to_string( [ 2.123_443_211_234_432_1, 2_112.432_1, 42.456_7, 23.765_444_444_444_444_444, -877.567_8, -33.876_587_658_765_875_687_658_765, 1_701.678_9 ] ),
#                '[ 2.123_443_211_234_43, 2_112.432_1, 42.456_7, 23.765_444_444_444_4, -877.567_8, -33.876_587_658_765_9, 1_701.678_9 ]',
#                q{TAVRVNV24 arrayref_number_to_string([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value}
#            );
#        },
#        q{TAVRVNV24 arrayref_number_to_string([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) lives}
#    );

    lives_and(                                                                 # TAVRVNV24
        sub {
            my string $tmp_retval = arrayref_number_to_string( [ 2.123_443_211_234_432_1, 2_112.432_1, 42.456_7, 23.765_444_444_444_444_444, -877.567_8, -33.876_587_658_765_875_687_658_765, 1_701.678_9 ] );
            like(
                $tmp_retval,
                qr/\[ 2\.123_443_211/,
                q{TAVRVNV24a arrayref_number_to_string([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value, array beginning}
            );
            like(
                $tmp_retval,
                qr/, 1_701\.678_9 \]/,
                q{TAVRVNV24b arrayref_number_to_string([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value, array end}
            );
        },
        q{TAVRVNV24 arrayref_number_to_string([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) lives}
    );

    throws_ok(                                                                # TAVRVNV30
        sub { arrayref_number_typetest0() },
        "/(EAVRVNV00.*$mode_tagline)|(Usage.*arrayref_number_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{TAVRVNV30 arrayref_number_typetest0() throws correct exception}
    );
    throws_ok(                                                                 # TAVRVNV31
        sub { arrayref_number_typetest0(2) },
        "/EAVRVNV01.*$mode_tagline/",
        q{TAVRVNV31 arrayref_number_typetest0(2) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVNV32
        sub {
            arrayref_number_typetest0( [ 2.123_443_211_234_432_1, 2_112.432_1, undef, 23.765_444_444_444_444_444, -877.567_8, -33.876_587_658_765_875_687_658_765, 1_701.678_9 ] );
        },
        "/EAVRVNV02.*$mode_tagline/",
        q{TAVRVNV32 arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, undef, 23.765_444_444_444_444_444, ..., 1_701.678_9 ]) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVNV33
        sub {
            arrayref_number_typetest0(
                [ 2.123_443_211_234_432_1, 2_112.432_1, 42.456_7, 23.765_444_444_444_444_444, -877.567_8, 'abcdefg', -33.876_587_658_765_875_687_658_765, 1_701.678_9 ] );
        },
        "/EAVRVNV03.*$mode_tagline/",
        q{TAVRVNV33 arrayref_number_typetest0([ 2.123_443_211_234_432_1, ..., 'abcdefg', -33.876_587_658_765_875_687_658_765, 1_701.678_9 ]) throws correct exception}
    );
    
    # NEED DELETE OLD CODE
#    lives_and(                                                                 # TAVRVNV34
#        sub {
#            is( 
#                arrayref_number_typetest0( [ 2.123_443_211_234_432_1, 2_112.432_1, 42.456_7, 23.765_444_444_444_444_444, -877.567_8, -33.876_587_658_765_875_687_658_765, 1_701.678_9 ] ),
#                '[ 2.123_443_211_234_43, 2_112.432_1, 42.456_7, 23.765_444_444_444_4, -877.567_8, -33.876_587_658_765_9, 1_701.678_9 ]' . $mode_tagline,
#                q{TAVRVNV34 arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value}
#            );
#        },
#        q{TAVRVNV34 arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) lives}
#    );
    lives_and(                                                                 # TAVRVNV34
        sub {
            my string $tmp_retval = arrayref_number_typetest0( [ 2.123_443_211_234_432_1, 2_112.432_1, 42.456_7, 23.765_444_444_444_444_444, -877.567_8, -33.876_587_658_765_875_687_658_765, 1_701.678_9 ] );
            like(
                $tmp_retval,
                qr/\[ 2\.123_443_211/,
                q{TAVRVNV34a arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value, array beginning}
            );
            like(
                $tmp_retval,
                qr/, 1_701\.678_9 \]/,
                q{TAVRVNV34b arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value, array end}
            );
            like(
                $tmp_retval,
                qr/$mode_tagline/,
                q{TAVRVNV34c arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) returns correct value, mode tagline}
            );
        },
        q{TAVRVNV34 arrayref_number_typetest0([ 2.123_443_211_234_432_1, 2_112.432_1, ..., 1_701.678_9 ]) lives}
    );

    lives_and(                                                                 # TAVRVNV40
        sub {
            # NEED DELETE OLD CODE
#            is_deeply(
            delta_ok(
                arrayref_number_typetest1(5),
                [ 0, 5.123456789, 10.246913578, 15.370370367, 20.493827156 ]
                ,                                                              ## PERLTIDY BUG comma on newline
                q{TAVRVNV40 arrayref_number_typetest1(5) returns correct value}
            );
        },
        q{TAVRVNV40 arrayref_number_typetest1(5) lives}
    );

    # [[[ ARRAY REF STRING TESTS ]]]
    # [[[ ARRAY REF STRING TESTS ]]]
    # [[[ ARRAY REF STRING TESTS ]]]

    throws_ok(    # TAVRVPV00
        sub { arrayref_string_to_string() },
        "/(EAVRVPV00.*$mode_tagline)|(Usage.*arrayref_string_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{TAVRVPV00 arrayref_string_to_string() throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV01
        sub { arrayref_string_to_string(undef) },
        "/EAVRVPV00.*$mode_tagline/",
        q{TAVRVPV01 arrayref_string_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV02
        sub { arrayref_string_to_string(2) },
        "/EAVRVPV01.*$mode_tagline/",
        q{TAVRVPV02 arrayref_string_to_string(2) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV03
        sub { arrayref_string_to_string(2.3) },
        "/EAVRVPV01.*$mode_tagline/",
        q{TAVRVPV03 arrayref_string_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV04
        sub { arrayref_string_to_string('Lone Ranger') },
        "/EAVRVPV01.*$mode_tagline/",
        q{TAVRVPV04 arrayref_string_to_string('Lone Ranger') throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV05
        sub { arrayref_string_to_string( { a_key => 'Lone Ranger' } ) },
        "/EAVRVPV01.*$mode_tagline/",
        q{TAVRVPV05 arrayref_string_to_string({a_key => 'Lone Ranger'}) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV10
        sub {
            arrayref_string_to_string( [ 'Superman', 'Batman', 'Wonder Woman', undef, 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] );
        },
        "/EAVRVPV02.*$mode_tagline/",
        q{TAVRVPV10 arrayref_string_to_string([ 'Superman', 'Batman', 'Wonder Woman', undef, 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV11
        sub {
            arrayref_string_to_string( [ 'Superman', 'Batman', 23, 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] );
        },
        "/EAVRVPV03.*$mode_tagline/",
        q{TAVRVPV11 arrayref_string_to_string([ 'Superman', 'Batman', 23, 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV12
        sub {
            arrayref_string_to_string( [ 'Superman', 'Batman', 23.2, 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] );
        },
        "/EAVRVPV03.*$mode_tagline/",
        q{TAVRVPV12 arrayref_string_to_string([ 'Superman', 'Batman', 23.2, 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV13
        sub {
            arrayref_string_to_string( [ 'Superman', 'Batman', ['Wonder Woman'], 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] );
        },
        "/EAVRVPV03.*$mode_tagline/",
        q{TAVRVPV13 arrayref_string_to_string([ 'Superman', 'Batman', ['Wonder Woman'], 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) throws correct exception}
    );
    throws_ok(                                                                # TAVRVPV14
        sub {
            arrayref_string_to_string( [ 'Superman', 'Batman', { a_subkey => 'Wonder Woman' }, 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] );
        },
        "/EAVRVPV03.*$mode_tagline/",
        q{TAVRVPV14 arrayref_string_to_string([ 'Superman', 'Batman', {a_subkey => 'Wonder Woman'}, ..., 'Martian Manhunter' ]) throws correct exception}
    );
    lives_and(                                                                # TAVRVPV20
        sub {
            is( arrayref_string_to_string(
                    [ 'Howard The Duck', 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]
                ),
                q{[ 'Howard The Duck', 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]},
                q{TAVRVPV20 arrayref_string_to_string([ 'Howard The Duck', 'Superman', 'Batman', 'Wonder Woman', ..., 'Martian Manhunter' ]) returns correct value}
            );
        },
        q{TAVRVPV20 arrayref_string_to_string([ 'Howard The Duck', 'Superman', 'Batman', 'Wonder Woman', ..., 'Martian Manhunter' ]) lives}
    );
    lives_and(                                                                # TAVRVPV21
        sub {
            is( arrayref_string_to_string( [ 'Superman', 'Martian Manhunter', 'undef' ] ),
                q{[ 'Superman', 'Martian Manhunter', 'undef' ]},
                q{TAVRVPV21 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', 'undef' ]) returns correct value}
            );
        },
        q{TAVRVPV21 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', 'undef' ]) lives}
    );
    lives_and(                                                                # TAVRVPV22
        sub {
            is( arrayref_string_to_string( [ 'Superman', 'Martian Manhunter', '23' ] ),
                q{[ 'Superman', 'Martian Manhunter', '23' ]},
                q{TAVRVPV22 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', '23' ]) returns correct value}
            );
        },
        q{TAVRVPV22 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', '23' ]) lives}
    );
    lives_and(                                                                # TAVRVPV23
        sub {
            is( arrayref_string_to_string( [ 'Superman', 'Martian Manhunter', '-2_112.23' ] ),
                q{[ 'Superman', 'Martian Manhunter', '-2_112.23' ]},
                q{TAVRVPV23 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', '-2_112.23' ]) returns correct value}
            );
        },
        q{TAVRVPV23 arrayref_string_to_string([ 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter', '-2_112.23' ]) lives}
    );
    lives_and(                                                                # TAVRVPV24
        sub {
            is( arrayref_string_to_string( [ 'Superman', 'Martian Manhunter', "[\\'Tonto'\\]" ] ),
                q{[ 'Superman', 'Martian Manhunter', '[\\\\\'Tonto\'\\\\]' ]},
                q{TAVRVPV24 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', "[\\'Tonto'\\]" ]) returns correct value}
            );
        },
        q{TAVRVPV24 arrayref_string_to_string([ 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', "Martian Manhunter", "-2_112.23" ]) lives}
    );
    lives_and(                                                                # TAVRVPV25
        sub {
            is( arrayref_string_to_string( [ 'Superman', 'Martian Manhunter', '{buzz => 5}' ] ),
                q{[ 'Superman', 'Martian Manhunter', '{buzz => 5}' ]},
                q{TAVRVPV25 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', '{buzz => 5}' ]) returns correct value}
            );
        },
        q{TAVRVPV25 arrayref_string_to_string([ 'Superman', 'Martian Manhunter', '{buzz => 5}' ]) lives}
    );
    throws_ok(                                                                # TAVRVPV30
        sub { arrayref_string_typetest0() },
        "/(EAVRVPV00.*$mode_tagline)|(Usage.*arrayref_string_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{TAVRVPV30 arrayref_string_typetest0() throws correct exception}
    );
    throws_ok(                                                                 # TAVRVPV31
        sub { arrayref_string_typetest0(2) },
        "/EAVRVPV01.*$mode_tagline/",
        q{TAVRVPV31 arrayref_string_typetest0(2) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVPV32
        sub {
            arrayref_string_typetest0( [ 'Superman', 'Batman', 'Wonder Woman', undef, 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] );
        },
        "/EAVRVPV02.*$mode_tagline/",
        q{TAVRVPV32 arrayref_string_typetest0([ 'Superman', 'Batman', 'Wonder Woman', undef, 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) throws correct exception}
    );
    throws_ok(                                                                 # TAVRVPV33
        sub {
            arrayref_string_typetest0( [ 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter', [ 23, -42.3 ] ] );
        },
        "/EAVRVPV03.*$mode_tagline/",
        q{TAVRVPV33 arrayref_string_typetest0([ 'Superman', 'Batman', 'Wonder Woman', ..., 'Martian Manhunter', [ 23, -42.3 ] ]) throws correct exception}
    );
    lives_and(                                                                 # TAVRVPV34
        sub {
            is( arrayref_string_typetest0( [ 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ] ),
                q{[ 'Superman', 'Batman', 'Wonder Woman', 'Flash', 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]} . $mode_tagline,
                q{TAVRVPV34 arrayref_string_typetest0([ 'Superman', ..., 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) returns correct value}
            );
        },
        q{TAVRVPV34 arrayref_string_typetest0([ 'Superman', ..., 'Green Lantern', 'Aquaman', 'Martian Manhunter' ]) lives}
    );
    lives_and(                                                                 # TAVRVPV40
        sub {
            is_deeply(
                arrayref_string_typetest1(5),
                [   'Jeffy Ten! 0/4 ' . $mode_tagline,
                    'Jeffy Ten! 1/4 ' . $mode_tagline,
                    'Jeffy Ten! 2/4 ' . $mode_tagline,
                    'Jeffy Ten! 3/4 ' . $mode_tagline,
                    'Jeffy Ten! 4/4 ' . $mode_tagline,
                ],
                q{TAVRVPV40 arrayref_string_typetest1(5) returns correct value}
            );
        },
        q{TAVRVPV40 arrayref_string_typetest1(5) lives}
    );
}

done_testing();
