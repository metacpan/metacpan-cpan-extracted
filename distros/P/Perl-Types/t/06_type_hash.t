# [[[ PRE-HEADER ]]]
# suppress 'WEXRP00: Found multiple perl executables' due to blib/ & pre-existing installation(s)
BEGIN { $ENV{PERL_WARNINGS} = 0; }

# [[[ HEADER ]]]
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.015_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitStringySplit ProhibitInterpolationOfLiterals)  # DEVELOPER DEFAULT 2: allow string test values
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Test::More tests => 495;
use Test::Exception;
use Test::Number::Delta;
use Perl::Structure::Hash::SubTypes1D qw(hashref_integer_typetest0 hashref_integer_typetest1 hashref_number_typetest0 hashref_number_typetest1 hashref_string_typetest0 hashref_string_typetest1);
use Perl::Structure::Hash::SubTypes2D qw(hashref_arrayref_integer_typetest0 hashref_arrayref_integer_typetest1 hashref_arrayref_number_typetest0 hashref_arrayref_number_typetest1 hashref_arrayref_string_typetest0 hashref_arrayref_string_typetest1);
use perltypes;  # types_enable()

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag('[[[ Beginning Hash Type Pre-Test Loading, Perl Type System ]]]');
    }
    lives_and( sub { use_ok('Perl::Structure::Hash_cpp'); }, q{use_ok('Perl::Structure::Hash_cpp') lives} );
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
    #    Perl::diag("in 06_type_hash.t, top of for() loop, have \$mode_id = $mode_id\n");
    my hashref::scalartype $mode = $Perl::MODES->{$mode_id};
    my $ops                     = $mode->{ops};
    my $types                   = $mode->{types};
    my string $mode_tagline     = $ops . 'OPS_' . $types . 'TYPES';
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag( '[[[ Beginning Perl Hash Type Tests, ' . $ops . ' Operations & ' . $types . ' Data Types' . ' ]]]' );
    }

    lives_ok( sub { perltypes::types_enable($types) }, q{mode '} . $ops . ' Operations & ' . $types . ' Data Types' . q{' enabled} );

    if ( $ops eq 'PERL' ) {
        lives_and( sub { use_ok('Perl::Structure::Hash'); }, q{use_ok('Perl::Structure::Hash') lives} );
    }
    else {
        if ( $types eq 'CPP' ) {

            # force reload
            delete $main::{'Perl__Structure__Hash__MODE_ID'};
        }

        # C++ use, load, link
        lives_and( sub { require_ok('Perl::Structure::Hash_cpp'); }, q{require_ok('Perl::Structure::Hash_cpp') lives} );
        lives_ok( sub { Perl::Structure::Hash_cpp::cpp_load(); }, q{Perl::Structure::Hash_cpp::cpp_load() lives} );
    }

    foreach my string $type (qw(Type__Integer Type__Number Type__String Structure__Hash)) {
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

    # [[[ HASH REF INTEGER TESTS ]]]
    # [[[ HASH REF INTEGER TESTS ]]]
    # [[[ HASH REF INTEGER TESTS ]]]

    throws_ok(    # THVRVIV00
        sub { hashref_integer_to_string() },
        "/(EHVRVIV00.*$mode_tagline)|(Usage.*hashref_integer_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVIV00 hashref_integer_to_string() throws correct exception}
    );
    throws_ok(                                                                # THVRVIV01
        sub { hashref_integer_to_string(undef) },
        "/EHVRVIV00.*$mode_tagline/",
        q{THVRVIV01 hashref_integer_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                # THVRVIV02
        sub { hashref_integer_to_string(2) },
        "/EHVRVIV01.*$mode_tagline/",
        q{THVRVIV02 hashref_integer_to_string(2) throws correct exception}
    );
    throws_ok(                                                                # THVRVIV03
        sub { hashref_integer_to_string(2.3) },
        "/EHVRVIV01.*$mode_tagline/",
        q{THVRVIV03 hashref_integer_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                # THVRVIV04
        sub { hashref_integer_to_string('2') },
        "/EHVRVIV01.*$mode_tagline/",
        q{THVRVIV04 hashref_integer_to_string('2') throws correct exception}
    );
    throws_ok(                                                                # THVRVIV05
        sub { hashref_integer_to_string([ 2 ]) },
        "/EHVRVIV01.*$mode_tagline/",
        q{THVRVIV05 hashref_integer_to_string([ 2 ]) throws correct exception}
    );
    throws_ok(                                                                # THVRVIV10
        sub {
            hashref_integer_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => undef,
                    d_key => 23,
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVIV02.*$mode_tagline/",
        q{THVRVIV10 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => undef, d_key => 23, e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVIV11
        sub {
            hashref_integer_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42,
                    d_key => 23.3,
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVIV03.*$mode_tagline/",
        q{THVRVIV11 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => 23.3, e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVIV12
        sub {
            hashref_integer_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42,
                    d_key => '23',
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVIV03.*$mode_tagline/",
        q{THVRVIV12 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => '23', e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVIV13
        sub {
            hashref_integer_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42,
                    d_key => [ 23 ],
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVIV03.*$mode_tagline/",
        q{THVRVIV13 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => [ 23 ], e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVIV14
        sub {
            hashref_integer_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42,
                    d_key => { a_subkey => 23 },
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVIV03.*$mode_tagline/",
#        q{THVRVIV14 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => {a_subkey => 23}, e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
        q{THVRVIV14 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => {a_subkey => 23}, ..., g_key => 1_701 }) throws correct exception}
    );
    lives_and(    # THVRVIV20
        sub {
            is( hashref_integer_to_string( { a_key => 23 } ), q{{ 'a_key' => 23 }}, q{THVRVIV20 hashref_integer_to_string({ a_key => 23 }) returns correct value} );
        },
        q{THVRVIV20 hashref_integer_to_string({ a_key => 23 }) lives}
    );
    lives_and(    # THVRVIV21
        sub {
            like(
                hashref_integer_to_string(
                    {   a_key => 2,
                        b_key => 2_112,
                        c_key => 42,
                        d_key => 23,
                        e_key => -877,
                        f_key => -33,
                        g_key => 1_701
                    }
                ),

             # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
                q{/^\\\{\s(?=.*'a_key' => 2\b)(?=.*'b_key' => 2_112\b)(?=.*'c_key' => 42\b)(?=.*'d_key' => 23\b)(?=.*'e_key' => -877\b)(?=.*'f_key' => -33\b)(?=.*'g_key' => 1_701\b).*\s\}$/m},
                q{THVRVIV21 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => 23, e_key => -877, f_key => -33, g_key => 1_701 }) returns correct value}
            );
        },
        q{THVRVIV21 hashref_integer_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => 23, e_key => -877, f_key => -33, g_key => 1_701 }) lives}
    );
    throws_ok(    # THVRVIV30
        sub { hashref_integer_typetest0() },
        "/(EHVRVIV00.*$mode_tagline)|(Usage.*hashref_integer_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVIV30 hashref_integer_typetest0() throws correct exception}
    );
    throws_ok(                                                                 # THVRVIV31
        sub { hashref_integer_typetest0(2) },
        "/EHVRVIV01.*$mode_tagline/",
        q{THVRVIV31 hashref_integer_typetest0(2) throws correct exception}
    );
    throws_ok(                                                                 # THVRVIV32
        sub {
            hashref_integer_typetest0(
                {   'binary'       => 2,
                    'rush'         => 2_112,
                    'ERROR_FUNKEY' => undef,
                    'answer'       => 42,
                    'fnord'        => 23,
                    'units'        => -877,
                    'degree'       => -33,
                    'ncc'          => 1_701
                }
            );
        },
        "/EHVRVIV02.*$mode_tagline/",
        q{THVRVIV32 hashref_integer_typetest0({ 'binary' => 2, 'rush' => 2_112, 'ERROR_FUNKEY' => undef, ..., 'ncc' => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVIV33
        sub {
            hashref_integer_typetest0(
                {   'binary'       => 2,
                    'rush'         => 2_112,
                    'ERROR_FUNKEY' => 'abcdefg',
                    'answer'       => 42,
                    'fnord'        => 23,
                    'units'        => -877,
                    'degree'       => -33,
                    'ncc'          => 1_701
                }
            );
        },
        "/EHVRVIV03.*$mode_tagline/",
        q{THVRVIV33 hashref_integer_typetest0({ 'binary' => 2, 'rush' => 2_112, 'ERROR_FUNKEY' => 'abcdefg', ..., 'ncc' => 1_701 }) throws correct exception}
    );
    lives_and(    # THVRVIV34
        sub {
            like(
                hashref_integer_typetest0(
                    {   'binary' => 2,
                        'rush'   => 2_112,
                        'answer' => 42,
                        'fnord'  => 23,
                        'units'  => -877,
                        'degree' => -33,
                        'ncc'    => 1_701
                    }
                ),
                q{/^\\\{\s(?=.*'binary' => 2\b)(?=.*'rush' => 2_112\b)(?=.*'answer' => 42\b)(?=.*'fnord' => 23\b)(?=.*'units' => -877\b)(?=.*'degree' => -33\b)(?=.*'ncc' => 1_701\b).*\s\}}
                    . $mode_tagline . q{$/m},

#                q{THVRVIV34 hashref_integer_typetest0({ 'binary' => 2, 'rush' => 2_112, 'answer' => 42, 'fnord' => 23, 'units' => -877, 'degree' => -33, 'ncc' => 1_701 }) returns correct value}
                q{THVRVIV34 hashref_integer_typetest0({ 'binary' => 2, 'rush' => 2_112, ..., 'ncc' => 1_701 }) returns correct value}
            );
        },
        q{THVRVIV34 hashref_integer_typetest0({ 'binary' => 2, 'rush' => 2_112, ..., 'ncc' => 1_701 }) lives}
    );
    lives_and(    # THVRVIV40
        sub {
            is_deeply(
                hashref_integer_typetest1(5),
                {   "$mode_tagline\_funkey2" => 10,
                    "$mode_tagline\_funkey3" => 15,
                    "$mode_tagline\_funkey4" => 20,
                    "$mode_tagline\_funkey1" => 5,
                    "$mode_tagline\_funkey0" => 0
                },
                q{THVRVIV40 hashref_integer_typetest1(5) returns correct value}
            );
        },
        q{THVRVIV40 hashref_integer_typetest1(5) lives}
    );

    # [[[ HASH NUMBER REF TESTS ]]]
    # [[[ HASH NUMBER REF TESTS ]]]
    # [[[ HASH NUMBER REF TESTS ]]]

    throws_ok(    # THVRVNV00
        sub { hashref_number_to_string() },
        "/(EHVRVNV00.*$mode_tagline)|(Usage.*hashref_number_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVNV00 hashref_number_to_string() throws correct exception}
    );
    throws_ok(                                                               # THVRVNV01
        sub { hashref_number_to_string(undef) },
        "/EHVRVNV00.*$mode_tagline/",
        q{THVRVNV01 hashref_number_to_string(undef) throws correct exception}
    );
    throws_ok(                                                               # THVRVNV02
        sub { hashref_number_to_string(2) },
        "/EHVRVNV01.*$mode_tagline/",
        q{THVRVNV02 hashref_number_to_string(2) throws correct exception}
    );
    throws_ok(                                                               # THVRVNV03
        sub { hashref_number_to_string(2.3) },
        "/EHVRVNV01.*$mode_tagline/",
        q{THVRVNV03 hashref_number_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                               # THVRVNV04
        sub { hashref_number_to_string('2') },
        "/EHVRVNV01.*$mode_tagline/",
        q{THVRVNV04 hashref_number_to_string('2') throws correct exception}
    );
    throws_ok(                                                               # THVRVNV05
        sub { hashref_number_to_string([ 2 ]) },
        "/EHVRVNV01.*$mode_tagline/",
        q{THVRVNV05 hashref_number_to_string([ 2 ]) throws correct exception}
    );
    throws_ok(                                                               # THVRVNV10
        sub {
            hashref_number_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => undef,
                    d_key => 23,
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVNV02.*$mode_tagline/",
        q{THVRVNV10 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => undef, d_key => 23, e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVNV11
        sub {
            hashref_number_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42.3,
                    d_key => '23',
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVNV03.*$mode_tagline/",
        q{THVRVNV11 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => 42.3, d_key => '23', e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVNV12
        sub {
            hashref_number_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42.3,
                    d_key => [ 23 ],
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVNV03.*$mode_tagline/",
        q{THVRVNV12 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => 42.3, d_key => [ 23 ], e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
    );
    throws_ok(    # THVRVNV13
        sub {
            hashref_number_to_string(
                {   a_key => 2,
                    b_key => 2_112,
                    c_key => 42.3,
                    d_key => { a_subkey => 23 },
                    e_key => -877,
                    f_key => -33,
                    g_key => 1_701
                }
            );
        },
        "/EHVRVNV03.*$mode_tagline/",

#        q{THVRVNV13 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => 42.3, d_key => {a_subkey => 23}, e_key => -877, f_key => -33, g_key => 1_701 }) throws correct exception}
        q{THVRVNV13 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => 42.3, d_key => {a_subkey => 23}, ..., g_key => 1_701 }) throws correct exception}
    );
    lives_and(    # THVRVNV20
        sub {
            is( hashref_number_to_string( { a_key => 23 } ), q{{ 'a_key' => 23 }}, q{THVRVNV20 hashref_number_to_string({a_key => 23}) returns correct value} );
        },
        q{THVRVNV20 hashref_number_to_string({ a_key => 23 }) lives}
    );
    lives_and(    # THVRVNV21
        sub {
            like(
                hashref_number_to_string(
                    {   a_key => 2,
                        b_key => 2_112,
                        c_key => 42,
                        d_key => 23,
                        e_key => -877,
                        f_key => -33,
                        g_key => 1_701
                    }
                ),

                q{/^\\\{\s(?=.*'a_key' => 2\b)(?=.*'b_key' => 2_112\b)(?=.*'c_key' => 42\b)(?=.*'d_key' => 23\b)(?=.*'e_key' => -877\b)(?=.*'f_key' => -33\b)(?=.*'g_key' => 1_701\b).*\s\}$/m},
                q{THVRVNV21 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => 23, e_key => -877, f_key => -33, g_key => 1_701 }) returns correct value}
            );
        },
        q{THVRVNV21 hashref_number_to_string({ a_key => 2, b_key => 2_112, c_key => 42, d_key => 23, e_key => -877, f_key => -33, g_key => 1_701 }) lives}
    );
    lives_and(    # THVRVNV22
        sub {
            like(
                hashref_number_to_string( { a_key => 2.123_443_211_234_432_1 } ),
                qr/\{\s'a_key' => 2\.123_443_211_234/,
                q{THVRVNV22 hashref_number_to_string({ a_key => 2.123_443_211_234_432_1 }) returns correct value}
            );
        },
        q{THVRVNV22 hashref_number_to_string({ a_key => 2.123_443_211_234_432_1 }) lives}
    );
    lives_and(    # THVRVNV23
        sub {
            like(
                hashref_number_to_string(
                    {   a_key => 2.123_443_211_234_432_1,
                        b_key => 2_112.432_1,
                        c_key => 42.456_7,
                        d_key => 23.765_444_444_444_444_444,
                        e_key => -877.567_8,
                        f_key => -33.876_587_658_765_875_687_658_765,
                        g_key => 1_701.678_9
                    }
                ),

                q{/^\\\{\s(?=.*'a_key' => 2\.123_443_211_234)(?=.*'b_key' => 2_112\.432_1)(?=.*'c_key' => 42\.456_7)(?=.*'d_key' => 23\.765_444_444_44)(?=.*'e_key' => -877\.567_8)(?=.*'f_key' => -33\.876_587_658_76)(?=.*'g_key' => 1_701\.678_9).*\s\}$/m},

#                q{THVRVNV23 hashref_number_to_string({ a_key => 2.123_443_211_234_432_1, b_key => 2_112.432_1, c_key => 42.456_7, d_key => 23.765_444_444_444_444_444, e_key => -877.567_8, f_key => -33.876_587_658_765_875_687_658_765, g_key => 1_701.678_9 }) returns correct value}
                q{THVRVNV23 hashref_number_to_string({ a_key => 2.123_443_211_234_432_1, b_key => 2_112.432_1, c_key => 42.456_7, ..., g_key => 1_701.678_9 }) returns correct value}
            );
        },
        q{THVRVNV23 hashref_number_to_string({ a_key => 2.123_443_211_234_432_1, b_key => 2_112.432_1, c_key => 42.456_7, d_key => 23.765_444_444_444_444_444, e_key => -877.567_8, f_key => -33.876_587_658_765_875_687_658_765, g_key => 1_701.678_9 }) lives}
    );
    throws_ok(    # THVRVNV30
        sub { hashref_number_typetest0() },
        "/(EHVRVNV00.*$mode_tagline)|(Usage.*hashref_number_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVNV30 hashref_number_typetest0() throws correct exception}
    );
    throws_ok(                                                                # THVRVNV31
        sub { hashref_number_typetest0(2) },
        "/EHVRVNV01.*$mode_tagline/",
        q{THVRVNV31 hashref_number_typetest0(2) throws correct exception}
    );
    throws_ok(                                                                # THVRVNV32
        sub {
            hashref_number_typetest0(
                {   'binary'       => 2.123_443_211_234_432_1,
                    'rush'         => 2_112.432_1,
                    'ERROR_FUNKEY' => undef,
                    'answer'       => 42.456_7,
                    'fnord'        => 23.765_444_444_444_444_444,
                    'units'        => -877.567_8,
                    'degree'       => -33.876_587_658_765_875_687_658_765,
                    'ncc'          => 1_701.678_9
                }
            );
        },
        "/EHVRVNV02.*$mode_tagline/",
        q{THVRVNV32 hashref_number_typetest0({ 'binary' => 2.123_443_211_234_432_1, 'ERROR_FUNKEY' => undef, ..., 'ncc' => 1_701.678_9 }) throws correct exception}
    );
    throws_ok(    # THVRVNV33
        sub {
            hashref_number_typetest0(
                {   'binary'       => 2.123_443_211_234_432_1,
                    'rush'         => 2_112.432_1,
                    'ERROR_FUNKEY' => 'abcdefg',
                    'answer'       => 42.456_7,
                    'fnord'        => 23.765_444_444_444_444_444,
                    'units'        => -877.567_8,
                    'degree'       => -33.876_587_658_765_875_687_658_765,
                    'ncc'          => 1_701.678_9
                }
            );
        },
        "/EHVRVNV03.*$mode_tagline/",
        q{THVRVNV33 hashref_number_typetest0({ 'binary' => 2.123_443_211_234_432_1, 'ERROR_FUNKEY' => 'abcdefg', ..., 'ncc' => 1_701.678_9 }) throws correct exception}
    );
    lives_and(    # THVRVNV34
        sub {
            like(
                hashref_number_typetest0(
                    {   'binary' => 2.123_443_211_234_432_1,
                        'rush'   => 2_112.432_1,
                        'answer' => 42.456_7,
                        'fnord'  => 23.765_444_444_444_444_444,
                        'units'  => -877.567_8,
                        'degree' => -33.876_587_658_765_875_687_658_765,
                        'ncc'    => 1_701.678_9
                    }
                ),

                q{/^\\\{\s(?=.*'binary' => 2\.123_443_211_234)(?=.*'rush' => 2_112\.432_1)(?=.*'answer' => 42\.456_7)(?=.*'fnord' => 23\.765_444_444_44)(?=.*'units' => -877\.567_8)(?=.*'degree' => -33\.876_587_658_76)(?=.*'ncc' => 1_701\.678_9).*\s\}} . $mode_tagline . q{$/m},
                q{THVRVNV34 hashref_number_typetest0({ 'binary' => 2.123_443_211_234_432_1, 'rush' => 2_112.432_1, ..., 'ncc' => 1_701.678_9 }) returns correct value}
            );
        },
        q{THVRVNV34 hashref_number_typetest0({ 'binary' => 2.123_443_211_234_432_1, 'rush' => 2_112.432_1, ..., 'ncc' => 1_701.678_9 }) lives}
    );
    lives_and(    # THVRVNV40
        sub {
            my hashref::number $tmp_retval    = hashref_number_typetest1(5);
            my hashref::number $correct_retval = {
                "$mode_tagline\_funkey2" => 10.246_913_578,
                "$mode_tagline\_funkey3" => 15.370_370_367,
                "$mode_tagline\_funkey4" => 20.493_827_156,
                "$mode_tagline\_funkey1" => 5.123_456_789,
                "$mode_tagline\_funkey0" => 0
            };
            foreach my string $correct_retval_key ( keys %{$correct_retval} ) {
                ok( ( ( exists $tmp_retval->{$correct_retval_key} ) and ( defined $tmp_retval->{$correct_retval_key} ) ),
                    q{THVRVNV40a hashref_number_typetest1(5) returns defined value, at key } . $correct_retval_key
                );
                delta_ok(
                    $correct_retval->{$correct_retval_key},
                    $tmp_retval->{$correct_retval_key},
                    q{THVRVNV40b hashref_number_typetest1(5) returns correct value, at key } . $correct_retval_key
                );
            }
        },
        q{THVRVNV40 hashref_number_typetest1(5) lives}
    );

    # [[[ HASH STRING REF TESTS ]]]
    # [[[ HASH STRING REF TESTS ]]]
    # [[[ HASH STRING REF TESTS ]]]

    throws_ok(    # THVRVPV00
        sub { hashref_string_to_string() },
        "/(EHVRVPV00.*$mode_tagline)|(Usage.*hashref_string_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVPV00 hashref_string_to_string() throws correct exception}
    );
    throws_ok(                                                               # THVRVPV01
        sub { hashref_string_to_string(undef) },
        "/EHVRVPV00.*$mode_tagline/",
        q{THVRVPV01 hashref_string_to_string(undef) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV02
        sub { hashref_string_to_string(2) },
        "/EHVRVPV01.*$mode_tagline/",
        q{THVRVPV02 hashref_string_to_string(2) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV03
        sub { hashref_string_to_string(2.3) },
        "/EHVRVPV01.*$mode_tagline/",
        q{THVRVPV03 hashref_string_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV04
        sub { hashref_string_to_string('Lone Ranger') },
        "/EHVRVPV01.*$mode_tagline/",
        q{THVRVPV04 hashref_string_to_string('Lone Ranger') throws correct exception}
    );
    throws_ok(                                                               # THVRVPV05
        sub { hashref_string_to_string([ 'Lone Ranger' ]) },
        "/EHVRVPV01.*$mode_tagline/",
        q{THVRVPV05 hashref_string_to_string([ 'Lone Ranger' ]) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV10
        sub {
            hashref_string_to_string(
                {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                    'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                    'UNDEF_NOT_STRING'                 => undef
                }
            );
        },
        "/EHVRVPV02.*$mode_tagline/",
        q{THVRVPV10 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'UNDEF_NOT_STRING' => undef }) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV11
        sub {
            hashref_string_to_string(
                {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                    'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                    'INTEGER_NOT_STRING'               => 23
                }
            );
        },
        "/EHVRVPV03.*$mode_tagline/",
        q{THVRVPV11 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'INTEGER_NOT_STRING' => 23 }) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV12
        sub {
            hashref_string_to_string(
                {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                    'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                    'NUMBER_NOT_STRING'                => -2_112.23
                }
            );
        },
        "/EHVRVPV03.*$mode_tagline/",
        q{THVRVPV12 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'NUMBER_NOT_STRING' => -2_112.23 }) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV13
        sub {
            hashref_string_to_string(
                {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                    'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                    'ARRAY_NOT_STRING'                 => [ 'Tonto' ]
                }
            );
        },
        "/EHVRVPV03.*$mode_tagline/",
        q{THVRVPV13 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'ARRAY_NOT_STRING' => [ 'Tonto' ] }) throws correct exception}
    );
    throws_ok(                                                               # THVRVPV14
        sub {
            hashref_string_to_string(
                {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                    'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                    'HASH_NOT_STRING'                  => { fizz => 3 }
                }
            );
        },
        "/EHVRVPV03.*$mode_tagline/",
        q{THVRVPV14 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'HASH_NOT_STRING' => { fizz => 3 } }) throws correct exception}
    );
    lives_and(                                                               # THVRVPV20
        sub {
            like(
                hashref_string_to_string(
                    {   'stuckinaworldhenevercreated'                => 'Howard The Duck',
                        'kryptonian_manofsteel_clarkkent'            => 'Superman',
                        'gothamite_darkknight_brucewayne'            => 'Batman',
                        'amazonian_dianathemyscira_dianaprince'      => 'Wonder Woman',
                        'scarletspeedster_barryallenetal'            => 'Flash',
                        'alanscottetal'                              => 'Green Lantern',
                        'atlanteanhybrid_aquaticace_arthurcurryorin' => 'Aquaman',
                        'greenmartian_bloodwynd_jonnjonnz'           => 'Martian Manhunter'
                    }
                ),
                q{/^\\\{\s(?=.*'stuckinaworldhenevercreated' => 'Howard The Duck')(?=.*'kryptonian_manofsteel_clarkkent' => 'Superman')(?=.*'gothamite_darkknight_brucewayne' => 'Batman')(?=.*'amazonian_dianathemyscira_dianaprince' => 'Wonder Woman')(?=.*'scarletspeedster_barryallenetal' => 'Flash')(?=.*'alanscottetal' => 'Green Lantern')(?=.*'atlanteanhybrid_aquaticace_arthurcurryorin' => 'Aquaman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter').*\s\}$/m}
                ,    ## PERLTIDY BUG comma on newline
                q{THVRVPV20 hashref_string_to_string({ 'stuckinaworldhenevercreated' => 'Howard The Duck', 'kryptonian_manofsteel_clarkkent' => 'Superman', ... }) returns correct value}
            );
        },
        q{THVRVPV20 hashref_string_to_string({ 'stuckinaworldhenevercreated' => 'Howard The Duck', 'kryptonian_manofsteel_clarkkent' => 'Superman', ... }) lives}
    );
    lives_and(       # THVRVPV21
        sub {
            like(
                hashref_string_to_string(
                    {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                        'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                        'STRING_NOT_UNDEF'                 => 'undef'
                    }
                ),
                q{/^\\\{\s(?=.*'kryptonian_manofsteel_clarkkent' => 'Superman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter')(?=.*'STRING_NOT_UNDEF' => 'undef').*\s\}$/m}
                ,    ## PERLTIDY BUG comma on newline
                q{THVRVPV21 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'STRING_NOT_UNDEF' => 'undef' }) returns correct value}
            );
        },
        q{THVRVPV21 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'STRING_NOT_UNDEF' => 'undef' }) lives}
    );
    lives_and(       # THVRVPV22
        sub {
            like(
                hashref_string_to_string(
                    {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                        'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                        'STRING_NOT_INTEGER'               => '23'
                    }
                ),
                q{/^\\\{\s(?=.*'kryptonian_manofsteel_clarkkent' => 'Superman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter')(?=.*'STRING_NOT_INTEGER' => '23').*\s\}$/m}
                ,    ## PERLTIDY BUG comma on newline
                q{THVRVPV22 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'STRING_NOT_INTEGER' => '23' }) returns correct value}
            );
        },
        q{THVRVPV22 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'STRING_NOT_INTEGER' => '23' }) lives}
    );
    lives_and(       # THVRVPV23
        sub {
            like(
                hashref_string_to_string(
                    {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                        'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                        'STRING_NOT_NUMBER'                => '-2_112.23'
                    }
                ),
                q{/^\\\{\s(?=.*'kryptonian_manofsteel_clarkkent' => 'Superman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter')(?=.*'STRING_NOT_NUMBER' => '-2_112.23').*\s\}$/m}
                ,    ## PERLTIDY BUG comma on newline
                q{THVRVPV23 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'STRING_NOT_NUMBER' => '-2_112.23' }) returns correct value}
            );
        },
        q{THVRVPV23 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'STRING_NOT_NUMBER' => '-2_112.23' }) lives}
    );
    lives_and(       # THVRVPV24
        sub {
            like(
                hashref_string_to_string(
                    {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                        'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                        "STRING_NOT_ARRAY"                 => "[ Tonto ]"
                    }
                ),
                q{/^\\\{\s(?=.*'kryptonian_manofsteel_clarkkent' => 'Superman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter')(?=.*'STRING_NOT_ARRAY' => '\[ Tonto \]').*\s\}$/m}
                ,    ## PERLTIDY BUG comma on newline
                q{THVRVPV24 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., "STRING_NOT_ARRAY" => "[ Tonto ]" }) returns correct value}
            );
        },
        q{THVRVPV24 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., "STRING_NOT_ARRAY" => "[ Tonto ]" }) lives}
    );
    lives_and(       # THVRVPV25
        sub {
            like(
                hashref_string_to_string(
                    {   'kryptonian_manofsteel_clarkkent'  => 'Superman',
                        'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter',
                        "STRING_NOT_HASH"                  => "{ buzz => 5 }"
                    }
                ),

   # DEV NOTE: must surround single-q-quote below with square brackets instead of curly braces, so that the backslash-escaped curly braces inside the string
   # will stay backslash-escaped as they are passed to the regex, to fix Perl v5.22 error 'Unescaped left brace in regex is deprecated, passed through in regex'
                q[/^\{\s(?=.*'kryptonian_manofsteel_clarkkent' => 'Superman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter')(?=.*'STRING_NOT_HASH' => '\{ buzz => 5 \}').*\s\}$/m]
                ,    ## PERLTIDY BUG comma on newline
                q{THVRVPV25 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., "STRING_NOT_HASH" => "{ buzz => 5 }" }) returns correct value}
            );
        },
        q{THVRVPV25 hashref_string_to_string({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., "STRING_NOT_HASH" => "{ buzz => 5 }" }) lives}
    );
    throws_ok(       # THVRVPV30
        sub { hashref_string_typetest0() },
        "/(EHVRVPV00.*$mode_tagline)|(Usage.*hashref_string_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVPV30 hashref_string_typetest0() throws correct exception}
    );
    throws_ok(                                                                # THVRVPV31
        sub { hashref_string_typetest0(2) },
        "/EHVRVPV01.*$mode_tagline/",
        q{THVRVPV31 hashref_string_typetest0(2) throws correct exception}
    );
    throws_ok(                                                                # THVRVPV32
        sub {
            hashref_string_typetest0(
                {   'kryptonian_manofsteel_clarkkent'            => 'Superman',
                    'gothamite_darkknight_brucewayne'            => 'Batman',
                    'amazonian_dianathemyscira_dianaprince'      => 'Wonder Woman',
                    'scarletspeedster_barryallenetal'            => 'Flash',
                    'alanscottetal'                              => 'Green Lantern',
                    'atlanteanhybrid_aquaticace_arthurcurryorin' => 'Aquaman',
                    'greenmartian_bloodwynd_jonnjonnz'           => 'Martian Manhunter',
                    'UNDEF_NOT_STRING'                           => undef
                }
            );
        },
        "/EHVRVPV02.*$mode_tagline/",
        q{THVRVPV32 hashref_string_typetest0({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'UNDEF_NOT_STRING' => undef }) throws correct exception}
    );
    throws_ok(    # THVRVPV33
        sub {
            hashref_string_typetest0(
                {   'kryptonian_manofsteel_clarkkent'            => 'Superman',
                    'gothamite_darkknight_brucewayne'            => 'Batman',
                    'amazonian_dianathemyscira_dianaprince'      => 'Wonder Woman',
                    'scarletspeedster_barryallenetal'            => 'Flash',
                    'alanscottetal'                              => 'Green Lantern',
                    'atlanteanhybrid_aquaticace_arthurcurryorin' => 'Aquaman',
                    'greenmartian_bloodwynd_jonnjonnz'           => 'Martian Manhunter',
                    'ARRAY_NOT_STRING'                           => [ 23, -42.3 ]
                }
            );
        },
        "/EHVRVPV03.*$mode_tagline/",
        q{THVRVPV33 hashref_string_typetest0({ 'kryptonian_manofsteel_clarkkent' => 'Superman', ..., 'ARRAY_NOT_STRING' => [ 23, -42. 3 ] }) throws correct exception}
    );
    lives_and(    # THVRVPV34
        sub {
            like(
                hashref_string_typetest0(
                    {   'stuckinaworldhenevercreated'                => 'Howard The Duck',
                        'atlanteanhybrid_aquaticace_arthurcurryorin' => 'Aquaman',
                        'greenmartian_bloodwynd_jonnjonnz'           => 'Martian Manhunter'
                    }
                ),
                q{/^\\\{\s(?=.*'stuckinaworldhenevercreated' => 'Howard The Duck')(?=.*'atlanteanhybrid_aquaticace_arthurcurryorin' => 'Aquaman')(?=.*'greenmartian_bloodwynd_jonnjonnz' => 'Martian Manhunter').*\s\}} . $mode_tagline . q{$/m},
                q{THVRVPV34 hashref_string_typetest0({ 'stuckinaworldhenevercreated' => 'Howard The Duck', ... }) returns correct value}
            );
        },
        q{THVRVPV34 hashref_string_typetest0({ 'stuckinaworldhenevercreated' => 'Howard The Duck', ... }) lives}
    );
    lives_and(    # THVRVPV40
        sub {
            is_deeply(
                hashref_string_typetest1(5),
                {   "$mode_tagline\_Luker_key3" => 'Jeffy Ten! 3/4',
                    "$mode_tagline\_Luker_key2" => 'Jeffy Ten! 2/4',
                    "$mode_tagline\_Luker_key1" => 'Jeffy Ten! 1/4',
                    "$mode_tagline\_Luker_key4" => 'Jeffy Ten! 4/4',
                    "$mode_tagline\_Luker_key0" => 'Jeffy Ten! 0/4'
                },
                q{THVRVPV40 hashref_string_typetest1(5) returns correct value}
            );
        },
        q{THVRVPV40 hashref_string_typetest1(5) lives}
    );

    # [[[ HASH REF ARRAY REF INTEGER TESTS ]]]
    # [[[ HASH REF ARRAY REF INTEGER TESTS ]]]
    # [[[ HASH REF ARRAY REF INTEGER TESTS ]]]

=DISABLE_TEST_DATA
{ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }
{
    key_0 => [ 0,  1,  2 ],
    key_1 => [ 5,  6,  7 ],
    key_2 => [ 0, -1, -2 ]
}
=cut

    throws_ok(    # THVRVAVRVIV00
        sub { hashref_arrayref_integer_to_string() },
        "/(EHVRVAVRVIV00.*$mode_tagline)|(Usage.*hashref_arrayref_integer_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVAVRVIV00 hashref_arrayref_integer_to_string() throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVIV01
        sub { hashref_arrayref_integer_to_string(undef) },
        "/EHVRVAVRVIV00.*$mode_tagline/",
        q{THVRVAVRVIV01 hashref_arrayref_integer_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVIV02
        sub { hashref_arrayref_integer_to_string(2) },
        "/EHVRVAVRVIV01.*$mode_tagline/",
        q{THVRVAVRVIV02 hashref_arrayref_integer_to_string(2) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVIV03
        sub { hashref_arrayref_integer_to_string(2.3) },
        "/EHVRVAVRVIV01.*$mode_tagline/",
        q{THVRVAVRVIV03 hashref_arrayref_integer_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVIV04
        sub { hashref_arrayref_integer_to_string('2') },
        "/EHVRVAVRVIV01.*$mode_tagline/",
        q{THVRVAVRVIV04 hashref_arrayref_integer_to_string('2') throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVIV05
        sub { hashref_arrayref_integer_to_string([ 2 ]) },
        "/EHVRVAVRVIV01.*$mode_tagline/",
        q{THVRVAVRVIV05 hashref_arrayref_integer_to_string([ 2 ]) throws correct exception}
    );

    throws_ok(    # THVRVAVRVIV10
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => undef,
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV02.*$mode_tagline/",
        q{THVRVAVRVIV10 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => undef, key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV11
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => 23,
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV03.*$mode_tagline/",
        q{THVRVAVRVIV11 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => 23, key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV12
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => 23.42,
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV03.*$mode_tagline/",
        q{THVRVAVRVIV12 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => 23.42, key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV13
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => 'howdy',
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV03.*$mode_tagline/",
        q{THVRVAVRVIV13 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => 'howdy', key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV14
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => { subkey_10 => 23 },
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV03.*$mode_tagline/",
        q{THVRVAVRVIV14 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => { subkey_10 => 23 }, key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );

    throws_ok(    # THVRVAVRVIV20
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  undef ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV04.*$mode_tagline/",
        q{THVRVAVRVIV20 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, undef ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV21
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  undef,  7 ],
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV04.*$mode_tagline/",
        q{THVRVAVRVIV21 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, undef, 7 ], key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV22
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  undef, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV04.*$mode_tagline/",
        q{THVRVAVRVIV22 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [  undef, -1, -2 ] }) throws correct exception}
    );
    

    throws_ok(    # THVRVAVRVIV30
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0.1,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV05.*$mode_tagline/",
        q{THVRVAVRVIV30 hashref_arrayref_integer_to_string({ key_0 => [ 0.1, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV31
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  '6',  7 ],
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV05.*$mode_tagline/",
        q{THVRVAVRVIV31 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, '6', 7 ], key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV32
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, [ -2 ] ]
            });
        },
        "/EHVRVAVRVIV05.*$mode_tagline/",
        q{THVRVAVRVIV32 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, [ -2 ] ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV33
        sub {
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  { subkey_11 => 6 },  7 ],
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV05.*$mode_tagline/",
        q{THVRVAVRVIV33 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, { subkey_11 => 6 }, 7 ], key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );

    lives_and(    # THVRVAVRVIV40
        sub {
            is( hashref_arrayref_integer_to_string( { key_0 => [ 0, 1, 2 ] } ), q{{ 'key_0' => [ 0, 1, 2 ] }}, q{THVRVAVRVIV40 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ] }) returns correct value} );
        },
        q{THVRVAVRVIV40 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ] }) lives}
    );
    lives_and(    # THVRVAVRVIV51
        sub { like(
            hashref_arrayref_integer_to_string({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, -2 ]
            }),

             # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            q{/^\\\{\s(?=.*'key_0' => \[ 0, 1, 2 \])(?=.*'key_1' => \[ 5, 6, 7 \])(?=.*'key_2' => \[ 0, -1, -2 \]).*\s\}$/m},
            q{THVRVAVRVIV51 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) returns correct value}
        ); },
        q{THVRVAVRVIV51 hashref_arrayref_integer_to_string({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) lives}
    );
    lives_and(    # THVRVAVRVIV52
        sub { like(
            hashref_arrayref_integer_to_string_compact({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, -2 ]
            }),

             # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            q{/^\\\{(?=.*'key_0'=>\[0,1,2\])(?=.*'key_1'=>\[5,6,7\])(?=.*'key_2'=>\[0,-1,-2\]).*\}$/m},
            q{THVRVAVRVIV52 hashref_arrayref_integer_to_string_compact({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) returns correct value}
        ); },
        q{THVRVAVRVIV52 hashref_arrayref_integer_to_string_compact({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) lives}
    );
    lives_and(    # THVRVAVRVIV53
        sub { like(
            hashref_arrayref_integer_to_string_pretty({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, -2 ]
            }),

            # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            # DEV NOTE: must have 's' regex modifier to treat multi-line string as single line
            # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warnings
            # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
            q{/^\\\{(?=.*\n    'key_0' => \[ 0, 1, 2 \])(?=.*\n    'key_1' => \[ 5, 6, 7 \])(?=.*\n    'key_2' => \[ 0, -1, -2 \]).*\}$/ms},
            q{THVRVAVRVIV53 hashref_arrayref_integer_to_string_pretty({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) returns correct value}
        ); },
        q{THVRVAVRVIV53 hashref_arrayref_integer_to_string_pretty({ key_0 => [ 0, 1, 2 ], key_1 => [ 5, 6, 7 ], key_2 => [ 0, -1, -2 ] }) lives}
    );

    throws_ok(    # THVRVAVRVIV60
        sub { hashref_arrayref_integer_typetest0() },
        "/(EHVRVAVRVIV00.*$mode_tagline)|(Usage.*hashref_arrayref_integer_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVAVRVIV60 hashref_arrayref_integer_typetest0() throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV61
        sub { hashref_arrayref_integer_typetest0(2) },
        "/EHVRVAVRVIV01.*$mode_tagline/",
        q{THVRVAVRVIV61 hashref_arrayref_integer_typetest0(2) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV62
        sub {
            hashref_arrayref_integer_typetest0({
                key_0 => [  0,  1,  2 ],
                key_1 => undef,
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV02.*$mode_tagline/",
        q{THVRVAVRVIV62 hashref_arrayref_integer_typetest0({ key_0 => [ 0, 1, 2 ], key_1 => undef, key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVIV63
        sub {
            hashref_arrayref_integer_typetest0({
                key_0 => [  0,  1,  2 ],
                key_1 => 5,
                key_2 => [  0, -1, -2 ]
            });
        },
        "/EHVRVAVRVIV03.*$mode_tagline/",
        q{THVRVAVRVIV63 hashref_arrayref_integer_typetest0({ key_0 => [ 0, 1, 2 ], key_1 => 5, key_2 => [ 0, -1, -2 ] }) throws correct exception}
    );
    lives_and(    # THVRVAVRVIV64
        sub {
            like( hashref_arrayref_integer_typetest0({
                key_0 => [  0,  1,  2 ],
                key_1 => [  5,  6,  7 ],
                key_2 => [  0, -1, -2 ]
            } ),
            # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warnings
            # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
                q{/^\\\{(?=.*'key_0' => \[ 0, 1, 2 \])(?=.*'key_1' => \[ 5, 6, 7 \])(?=.*'key_2' => \[ 0, -1, -2 \]).*\}} . $mode_tagline . q{$/ms},
                q{THVRVAVRVIV64 hashref_arrayref_integer_typetest0({ key_0 => [ 0, 1, 2 ], key_1 => [ 5,  6,  7 ], key_2 => [ 0, -1, -2 ] }) returns correct value}
            );
        },
        q{THVRVAVRVIV64 hashref_arrayref_integer_typetest0({ key_0 => [ 0, 1, 2 ], key_1 => [ 5,  6,  7 ], key_2 => [ 0, -1, -2 ] }) lives}
    );

    lives_and(    # THVRVAVRVIV70
        sub {
            is_deeply(
                hashref_arrayref_integer_typetest1(5),
                {   
                    "$mode_tagline\_funkey0" => [0, 0, 0, 0, 0],
                    "$mode_tagline\_funkey1" => [0, 1, 2, 3, 4],
                    "$mode_tagline\_funkey2" => [0, 2, 4, 6, 8],
                    "$mode_tagline\_funkey3" => [0, 3, 6, 9, 12],
                    "$mode_tagline\_funkey4" => [0, 4, 8, 12, 16]
                },
                q{THVRVAVRVIV70 hashref_arrayref_integer_typetest1(5) returns correct value}
            );
        },
        q{THVRVAVRVIV70 hashref_arrayref_integer_typetest1(5) lives}
    );

    # [[[ HASH REF ARRAY REF NUMBER TESTS ]]]
    # [[[ HASH REF ARRAY REF NUMBER TESTS ]]]
    # [[[ HASH REF ARRAY REF NUMBER TESTS ]]]

# DEV NOTE: must include at least one normal integer ('1') in our floating-point test data, in order to trigger *SvIOKp() in hashref_arrayref_number_CHECK*()
=DISABLE_TEST_DATA
{ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }
{
    key_0 => [ 0.1,    1,      2.3   ],
    key_1 => [ 5.67,   6.78,   7.89  ],
    key_2 => [ 0.123, -1.234, -2.345 ]
}
=cut

    throws_ok(    # THVRVAVRVNV00
        sub { hashref_arrayref_number_to_string() },
        "/(EHVRVAVRVNV00.*$mode_tagline)|(Usage.*hashref_arrayref_number_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVAVRVNV00 hashref_arrayref_number_to_string() throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVNV01
        sub { hashref_arrayref_number_to_string(undef) },
        "/EHVRVAVRVNV00.*$mode_tagline/",
        q{THVRVAVRVNV01 hashref_arrayref_number_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVNV02
        sub { hashref_arrayref_number_to_string(2) },
        "/EHVRVAVRVNV01.*$mode_tagline/",
        q{THVRVAVRVNV02 hashref_arrayref_number_to_string(2) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVNV03
        sub { hashref_arrayref_number_to_string(2.3) },
        "/EHVRVAVRVNV01.*$mode_tagline/",
        q{THVRVAVRVNV03 hashref_arrayref_number_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVNV04
        sub { hashref_arrayref_number_to_string('2') },
        "/EHVRVAVRVNV01.*$mode_tagline/",
        q{THVRVAVRVNV04 hashref_arrayref_number_to_string('2') throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVNV05
        sub { hashref_arrayref_number_to_string([ 2 ]) },
        "/EHVRVAVRVNV01.*$mode_tagline/",
        q{THVRVAVRVNV05 hashref_arrayref_number_to_string([ 2 ]) throws correct exception}
    );

    throws_ok(    # THVRVAVRVNV10
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => undef,
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV02.*$mode_tagline/",
        q{THVRVAVRVNV10 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => undef, key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV11
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => 23,
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV03.*$mode_tagline/",
        q{THVRVAVRVNV11 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => 23, key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV12
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => 23.42,
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV03.*$mode_tagline/",
        q{THVRVAVRVNV12 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => 23.42, key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV13
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => 'howdy',
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV03.*$mode_tagline/",
        q{THVRVAVRVNV13 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => 'howdy', key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV14
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => { subkey_10 => 23.42 },
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV03.*$mode_tagline/",
        q{THVRVAVRVNV14 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => { subkey_10 => 23.42 }, key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );

    throws_ok(    # THVRVAVRVNV20
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      undef ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV04.*$mode_tagline/",
        q{THVRVAVRVNV20 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, undef ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV21
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   undef,  7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV04.*$mode_tagline/",
        q{THVRVAVRVNV21 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, undef, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV22
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ undef, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV04.*$mode_tagline/",
        q{THVRVAVRVNV22 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [  undef, -1.234, -2.345 ] }) throws correct exception}
    );

    throws_ok(    # THVRVAVRVNV30
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,  '6.78',  7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV05.*$mode_tagline/",
        q{THVRVAVRVNV30 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67,  '6.78',  7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV31
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ 0.123, -1.234, [ -2.345 ] ]
            });
        },
        "/EHVRVAVRVNV05.*$mode_tagline/",
        q{THVRVAVRVNV31 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, [ -2.345 ] ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV32
        sub {
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   { subkey_11 => 6.78 },   7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV05.*$mode_tagline/",
        q{THVRVAVRVNV32 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, { subkey_11 => 6.78 }, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );

    lives_and(    # THVRVAVRVNV40
        sub {
            is( hashref_arrayref_number_to_string( { key_0 => [ 0.1, 1, 2.3 ] } ), q{{ 'key_0' => [ 0.1, 1, 2.3 ] }}, q{THVRVAVRVNV40 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1,   2.3 ] }) returns correct value} );
        },
        q{THVRVAVRVNV40 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ] }) lives}
    );
    lives_and(    # THVRVAVRVNV51
        sub { like(
            hashref_arrayref_number_to_string({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            }),

             # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            q{/^\\\{\s(?=.*'key_0' => \[ 0.1, 1, 2.3 \])(?=.*'key_1' => \[ 5.67, 6.78, 7.89 \])(?=.*'key_2' => \[ 0.123, -1.234, -2.345 \]).*\s\}$/m},
            q{THVRVAVRVNV51 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) returns correct value}
        ); },
        q{THVRVAVRVNV51 hashref_arrayref_number_to_string({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) lives}
    );
    lives_and(    # THVRVAVRVNV52
        sub { like(
            hashref_arrayref_number_to_string_compact({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            }),

             # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warnings
            # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
            q{/^\\\{(?=.*'key_0'=>\[0.1,1,2.3\])(?=.*'key_1'=>\[5.67,6.78,7.89\])(?=.*'key_2'=>\[0.123,-1.234,-2.345\]).*\}$/m},
            q{THVRVAVRVNV52 hashref_arrayref_number_to_string_compact({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) returns correct value}
        ); },
        q{THVRVAVRVNV52 hashref_arrayref_number_to_string_compact({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) lives}
    );
    lives_and(    # THVRVAVRVNV53
        sub { like(
            hashref_arrayref_number_to_string_pretty({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            }),

            # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            # DEV NOTE: must have 's' regex modifier to treat multi-line string as single line
            # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warnings
            # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
            q{/^\\\{(?=.*\n    'key_0' => \[ 0.1, 1, 2.3 \])(?=.*\n    'key_1' => \[ 5.67, 6.78, 7.89 \])(?=.*\n    'key_2' => \[ 0.123, -1.234, -2.345 \]).*\}$/ms},
            q{THVRVAVRVNV53 hashref_arrayref_number_to_string_pretty({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) returns correct value}
        ); },
        q{THVRVAVRVNV53 hashref_arrayref_number_to_string_pretty({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) lives}
    );

    throws_ok(    # THVRVAVRVNV60
        sub { hashref_arrayref_number_typetest0() },
        "/(EHVRVAVRVNV00.*$mode_tagline)|(Usage.*hashref_arrayref_number_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVAVRVNV60 hashref_arrayref_number_typetest0() throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV61
        sub { hashref_arrayref_number_typetest0(2) },
        "/EHVRVAVRVNV01.*$mode_tagline/",
        q{THVRVAVRVNV61 hashref_arrayref_number_typetest0(2) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV62
        sub {
            hashref_arrayref_number_typetest0({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => undef,
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV02.*$mode_tagline/",
        q{THVRVAVRVNV62 hashref_arrayref_number_typetest0({ key_0 => [ 0.1, 1, 2.3 ], key_1 => undef, key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVNV63
        sub {
            hashref_arrayref_number_typetest0({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => 5.67,
                key_2 => [ 0.123, -1.234, -2.345 ]
            });
        },
        "/EHVRVAVRVNV03.*$mode_tagline/",
        q{THVRVAVRVNV63 hashref_arrayref_number_typetest0({ key_0 => [ 0.1, 1, 2.3 ], key_1 => 5.67, key_2 => [ 0.123, -1.234, -2.345 ] }) throws correct exception}
    );
    lives_and(    # THVRVAVRVNV64
        sub {
            like( hashref_arrayref_number_typetest0({
                key_0 => [ 0.1,    1,      2.3   ],
                key_1 => [ 5.67,   6.78,   7.89  ],
                key_2 => [ 0.123, -1.234, -2.345 ]
            }),
                # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warning
                # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
                q{/^\\\{(?=.*'key_0' => \[ 0.1, 1, 2.3 \])(?=.*'key_1' => \[ 5.67, 6.78, 7.89 \])(?=.*'key_2' => \[ 0.123, -1.234, -2.345 \]).*\}} . $mode_tagline . q{$/ms},
                q{THVRVAVRVNV64 hashref_arrayref_number_typetest0({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89  ], key_2 => [ 0.123, -1.234, -2.345 ] }) returns correct value}
            );
        },
        q{THVRVAVRVNV64 hashref_arrayref_number_typetest0({ key_0 => [ 0.1, 1, 2.3 ], key_1 => [ 5.67, 6.78, 7.89 ], key_2 => [ 0.123, -1.234, -2.345 ] }) lives}
    );

    # perl -e 'use Perl::Structure::Hash::SubTypes2D qw(hashref_arrayref_number_typetest1); print hashref_arrayref_number_to_string_pretty(hashref_arrayref_number_typetest1(5)), "\n";'
    lives_and(    # THVRVAVRVNV70
        sub {
            is_deeply(
                hashref_arrayref_number_typetest1(5),
                {   
                    "$mode_tagline\_funkey0" => [ 0, 0, 0, 0, 0 ],
                    "$mode_tagline\_funkey1" => [ 0,  5.123_456_789, 10.246_913_578, 15.370_370_367, 20.493_827_156 ],
                    "$mode_tagline\_funkey2" => [ 0, 10.246_913_578, 20.493_827_156, 30.740_740_734, 40.987_654_312 ],
                    "$mode_tagline\_funkey3" => [ 0, 15.370_370_367, 30.740_740_734, 46.111_111_101, 61.481_481_468 ],
                    "$mode_tagline\_funkey4" => [ 0, 20.493_827_156, 40.987_654_312, 61.481_481_468, 81.975_308_624 ]
                },
                q{THVRVAVRVNV70 hashref_arrayref_number_typetest1(5) returns correct value}
            );
        },
        q{THVRVAVRVNV70 hashref_arrayref_number_typetest1(5) lives}
    );

    # [[[ HASH REF ARRAY REF STRING TESTS ]]]
    # [[[ HASH REF ARRAY REF STRING TESTS ]]]
    # [[[ HASH REF ARRAY REF STRING TESTS ]]]

=DISABLE_TEST_DATA
{ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }
{
    key_0 => [ '0', '1', '2'  ],
    key_1 => [ 'a', 'b', 'c'  ],
    key_2 => [ 'h i', '', "\n" ]
}
            {
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            }
=cut

    throws_ok(    # THVRVAVRVPV00
        sub { hashref_arrayref_string_to_string() },
        "/(EHVRVAVRVPV00.*$mode_tagline)|(Usage.*hashref_arrayref_string_to_string)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVAVRVPV00 hashref_arrayref_string_to_string() throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVPV01
        sub { hashref_arrayref_string_to_string(undef) },
        "/EHVRVAVRVPV00.*$mode_tagline/",
        q{THVRVAVRVPV01 hashref_arrayref_string_to_string(undef) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVPV02
        sub { hashref_arrayref_string_to_string(2) },
        "/EHVRVAVRVPV01.*$mode_tagline/",
        q{THVRVAVRVPV02 hashref_arrayref_string_to_string(2) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVPV03
        sub { hashref_arrayref_string_to_string(2.3) },
        "/EHVRVAVRVPV01.*$mode_tagline/",
        q{THVRVAVRVPV03 hashref_arrayref_string_to_string(2.3) throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVPV04
        sub { hashref_arrayref_string_to_string('2') },
        "/EHVRVAVRVPV01.*$mode_tagline/",
        q{THVRVAVRVPV04 hashref_arrayref_string_to_string('2') throws correct exception}
    );
    throws_ok(                                                                # THVRVAVRVPV05
        sub { hashref_arrayref_string_to_string([ 2 ]) },
        "/EHVRVAVRVPV01.*$mode_tagline/",
        q{THVRVAVRVPV05 hashref_arrayref_string_to_string([ 2 ]) throws correct exception}
    );

    throws_ok(    # THVRVAVRVPV10
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => undef,
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV02.*$mode_tagline/",
        q{THVRVAVRVPV10 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => undef, key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV11
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => 23,
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV03.*$mode_tagline/",
        q{THVRVAVRVPV11 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => 23, key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV12
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => 23.42,
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV03.*$mode_tagline/",
        q{THVRVAVRVPV12 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => 23.42, key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV13
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => 'h i',
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV03.*$mode_tagline/",
        q{THVRVAVRVPV13 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => 'h i', key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV14
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => { subkey_10 => 'h i' },
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV03.*$mode_tagline/",
        q{THVRVAVRVPV14 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => { subkey_10 => 'h i' }, key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );

    throws_ok(    # THVRVAVRVPV20
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', undef  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV04.*$mode_tagline/",
        q{THVRVAVRVPV20 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', undef ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV21
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', undef, 'c' ],
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV04.*$mode_tagline/",
        q{THVRVAVRVPV21 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', undef, 'c' ], key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV22
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ undef, '', "\n" ]
            });
        },
        "/EHVRVAVRVPV04.*$mode_tagline/",
        q{THVRVAVRVPV22 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [  undef, '', "\n" ] }) throws correct exception}
    );
    

    throws_ok(    # THVRVAVRVPV30
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ 0, '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV05.*$mode_tagline/",
        q{THVRVAVRVPV30 hashref_arrayref_string_to_string({ key_0 => [ 0, '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV31
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0',  '1', '2' ],
                key_1 => [ 'a', 6.78, 'c' ],
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV05.*$mode_tagline/",
        q{THVRVAVRVPV31 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 6.78, 'c' ], key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV32
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', [ "\n" ] ]
            });
        },
        "/EHVRVAVRVPV05.*$mode_tagline/",
        q{THVRVAVRVPV32 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', [ "\n" ] ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV33
        sub {
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', { subkey_11 => 'b' }, 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV05.*$mode_tagline/",
        q{THVRVAVRVPV33 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', { subkey_11 => 'b' }, 'c' ], key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );

    lives_and(    # THVRVAVRVPV40
        sub {
            is( hashref_arrayref_string_to_string( { key_0 => [ '0', '1', '2' ] } ), q{{ 'key_0' => [ '0', '1', '2' ] }}, q{THVRVAVRVPV40 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ] }) returns correct value} );
        },
        q{THVRVAVRVPV40 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ] }) lives}
    );
    lives_and(    # THVRVAVRVPV51
        sub { like(
            hashref_arrayref_string_to_string({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            }),

            # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            # DEV NOTE: must have 's' regex modifier to treat multi-line string as single line, and must replace double-quotes w/ single-quotes per RPerl's string output default
            q{/^\\\{\s(?=.*'key_0' => \[ '0', '1', '2' \])(?=.*'key_1' => \[ 'a', 'b', 'c' \])(?=.*'key_2' => \[ 'h i', '', '\n' \]).*\s\}$/ms},
            q{THVRVAVRVPV51 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) returns correct value}
        ); },
        q{THVRVAVRVPV51 hashref_arrayref_string_to_string({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) lives}
    );
    lives_and(    # THVRVAVRVPV52
        sub { like(
            hashref_arrayref_string_to_string_compact({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            }),

            # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            # DEV NOTE: must have 's' regex modifier to treat multi-line string as single line, and must replace double-quotes w/ single-quotes per RPerl's string output default
            q{/^\\\{(?=.*'key_0'=>\['0','1','2'\])(?=.*'key_1'=>\['a','b','c'\])(?=.*'key_2'=>\['h i','','\n'\]).*\}$/ms},
            q{THVRVAVRVPV52 hashref_arrayref_string_to_string_compact({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) returns correct value}
        ); },
        q{THVRVAVRVPV52 hashref_arrayref_string_to_string_compact({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) lives}
    );
    lives_and(    # THVRVAVRVPV53
        sub { like(
            hashref_arrayref_string_to_string_pretty({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            }),

            # NEED FIX: replace ".*" near end of this & following regexes with syntax to match exactly 6 occurrences of ", "; (,\s)* and variations don't work?
            # DEV NOTE: must have 's' regex modifier to treat multi-line string as single line, and must replace double-quotes w/ single-quotes per RPerl's string output default
            # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warning
            # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
            q{/^\\\{(?=.*\n    'key_0' => \[ '0', '1', '2' \])(?=.*\n    'key_1' => \[ 'a', 'b', 'c' \])(?=.*\n    'key_2' => \[ 'h i', '', '\n' \]).*\}$/ms},
            q{THVRVAVRVPV53 hashref_arrayref_string_to_string_pretty({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) returns correct value}
        ); },
        q{THVRVAVRVPV53 hashref_arrayref_string_to_string_pretty({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) lives}
    );

    throws_ok(    # THVRVAVRVPV60
        sub { hashref_arrayref_string_typetest0() },
        "/(EHVRVAVRVPV00.*$mode_tagline)|(Usage.*hashref_arrayref_string_typetest0)/",    # DEV NOTE: 2 different error messages, Perl & C
        q{THVRVAVRVPV60 hashref_arrayref_string_typetest0() throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV61
        sub { hashref_arrayref_string_typetest0(2) },
        "/EHVRVAVRVPV01.*$mode_tagline/",
        q{THVRVAVRVPV61 hashref_arrayref_string_typetest0(2) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV62
        sub {
            hashref_arrayref_string_typetest0({
                key_0 => [ '0', '1', '2'  ],
                key_1 => undef,
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV02.*$mode_tagline/",
        q{THVRVAVRVPV62 hashref_arrayref_string_typetest0({ key_0 => [ '0', '1', '2' ], key_1 => undef, key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    throws_ok(    # THVRVAVRVPV63
        sub {
            hashref_arrayref_string_typetest0({
                key_0 => [ '0', '1', '2'  ],
                key_1 => 'b',
                key_2 => [ 'h i', '', "\n" ]
            });
        },
        "/EHVRVAVRVPV03.*$mode_tagline/",
        q{THVRVAVRVPV63 hashref_arrayref_string_typetest0({ key_0 => [ '0', '1', '2' ], key_1 => 'b', key_2 => [ 'h i', '', "\n" ] }) throws correct exception}
    );
    lives_and(    # THVRVAVRVPV64
        sub {
            like( hashref_arrayref_string_typetest0({
                key_0 => [ '0', '1', '2'  ],
                key_1 => [ 'a', 'b', 'c'  ],
                key_2 => [ 'h i', '', "\n" ]
            } ),
                # DEV NOTE: must have 's' regex modifier to treat multi-line string as single line, and must replace double-quotes w/ single-quotes per RPerl's string output default
                # DEV NOTE: must have extra backslash-delimited-backslash '\\' in front of backslash-delimited-left-brace '\{' to avoid warning
                # "Unescaped left brace in regex is passed through in regex; marked by <-- HERE in m/(?ms)^{ <-- HERE (?=.*\n ..."
                q{/^\\\{(?=.*'key_0' => \[ '0', '1', '2' \])(?=.*'key_1' => \[ 'a', 'b', 'c' \])(?=.*'key_2' => \[ 'h i', '', '\n' \]).*\}} . $mode_tagline . q{$/ms},
                q{THVRVAVRVPV64 hashref_arrayref_string_typetest0({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) returns correct value}
            );
        },
        q{THVRVAVRVPV64 hashref_arrayref_string_typetest0({ key_0 => [ '0', '1', '2' ], key_1 => [ 'a', 'b', 'c' ], key_2 => [ 'h i', '', "\n" ] }) lives}
    );

    # perl -e 'use Perl::Structure::Hash::SubTypes2D qw(hashref_arrayref_string_typetest1); print hashref_arrayref_string_to_string_pretty(hashref_arrayref_string_typetest1(5)), "\n";'
    lives_and(    # THVRVAVRVPV70
        sub {
            is_deeply(
                hashref_arrayref_string_typetest1(5),
                {   
                    "$mode_tagline\_funkey0" => [ 'Jeffy Ten! (0, 0)/4', 'Jeffy Ten! (0, 1)/4', 'Jeffy Ten! (0, 2)/4', 'Jeffy Ten! (0, 3)/4', 'Jeffy Ten! (0, 4)/4' ],
                    "$mode_tagline\_funkey1" => [ 'Jeffy Ten! (1, 0)/4', 'Jeffy Ten! (1, 1)/4', 'Jeffy Ten! (1, 2)/4', 'Jeffy Ten! (1, 3)/4', 'Jeffy Ten! (1, 4)/4' ],
                    "$mode_tagline\_funkey2" => [ 'Jeffy Ten! (2, 0)/4', 'Jeffy Ten! (2, 1)/4', 'Jeffy Ten! (2, 2)/4', 'Jeffy Ten! (2, 3)/4', 'Jeffy Ten! (2, 4)/4' ],
                    "$mode_tagline\_funkey3" => [ 'Jeffy Ten! (3, 0)/4', 'Jeffy Ten! (3, 1)/4', 'Jeffy Ten! (3, 2)/4', 'Jeffy Ten! (3, 3)/4', 'Jeffy Ten! (3, 4)/4' ],
                    "$mode_tagline\_funkey4" => [ 'Jeffy Ten! (4, 0)/4', 'Jeffy Ten! (4, 1)/4', 'Jeffy Ten! (4, 2)/4', 'Jeffy Ten! (4, 3)/4', 'Jeffy Ten! (4, 4)/4' ]
                },
                q{THVRVAVRVPV70 hashref_arrayref_string_typetest1(5) returns correct value}
            );
        },
        q{THVRVAVRVPV70 hashref_arrayref_string_typetest1(5) lives}
    );
}

done_testing();
