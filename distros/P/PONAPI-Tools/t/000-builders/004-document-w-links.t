#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document');
}

subtest '... creating a document with links' => sub {

    my $doc = PONAPI::Document::Builder::Document->new( version => '1.0' );
    isa_ok( $doc, 'PONAPI::Document::Builder::Document');
    does_ok($doc, 'PONAPI::Document::Builder');
    does_ok($doc, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Document::Builder::Role::HasMeta');

    $doc->add_meta( info => "test: document w/links" );
    $doc->add_links(
        self    => "http://example.com/articles/1",
        related => {
            href => "http://example.com/articles/1/author",
            meta => { info => "a meta info" }
        },
    );

    is_deeply(
        $doc->build,
        {
            jsonapi => { version => '1.0' },
            meta    => { info => "test: document w/links" },
            links   => {
                self    => "http://example.com/articles/1",
                related => {
                    href => "http://example.com/articles/1/author",
                    meta => { info => "a meta info" }
                },
            },
        },
        "... the document now has links",
    );

};

done_testing;
