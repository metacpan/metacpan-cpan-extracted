#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document');
}

subtest '... adding pagination link' => sub {

    my $doc = PONAPI::Document::Builder::Document->new( version => '1.0', is_collection => 1 );
    isa_ok( $doc, 'PONAPI::Document::Builder::Document');
    ok($doc->is_collection, '... this document is a collection');

    # valid self link
    {
        $doc->add_pagination_links( self => { page => "SELF", offset => 0 } );
        is_deeply(
            $doc->build,
            {
                jsonapi => { version => '1.0' },
                data    => [],
                links   => { self => '/?page%5Boffset%5D=0&page%5Bpage%5D=SELF' },
            },
            '... successfully added a pagination self link'
        );
    }

    # valid self link
    {
        $doc->add_pagination_links( current => { page => "CURRENT", offset => 3 } );
        is_deeply(
            $doc->build,
            {
                jsonapi => { version => '1.0' },
                data    => [],
                links   => { self => '/?page%5Boffset%5D=3&page%5Bpage%5D=CURRENT' },
            },
            '... successfully added a pagination current (self) link'
        );
    }

    # invalid name
    my $e;
    eval {
        $doc->add_pagination_links( blah => 1 );
        1;
    } or do {
        $e = $@ || "unknown error";
    };
    like( $e, qr/^Tried to add pagination link `blah`/, '... invalid pagination link member' );

};

done_testing;
