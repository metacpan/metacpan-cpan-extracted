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

    my $r = $doc->add_null_resource();
    isa_ok($r, 'PONAPI::Document::Builder::Resource::Null');

    ok($doc->has_resource, '... the document now has a resource');
    ok(!$doc->has_resources, '... the document does not have multiple resource');

    is_deeply(
        $doc->build,
        {
            jsonapi => { version => '1.0' },
            data    => undef,
        },
        '... got the build product we expected'
    );

};

done_testing;
