use warnings;
use strict;

use Test::More tests => 11;
use RDF::Sesame;

SKIP: {
    my $uri    = $ENV{SESAME_URI};
    my $r_name = $ENV{SESAME_REPO};
    skip 'SESAME_URI environment not set', 11  unless $uri;
    skip 'SESAME_REPO environment not set', 11 unless $r_name;

    my $conn = RDF::Sesame->connect( uri => $uri );

    die "No connection: $RDF::Sesame::errstr\n" unless defined($conn);

    my $repo = $conn->open($r_name);

    # make sure there's no old data in there
    $repo->clear;

    $repo->upload_uri( 'file:t/dc.rdf' );

    my $serql = q{
        SELECT
            "a",
            "b"@en-us,
            "c"^^<http://example.com/#foo>,
            <http://example.org>,
            _:b123
    };

    ###### Verify the behavior of the 'strip' option

    ### default
    my $res = $repo->select($serql);
    my @row = $res->each;
    is_deeply(
        \@row,
        [
            q{"a"},
            q{"b"@en-us},
            q{"c"^^<http://example.com/#foo>},
            q{<http://example.org>},
            q{_:b123},
        ],
        'default'
    );

    # test strip in each of the table results formats
    for my $format ( '', 'xml', 'binary' ) {
        ### literals
        $res = $repo->select(
            query=>$serql,
            strip=>'literals',
            ( $format ? (format=>$format) : () ),
        );
        is_deeply(
            [ $res->each() ],
            [
                q{a},
                q{b},
                q{c},
                q{<http://example.org>},
                q{_:b123},
            ],
            "$format: literals"
        );

        ### urirefs
        $res = $repo->select(
            query=>$serql,
            strip=>'urirefs',
            ( $format ? (format=>$format) : () ),
        );
        is_deeply(
            [ $res->each ],
            [
                q{"a"},
                q{"b"@en-us},
                q{"c"^^<http://example.com/#foo>},
                q{http://example.org},
                q{_:b123},
            ],
            "$format: urirefs"
        );

        ### all
        $res = $repo->select(
            query=>$serql,
            strip=>'all',
            ( $format ? (format=>$format) : () ),
        );
        is_deeply(
            [ $res->each ],
            [
                q{a},
                q{b},
                q{c},
                q{http://example.org},
                q{_:b123},
            ],
            "$format: all"
        );
    }

    ###### Verify setting the default for strip

    $repo = $conn->open( id => $r_name, strip => 'all');
    $res = $repo->select($serql);
    is_deeply(
        [ $res->each ],
        [
            q{a},
            q{b},
            q{c},
            q{http://example.org},
            q{_:b123},
        ],
        'setting default through open()'
    );



    # don't leave our junk lying around
    $repo->clear;
}

