#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Resource::Null');
}

subtest '... testing constructor' => sub {

    my $doc = PONAPI::Document::Builder::Resource::Null->new();

    isa_ok( $doc, 'PONAPI::Document::Builder::Resource::Null');
    does_ok($doc, 'PONAPI::Document::Builder');

    can_ok( $doc, 'build' );

};

subtest '... testing build output' => sub {

    my $doc = PONAPI::Document::Builder::Resource::Null->new();

    my $EXPECTED = undef;

    my $GOT = $doc->build;

    is( $GOT, $EXPECTED, 'null resource builds into undef' );

};

done_testing;
