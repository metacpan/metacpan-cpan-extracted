#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document');
}

subtest '... testing constructor' => sub {

    my $doc = PONAPI::Document::Builder::Document->new( version => '1.0' );
    isa_ok( $doc, 'PONAPI::Document::Builder::Document');
    does_ok($doc, 'PONAPI::Document::Builder');
    does_ok($doc, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($doc, 'PONAPI::Document::Builder::Role::HasMeta');

    ok(!$doc->is_collection, '... this document is not a collection');

    ok(!$doc->has_resource, '... the document does not have a resource');
    ok(!$doc->has_resources, '... the document does not have a resource');

    my $r = $doc->add_resource( type => 'article', id => 10 );
    isa_ok($r, 'PONAPI::Document::Builder::Resource');

    like(
        exception { $doc->add_resource( type => 'article', id => 11 ) },
        qr/^Cannot add more then one resource unless the Document is in collection mode/,
        '... could not add another resource with not a collection'
    );

    ok($doc->has_resource, '... the document now has a resource');
    ok(!$doc->has_resources, '... the document does not have a resource');

    is_deeply(
        $doc->build,
        {
            jsonapi => { version => '1.0' },
            data    => { type => 'article', id => 10 },
        },
        '... got the build product we expected'
    );

};

done_testing;
