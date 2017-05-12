#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 143;

use Symbol::Util 'export_package', 'unexport_package';

{
    package Symbol::Util::Test80::Source1;
    no warnings 'once';
    sub FOO { "FOO" };
    our $FOO = "FOO";
    sub BAR { "BAR" };
    our $BAZ = "BAZ";
    our @BAZ = ("BAZ");
    our %BAZ = (BAZ => 1);
    open BAZ, __FILE__ or die $!;
    *BAZ = sub { "BAZ" };
};

no warnings 'once';

export_package("Symbol::Util::Test80::Target1", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR" ],
});
pass( 'export_package("Symbol::Util::Test80::Target1", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target1::FOO }, 'FOO', '&Symbol::Util::Test80::Target1::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target1->FOO }, 'FOO', 'Symbol::Util::Test80::Target1->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target1::FOO, '$Symbol::Util::Test80::Target1::FOO is ok [1]' );
is( eval { &Symbol::Util::Test80::Target1::BAR }, 'BAR', '&Symbol::Util::Test80::Target1::BAR is ok [1]' );
is( eval { Symbol::Util::Test80::Target1->BAR }, 'BAR', 'Symbol::Util::Test80::Target1->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target1::BAZ, '$Symbol::Util::Test80::Target1::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target1", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target1", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target1::FOO }, 'FOO', '&Symbol::Util::Test80::Target1::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target1->FOO }, 'Symbol::Util::Test80::Target1->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target1::FOO, '$Symbol::Util::Test80::Target1::FOO is ok [2]' );
is( eval { &Symbol::Util::Test80::Target1::BAR }, 'BAR', '&Symbol::Util::Test80::Target1::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target1->BAR }, 'Symbol::Util::Test80::Target1->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target1::BAZ, '$Symbol::Util::Test80::Target1::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target2", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR" ],
}, 'FOO');
pass( 'export_package("Symbol::Util::Test80::Target2", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target2::FOO }, 'FOO', '&Symbol::Util::Test80::Target2::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target2->FOO }, 'FOO', 'Symbol::Util::Test80::Target2->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target2::FOO, '$Symbol::Util::Test80::Target2::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target2::BAR }, '&Symbol::Util::Test80::Target2::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target2->BAR }, 'Symbol::Util::Test80::Target2->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target2::BAZ, '$Symbol::Util::Test80::Target2::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target2", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target2", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target2::FOO }, 'FOO', '&Symbol::Util::Test80::Target2::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target2->FOO }, 'Symbol::Util::Test80::Target2->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target2::FOO, '$Symbol::Util::Test80::Target2::FOO is ok [2]' );
ok( ! defined eval { &Symbol::Util::Test80::Target2::BAR }, '&Symbol::Util::Test80::Target2::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target2->BAR }, 'Symbol::Util::Test80::Target2->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target2::BAZ, '$Symbol::Util::Test80::Target2::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target3", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR" ],
}, '!BAR');
pass( 'export_package("Symbol::Util::Test80::Target3", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target3::FOO }, 'FOO', '&Symbol::Util::Test80::Target3::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target3->FOO }, 'FOO', 'Symbol::Util::Test80::Target3->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target3::FOO, '$Symbol::Util::Test80::Target3::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target3::BAR }, '&Symbol::Util::Test80::Target3::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target3->BAR }, 'Symbol::Util::Test80::Target3->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target3::BAZ, '$Symbol::Util::Test80::Target3::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target3", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target3", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target3::FOO }, 'FOO', '&Symbol::Util::Test80::Target3::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target3->FOO }, 'Symbol::Util::Test80::Target3->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target3::FOO, '$Symbol::Util::Test80::Target3::FOO is ok [2]' );
ok( ! defined eval { &Symbol::Util::Test80::Target3::BAR }, '&Symbol::Util::Test80::Target3::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target3->BAR }, 'Symbol::Util::Test80::Target3->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target3::BAZ, '$Symbol::Util::Test80::Target3::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target4", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR" ],
}, '/FOO/');
pass( 'export_package("Symbol::Util::Test80::Target4", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target4::FOO }, 'FOO', '&Symbol::Util::Test80::Target4::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target4->FOO }, 'FOO', 'Symbol::Util::Test80::Target4->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target4::FOO, '$Symbol::Util::Test80::Target4::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target4::BAR }, '&Symbol::Util::Test80::Target4::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target4->BAR }, 'Symbol::Util::Test80::Target4->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target4::BAZ, '$Symbol::Util::Test80::Target4::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target4", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target4", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target4::FOO }, 'FOO', '&Symbol::Util::Test80::Target4::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target4->FOO }, 'Symbol::Util::Test80::Target4->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target4::FOO, '$Symbol::Util::Test80::Target4::FOO is ok [2]' );
ok( ! defined eval { &Symbol::Util::Test80::Target4::BAR }, '&Symbol::Util::Test80::Target4::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target4->BAR }, 'Symbol::Util::Test80::Target4->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target4::BAZ, '$Symbol::Util::Test80::Target4::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target5", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR" ],
}, '!/BAR/');
pass( 'export_package("Symbol::Util::Test80::Target5", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target5::FOO }, 'FOO', '&Symbol::Util::Test80::Target5::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target5->FOO }, 'FOO', 'Symbol::Util::Test80::Target5->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target5::FOO, '$Symbol::Util::Test80::Target5::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target5::BAR }, '&Symbol::Util::Test80::Target5::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target5->BAR }, 'Symbol::Util::Test80::Target5->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target5::BAZ, '$Symbol::Util::Test80::Target5::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target5", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target5", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target5::FOO }, 'FOO', '&Symbol::Util::Test80::Target5::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target5->FOO }, 'Symbol::Util::Test80::Target5->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target5::FOO, '$Symbol::Util::Test80::Target5::FOO is ok [2]' );
ok( ! defined eval { &Symbol::Util::Test80::Target5::BAR }, '&Symbol::Util::Test80::Target5::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target5->BAR }, 'Symbol::Util::Test80::Target5->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target5::BAZ, '$Symbol::Util::Test80::Target5::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target6", "Symbol::Util::Test80::Source1", {
    OK => [ "FOO" ],
    TAGS => { T => [ "FOO" ] },
}, ':T');
pass( 'export_package("Symbol::Util::Test80::Target6", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target6::FOO }, 'FOO', '&Symbol::Util::Test80::Target6::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target6->FOO }, 'FOO', 'Symbol::Util::Test80::Target6->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target6::FOO, '$Symbol::Util::Test80::Target6::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target6::BAR }, '&Symbol::Util::Test80::Target6::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target6->BAR }, 'Symbol::Util::Test80::Target6->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target6::BAZ, '$Symbol::Util::Test80::Target6::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target6", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target6", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target6::FOO }, 'FOO', '&Symbol::Util::Test80::Target6::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target6->FOO }, 'Symbol::Util::Test80::Target6->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target6::FOO, '$Symbol::Util::Test80::Target6::FOO is ok [2]' );
ok( ! defined eval { &Symbol::Util::Test80::Target6::BAR }, '&Symbol::Util::Test80::Target6::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target6->BAR }, 'Symbol::Util::Test80::Target6->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target6::BAZ, '$Symbol::Util::Test80::Target6::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target7", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR" ],
    TAGS => { T => [ "BAR" ] },
}, '!:T');
pass( 'export_package("Symbol::Util::Test80::Target7", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target7::FOO }, 'FOO', '&Symbol::Util::Test80::Target7::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target7->FOO }, 'FOO', 'Symbol::Util::Test80::Target7->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target7::FOO, '$Symbol::Util::Test80::Target7::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target7::BAR }, '&Symbol::Util::Test80::Target7::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target7->BAR }, 'Symbol::Util::Test80::Target7->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target7::BAZ, '$Symbol::Util::Test80::Target7::BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target7", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target7", "Symbol::Util::Test80::Source1")' );

is( eval { &Symbol::Util::Test80::Target7::FOO }, 'FOO', '&Symbol::Util::Test80::Target7::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target7->FOO }, 'Symbol::Util::Test80::Target7->FOO is ok [2]' );
ok( ! defined $Symbol::Util::Test80::Target7::FOO, '$Symbol::Util::Test80::Target7::FOO is ok [2]' );
ok( ! defined eval { &Symbol::Util::Test80::Target7::BAR }, '&Symbol::Util::Test80::Target7::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target7->BAR }, 'Symbol::Util::Test80::Target7->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target7::BAZ, '$Symbol::Util::Test80::Target7::BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target8", "Symbol::Util::Test80::Source1", {
    OK => [ '$BAZ', '&BAZ' ],
}, '$BAZ', '&BAZ');
pass( 'export_package("Symbol::Util::Test80::Target8", "Symbol::Util::Test80::Source1")' );

is( $Symbol::Util::Test80::Target8::BAZ, 'BAZ', '$Symbol::Util::Test80::Target8::BAZ is ok [1]' );
is( eval { &Symbol::Util::Test80::Target8::BAZ }, 'BAZ', '&Symbol::Util::Test80::Target8::BAZ is ok [1]' );
is( eval { Symbol::Util::Test80::Target8->BAZ }, 'BAZ', 'Symbol::Util::Test80::Target8->BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target8", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target8", "Symbol::Util::Test80::Source1")' );

ok( ! defined $Symbol::Util::Test80::Target8::BAZ, '$Symbol::Util::Test80::Target8::BAZ is ok [2]' );
is( eval { &Symbol::Util::Test80::Target8::BAZ }, 'BAZ', '&Symbol::Util::Test80::Target8::BAZ is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target8->BAZ }, 'Symbol::Util::Test80::Target8->BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target9", "Symbol::Util::Test80::Source1", {
    OK => [ '@BAZ', '%BAZ', '*BAZ' ],
}, '@BAZ', '%BAZ', '*BAZ');
pass( 'export_package("Symbol::Util::Test80::Target9", "Symbol::Util::Test80::Source1")' );

is_deeply( [ @Symbol::Util::Test80::Target9::BAZ ], [ 'BAZ' ], '@Symbol::Util::Test80::Target9::BAZ is ok [1]' );
is_deeply( { %Symbol::Util::Test80::Target9::BAZ }, { BAZ => 1 }, '@Symbol::Util::Test80::Target9::BAZ is ok [1]' );
ok( defined *Symbol::Util::Test80::Target9::BAZ{IO}, '*Symbol::Util::Test80::Target9::BAZ{IO} is ok [1]' );

unexport_package("Symbol::Util::Test80::Target9", "Symbol::Util::Test80::Source1");
pass( 'unexport_package("Symbol::Util::Test80::Target9", "Symbol::Util::Test80::Source1")' );

ok( ! @Symbol::Util::Test80::Target9::BAZ, '@Symbol::Util::Test80::Target9::BAZ is ok [2]' );
ok( ! %Symbol::Util::Test80::Target9::BAZ, '%Symbol::Util::Test80::Target9::BAZ is ok [2]' );
ok( ! defined *Symbol::Util::Test80::Target9::BAZ{IO}, '*Symbol::Util::Test80::Target9::BAZ{IO} is ok [2]' );

{
    package Symbol::Util::Test80::Source2;
    no warnings 'once';
    sub FOO { "FOO" };
    our $FOO = "FOO";
    sub BAR { "BAR" };
    our $BAZ = "BAZ";
    our @BAZ = ("BAZ");
    our %BAZ = (BAZ => 1);
    open BAZ, __FILE__ or die $!;
    *BAZ = sub { "BAZ" };
    our @EXPORT = qw( FOO  BAR );
    our @EXPORT_OK = qw ( BAZ );
    our %EXPORT_TAGS = ( T => [ qw( BAR ) ] );
};

export_package("Symbol::Util::Test80::Target10", "Symbol::Util::Test80::Source2",
    'FOO', ':T', 'BAZ'
);
pass( 'export_package("Symbol::Util::Test80::Target10", "Symbol::Util::Test80::Source2")' );

is( eval { &Symbol::Util::Test80::Target10::FOO }, 'FOO', '&Symbol::Util::Test80::Target10::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target10->FOO }, 'FOO', 'Symbol::Util::Test80::Target10->FOO is ok [1]' );
is( eval { &Symbol::Util::Test80::Target10::BAR }, 'BAR', '&Symbol::Util::Test80::Target10::BAR is ok [1]' );
is( eval { Symbol::Util::Test80::Target10->BAR }, 'BAR', 'Symbol::Util::Test80::Target10->BAR is ok [1]' );
is( eval { &Symbol::Util::Test80::Target10::BAZ }, 'BAZ', '&Symbol::Util::Test80::Target10::BAZ is ok [1]' );
is( eval { Symbol::Util::Test80::Target10->BAZ }, 'BAZ', 'Symbol::Util::Test80::Target10->BAZ is ok [1]' );

unexport_package("Symbol::Util::Test80::Target10", "Symbol::Util::Test80::Source2");
pass( 'unexport_package("Symbol::Util::Test80::Target10", "Symbol::Util::Test80::Source2")' );

is( eval { &Symbol::Util::Test80::Target10::FOO }, 'FOO', '&Symbol::Util::Test80::Target10::FOO is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target10->FOO }, 'Symbol::Util::Test80::Target10->FOO is ok [2]' );
is( eval { &Symbol::Util::Test80::Target10::BAR }, 'BAR', '&Symbol::Util::Test80::Target10::BAR is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target10->BAR }, 'Symbol::Util::Test80::Target10->BAR is ok [2]' );
is( eval { &Symbol::Util::Test80::Target10::BAZ }, 'BAZ', '&Symbol::Util::Test80::Target10::BAZ is ok [2]' );
ok( ! defined eval { Symbol::Util::Test80::Target10->BAZ }, 'Symbol::Util::Test80::Target10->BAZ is ok [2]' );

export_package("Symbol::Util::Test80::Target11", "Symbol::Util::Test80::Source1", {
    EXPORT => [ "FOO", "BAR", "BAZ" ],
}, '');
pass( 'export_package("Symbol::Util::Test80::Target11", "Symbol::Util::Test80::Source1")' );

ok( ! defined eval { &Symbol::Util::Test80::Target11::FOO }, '&Symbol::Util::Test80::Target11::FOO is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target11->FOO }, 'Symbol::Util::Test80::Target11->FOO is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target11::FOO, '$Symbol::Util::Test80::Target11::FOO is ok [1]' );
ok( ! defined eval { &Symbol::Util::Test80::Target11::BAR }, '&Symbol::Util::Test80::Target11::BAR is ok [1]' );
ok( ! defined eval { Symbol::Util::Test80::Target11->BAR }, 'Symbol::Util::Test80::Target11->BAR is ok [1]' );
ok( ! defined $Symbol::Util::Test80::Target11::BAZ, '$Symbol::Util::Test80::Target11::BAZ is ok [1]' );


# Check bug if $1 was previously set
{
    my $a = "defined";
    $a =~ /(.*)/;
    is( $1, "defined", '$1 is defined');
    eval {
        export_package("Symbol::Util::Test80::Target12", "Symbol::Util::Test80::Source1", {
            EXPORT => [ "FOO" ],
        });
    };
    is( $@, '', 'export_package("Symbol::Util::Test80::Target12", "Symbol::Util::Test80::Source1")' );
};

is( eval { &Symbol::Util::Test80::Target12::FOO }, 'FOO', '&Symbol::Util::Test80::Target12::FOO is ok [1]' );
is( eval { Symbol::Util::Test80::Target12->FOO }, 'FOO', 'Symbol::Util::Test80::Target12->FOO is ok [1]' );


# exported element have to be in EXPORT or EXPORT_OK
eval {
    export_package("Symbol::Util::Test80::Target01", "Symbol::Util::Test80::Source1", {
        EXPORT => [ "FOO" ],
    }, 'BAR');
};
like( $@, qr/^BAR is not exported/, 'export_package("Symbol::Util::Test80::Target01", "Symbol::Util::Test80::Source1")' );

# EXPORT_TAGS element have to be also in EXPORT or EXPORT_OK
eval {
    export_package("Symbol::Util::Test80::Target02", "Symbol::Util::Test80::Source1", {
        TAGS => { T => [ "FOO" ] },
    }, ':T');
};
like( $@, qr/^FOO is not exported/, 'export_package("Symbol::Util::Test80::Target02", "Symbol::Util::Test80::Source1")' );

# Unknown tag
eval {
    export_package("Symbol::Util::Test80::Target03", "Symbol::Util::Test80::Source1", {
    }, ':T');
};
like( $@, qr/is not a tag of/, 'export_package("Symbol::Util::Test80::Target03", "Symbol::Util::Test80::Source1")' );

# Unknown symbol
eval {
    export_package("Symbol::Util::Test80::Target04", "Symbol::Util::Test80::Source1", {
        OK => [ '#FOO' ],
    }, '#FOO');
};
like( $@, qr/Can.t export symbol/, 'export_package("Symbol::Util::Test80::Target04", "Symbol::Util::Test80::Source1")' );
