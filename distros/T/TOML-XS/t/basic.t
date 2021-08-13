#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use TOML::XS;

my $doc = <<END;
# This is a TOML document

title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00

[database]
enabled = true
ports = [ 8000, 8001, 8002 ]
data = [ ["delta", "phi"], [3.14] ]
temp_targets = { cpu = 79.5, case = 72.0 }

[servers]

[servers.alpha]
ip = "10.0.0.1"
role = "frontend"

[servers.beta]
ip = "10.0.0.2"
role = "backend"

[checkextra]
fluff = "épée"
alltypes = [ "a string", true, false, 123, 34.5, 1979-05-27T07:32:00-08:00, {} ]
boolean = false
integer = 123
double = 34.5
timestamp = 1979-05-27T07:32:00-08:00
END

my $docobj = TOML::XS::from_toml($doc);

my $struct = $docobj->to_struct();

my $round_floats = $Config{'uselongdouble'} || $Config{'usequadmath'};

my $the_timestamp_cmp = all(
    Isa('TOML::XS::Timestamp'),
    methods(
        to_string => '1979-05-27T07:32:00-08:00',
        year => 1979,
        month => 5,
        day => 27,
        date => 27,
        hour => 7,
        hours => 7,
        minute => 32,
        second => 0,
        millisecond => undef,
        milliseconds => undef,
        timezone => '-08:00',
    ),
);

my $struct_cmp = {
        'database' => {
            'data' => [
                [
                    'delta',
                    'phi'
                ],
                [ $round_floats ? num(3.14, 0.0001) : 3.14 ]
            ],
            'enabled' => TOML::XS::true,
            'ports'   => [
                8000,
                8001,
                8002
            ],
            'temp_targets' => {
                'case' => 72,
                'cpu'  => 79.5,
            }
        },
        'owner' => {
            'name' => 'Tom Preston-Werner',
            'dob'  => $the_timestamp_cmp,
        },
        'servers' => {
            'alpha' => {
                'ip'   => '10.0.0.1',
                'role' => 'frontend'
            },
            'beta' => {
                'ip'   => '10.0.0.2',
                'role' => 'backend'
            }
        },
        'title' => 'TOML Example',
   'checkextra' => {
     'fluff' => "\x{e9}p\x{e9}e",
     'alltypes' => [
       'a string',
       TOML::XS::true,
       TOML::XS::false,
       123,
       '34.5',
       $the_timestamp_cmp,
       {},
     ],
     boolean => TOML::XS::false,
     integer => 123,
     double => 34.5,
     timestamp => $the_timestamp_cmp,
   },
    };

cmp_deeply(
    $struct,
    $struct_cmp,
    'struct as expected',
) or diag explain $struct;

{
    eval { TOML::XS::from_toml("$doc\0") };
    my $err          = $@;
    diag $err;
    my $expect_index = length $doc;
    like( $err, qr<NUL>,           'reject null bytes in the TOML string' );
    like( $err, qr<$expect_index>, '… and the error says where the NUL is' );
}

{
    eval { TOML::XS::from_toml("$doc\xff") };
    my $err          = $@;
    diag $err;
    my $expect_index = length $doc;
    like( $err, qr<UTF>,           'reject non-UTF8 in the TOML string' );
    like( $err, qr<$expect_index>, '… and the error says where the non-UTF8 is' );
}

{
    eval { TOML::XS::from_toml("blahblahblah") };
    my $err          = $@;
    diag $err;
    like( $err, qr<.>,           'reject nonsense' );
}

{
    my $checkextra = $docobj->parse('checkextra');
    cmp_deeply(
        $checkextra,
        $struct_cmp->{'checkextra'},
        'parse() - single pointer item',
    );

    for my $ce_piece (sort keys %{ $struct_cmp->{'checkextra'} }) {
        my $parsed = $docobj->parse('checkextra', $ce_piece);
        cmp_deeply(
            $parsed,
            $struct_cmp->{'checkextra'}{$ce_piece},
            "parse(checkextra, $ce_piece)",
        );
    }

    for my $i ( 0 .. $#{ $struct_cmp->{'checkextra'}{'alltypes'} } ) {
        my $parsed = $docobj->parse('checkextra', 'alltypes', $i);
        cmp_deeply(
            $parsed,
            $struct_cmp->{'checkextra'}{'alltypes'}[$i],
            "parse(checkextra, alltypes, $i)",
        );

        $parsed = $docobj->parse('checkextra', 'alltypes', "$i");
        cmp_deeply(
            $parsed,
            $struct_cmp->{'checkextra'}{'alltypes'}[$i],
            qq<parse(checkextra, alltypes, "$i")>,
        );
    }
}

done_testing;
