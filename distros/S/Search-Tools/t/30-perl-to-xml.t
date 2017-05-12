#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 10;
use Data::Dump qw( dump );
use Search::Tools::XML;
my $utils = 'Search::Tools::XML';

{

    package My::Blessed::Object;
    use overload
        '""'     => sub { ref shift },
        fallback => 1;
}

my $data1 = {
    foo   => 'bar',
    array => [
        'one' => 1,
        'two' => 2,
    ],
    hash => {
        three => 3,
        four  => 4,
    },
};

ok( my $data1_xml = $utils->perl_to_xml( $data1, 'data1' ), "data1 to xml" );
like( $data1_xml, qr(<three>3</three>), "data1 xml" );

#diag( $utils->tidy($data1_xml) );

my $data2 = {
    arrays => [
        {   two   => 2,
            three => 3,
        },
        {   four => 4,
            five => 5,
        },
        {   foos => [
                {   depth => 2,
                    more  => 'here',
                }
            ],
        },
        bless( {}, "My::Blessed::Object" ),
        'red', 'blue',
    ],
};

# exercise $strip_plural
ok( my $data2_xml = $utils->perl_to_xml( $data2, 'data2', 1 ),
    "data2 to xml" );

#diag( $utils->tidy($data2_xml) );

like( $data2_xml, qr(<arrays count="6">),       "data2 xml" );
like( $data2_xml, qr(<foos count="1">.*?<foo>), "data2 xml" );
like(
    $data2_xml,
    qr(<array>My::Blessed::Object</array>),
    "data2 xml blessed object"
);

################
# new style
ok( my $data2_xml_new = $utils->perl_to_xml(
        $data2,
        {   root         => 'data2',
            wrap_array   => 0,
            strip_plural => 1,
        }
    ),
    "new style perl_to_xml with wrap_array=>0"
);

#diag( $utils->tidy($data2_xml_new) );
like( $data2_xml_new, qr(<array>red</array>),
    "plural stripped in new style" );
unlike( $data2_xml_new, qr(<arrays ), "wrap_array respected" );

ok( my $data3_xml_new = $utils->perl_to_xml(
        $data2,
        {   root => {
                tag   => 'fields',
                attrs => { xmlns => 'http://dezi.org/sos/schema' },
            },
            escape       => 0,
            strip_plural => 0
        },
    ),
    "root value == hashref"
);

#diag( dump $data3_xml_new );

