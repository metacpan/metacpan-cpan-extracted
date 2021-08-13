## Please see file perltidy.ERR
## Please see file perltidy.ERR
## Please see file perltidy.ERR
#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use TOML::XS;

my $toml = <<END;
# This is a TOML document

"Löwe" = "Löwe"
boolean = false
integer = 123
double = 34.5
timestamp = 1979-05-27T07:32:00-08:00
somearray = []

[checkextra]
"Löwe" = "Löwe"
alltypes = [ "a string", true, false, 123, 34.5, 1979-05-27T07:32:00-08:00, {} ]
boolean = false
integer = 123
double = 34.5
timestamp = 1979-05-27T07:32:00-08:00
END

my $the_timestamp_cmp = all(
    Isa('TOML::XS::Timestamp'),
    methods(
        to_string    => '1979-05-27T07:32:00-08:00',
        year         => 1979,
        month        => 5,
        day          => 27,
        date         => 27,
        hour         => 7,
        hours        => 7,
        minute       => 32,
        second       => 0,
        millisecond  => undef,
        milliseconds => undef,
        timezone     => '-08:00',
    ),
);

my $docobj = TOML::XS::from_toml($toml);

my $struct_cmp = {
    "L\xf6we" => "L\xf6we",
    boolean   => TOML::XS::false,
    integer   => 123,
    double    => 34.5,
    timestamp => $the_timestamp_cmp,
    somearray => [],

    checkextra => {
        "L\xf6we"  => "L\xf6we",
        boolean    => TOML::XS::false,
        integer    => 123,
        double     => 34.5,
        timestamp  => $the_timestamp_cmp,
        'alltypes' => [
            'a string',
            TOML::XS::true,
            TOML::XS::false,
            123,
            '34.5',
            $the_timestamp_cmp,
            {},
        ],
    },
};

my $struct = $docobj->parse();

cmp_deeply(
    $struct,
    $struct_cmp,
    'struct as expected',
) or diag explain $struct;

is(
    $docobj->parse("L\xf6we"),
    "L\xf6we",
    'non-ASCII pointer',
);

eval { diag explain $docobj->parse('timestamp', 'foo') };
my $err = $@;

like( $err, qr<timestamp>, 'JSON pointer in too-deep error' );
unlike( $err, qr<timestamp/foo>, 'JSON pointer in too-deep error (no too-deep element)' );

#----------------------------------------------------------------------
eval { diag explain $docobj->parse('checkextra', undef) };
$err = $@;

like( $err, qr<1>, 'Undef in pointer triggers exception (table)' );

eval { diag explain $docobj->parse('checkextra', 'alltypes', undef) };
$err = $@;

like( $err, qr<2>, 'Undef in pointer triggers exception (array)' );

#----------------------------------------------------------------------
eval { diag explain $docobj->parse('checkextra', "\xf6\xf6\xf6") };
$err = $@;

like( $err, qr<checkextra/\xf6\xf6\xf6>, 'pointer refers to nonexistent table key' );

#----------------------------------------------------------------------
eval { diag explain $docobj->parse('checkextra', 'alltypes', "\xf6\xf6\xf6") };
$err = $@;

like( $err, qr<checkextra/alltypes>, 'pointer is non-numeric into array' );
unlike( $err, qr<checkextra/alltypes/\xf6\xf6\xf6>, 'pointer is non-numeric into array - JSON pointer is to the array' );
like( $err, qr<\xf6\xf6\xf6>, 'non-numeric array index' );

#----------------------------------------------------------------------
cmp_deeply(
    $docobj->parse('checkextra', 'alltypes', 6),
    {},
    'fetch last array element',
);

eval { diag explain $docobj->parse('checkextra', 'alltypes', 7) };
$err = $@;

like( $err, qr<checkextra/alltypes/7>, 'excess array index' );
like( $err, qr<6>, 'max index given' );

done_testing;
