use Test::More tests => 6; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

my $l = $h->listAllRecords(
    'metadataPrefix'	=> 'oai_dc',
    'set'		=> 'lcposters'
);

SKIP: {
    my $HTE = HTE($l, $repo);
    skip $HTE, 4 if $HTE;

    subtest 'OAI request/response' => sub {
        plan tests => 5;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $repo, 'OAI response element text' );
        is($la{ verb }, 'ListRecords', 'OAI verb' );
        is($la{ metadataPrefix }, 'oai_dc', 'OAI metadata Prefix' );
        is($la{ set }, 'lcposters', 'OAI set' );
      };

    my $token = $l->resumptionToken();
    isa_ok( $token, 'Net::OAI::ResumptionToken' );

    subtest 'Collect result' => sub {
        my $count = 0;
        my (%oai_seen, %meta_seen);
        while ( my $r = $l->next() ) {
            isa_ok( $r, "Net::OAI::Record" );
            my $oid = $r->header()->identifier();
            ok( ! exists( $oai_seen{ $oid } ), "$oid not seen before" );
            $oai_seen{ $oid } = 1;
            my $mid = $r->metadata()->identifier();
            ok( $mid , "metadata contains dc:identifier" );
            ok( ! exists( $meta_seen{ $mid } ), "$mid not seen before" );
            $meta_seen{ $mid } = 1;

            $count++;
            last if $token ne $l->resumptionToken();
        }
        note("collected $count records from $repo");
    };

    ok( $l->resumptionToken(), 'listAllIdentifiers grabbed resumption token' );
}


sub HTE {
    my ($r, $url) = @_;
    my $hte;
    if ( my $e = $r->HTTPError() ) {
        $hte = "HTTP Error ".$e->status_line;
	$hte .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
	diag("LWP condition accessing $url:\n$hte");
        note explain $e;
      }
   return $hte;
}

