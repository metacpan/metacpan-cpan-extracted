use Test::More tests => 6; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

my $l = $h->listAllIdentifiers(
    'metadataPrefix'	=> 'oai_dc',
    'set'		=> 'lcposters'
);

SKIP: {
    my $HTE = HTE($l, $repo);
    skip $HTE, 4 if $HTE;

    my $token = $l->resumptionToken();
    isa_ok( $token, 'Net::OAI::ResumptionToken' );

    subtest 'OAI request/response' => sub {
        plan tests => 5;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $repo, 'OAI response element text' );
        is($la{ verb }, 'ListIdentifiers', 'OAI verb' );
        is($la{ set }, 'lcposters', 'OAI set' );
        is($la{ metadataPrefix }, 'oai_dc', 'OAI metadata Prefix' );
     };

    subtest 'Collect identifiers' => sub {
        my %seen = ();
        my $count = 0;
        while ( my $i = $l->next() ) {
            $count++;
            isa_ok( $i, "Net::OAI::Record::Header" );
            my $id = $i->identifier();
            ok( ! exists( $seen{ $id } ), "$id not seen before" );
            $seen{ $id } = 1;
            last if $token ne $l->resumptionToken();
          };
        note "collected $count headers from $repo";
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

