use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use DAIA;
use Plack::App::DAIA;

my $app = Plack::App::DAIA->new(
    code => sub {
        my $id = shift;        
        my $daia = DAIA::Response->new;
        $daia->addDocument( id => $id );
        return $daia;
    }
);

test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET "/?id=my:abc");
        my $daia = eval { DAIA::parse_xml( $res->content ); };
        like( $res->content, qr{^<\?xml.*xmlns}s, 'XML header and namespace' );
        isa_ok( $daia, 'DAIA::Response' );
        ok( $daia->document, "has document" );
    };

done_testing;
