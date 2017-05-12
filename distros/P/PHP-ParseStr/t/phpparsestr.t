#!perl

use Test::More;
use Test::Deep;

use_ok "PHP::ParseStr", qw(php_parse_str);

my @cases = (
    {
        name => "Simple",
        in => "foo=1&bar=2&baz=3",
        out => {
            foo => 1,
            bar => 2,
            baz => 3,
        }
    },
    {
        name => "Hashes",
        in => "foo=1&bar[wibble]=2&baz[flubber][jibber]=3",
        out => {
            foo => 1,
            bar => {
                wibble => 2,
            },
            baz => {
                flubber => {
                    jibber => 3,
                }
            }
        }
    },
    {
        name => "Arrays",
        in => "foo=1&bar[0]=a&bar[1]=b&bar[2]=c&baz[4][2]=3",
        out => {
            foo => 1,
            bar => [qw( a b c )],
            baz => [ undef, undef, undef, undef, [ undef, undef, 3 ] ],
        }
    },
    {
        name => "Big nested structures",
        in => "foo=1&bar[stuff][3][things]=2&baz[4][gubbins][2]=3&baz[2][wotsits][7]=4&baz[7][widgits][1]=5&something=somethingelse",
        out => {
            'bar' => {
                'stuff' => [
                    undef,
                    undef,
                    undef,
                    {
                        'things' => '2'
                    }
                ]
            },
            'baz' => [
                undef,
                undef,
                {
                    'wotsits' => [
                        undef,
                        undef,
                        undef,
                        undef,
                        undef,
                        undef,
                        undef,
                        '4'
                    ]
                },
                undef,
                {
                    'gubbins' => [
                        undef,
                        undef,
                        '3'
                    ]
                },
                undef,
                undef,
                {
                    'widgits' => [
                        undef,
                        '5'
                    ]
                }
            ],
            'foo' => '1',
            'something' => 'somethingelse'
        }
    },
);

foreach my $case (@cases) {

    my $got = php_parse_str($case->{in});
    cmp_deeply $got, $case->{out}, $case->{name}
        or diag explain $got;
}

done_testing;
