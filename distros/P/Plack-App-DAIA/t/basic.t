use strict;
use warnings;
use v5.10.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::App::DAIA;
use DAIA;

my $app = Plack::App::DAIA->new;

test_psgi $app, sub {
        my $cb  = shift;

        my $res = $cb->(GET "/?id=abc");
        my $daia = eval { DAIA::parse_xml( $res->content ); };
        isa_ok( $daia, 'DAIA::Response' );
        like( $res->content, qr{^<\?xml.*xmlns}s, 'XML header and namespace' );

        $res = $cb->(GET "/?id=abc&format=json");
        $daia = eval { DAIA::parse_json( $res->content ); };
        isa_ok( $daia, 'DAIA::Response' );

        $res = $cb->(GET "/?id=abc&format=json&callback=xyz");
        my $jsonp = $res->content;
        like( $jsonp, qr{xyz\(.+\)\s*$}ms, 'JSONP callback' );
        $jsonp =~ s{xyz\((.+)\)\s*$}{$1}ms;
        $daia = eval { DAIA::parse_json( $jsonp ); };
        isa_ok( $daia, 'DAIA::Response' );

        $res = $cb->(GET "/?id=x");
        $daia = eval { DAIA::parse( $res->content ); };
        like( $daia->json, qr{"please provide an explicit parameter format=xml"}m, "missing format" );

        $res = $cb->(GET "/?id=x\ny&format=xml");
        $daia = eval { DAIA::parse( $res->content ); };
        like( $daia->json, qr{"unknown identifier format"}m, "invalid identifier" );

        $res = $cb->(GET "/?id=&format=XML");
        $daia = eval { DAIA::parse( $res->content ); };
        like( $daia->json, qr{"please provide a document identifier"}m, "missing identifier" );
        unlike( $daia->json, qr{"please provide an explicit parameter format=xml"}m, "format given" );
    };

$app = Plack::App::DAIA->new( code => sub { } ); # returns undef
test_psgi $app, sub {
        my $cb  = shift;

        my $res = $cb->(GET "/?id=my:id&format=json");
        my $daia = eval { DAIA::parse( $res->content ); };
        is( $res->code, 500, "undefined response" );
        ok( $daia, "empty response" );
};

$app = Plack::App::DAIA->new( code => sub {
    my ($id, %parts) = @_;
    my $daia = DAIA::Response->new;
    $daia->document( id => $parts{local} . ':' . $parts{prefix} );
}, idformat => qr{ ^ (?<prefix>[a-z]+) : (?<local>.+) $ }x );

test_psgi $app, sub {
        my $cb  = shift;

        my $res = $cb->(GET "/?id=foo:bar&format=json");
        is( $res->code, 200, "found" );

        my $daia = eval { DAIA::parse( $res->content ); };
        my ($doc) = $daia->document;
        is( $doc->id, 'bar:foo', 'named capturing groups' );
};

done_testing;
