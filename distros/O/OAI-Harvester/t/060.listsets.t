use Test::More tests => 8; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

my $l = $h->listSets();
isa_ok( $l, 'Net::OAI::ListSets', 'listSets()' );

SKIP: {
    my $HTE = HTE($l, $repo);
    skip $HTE, 5 if $HTE;

    ok( ! $l->errorCode(), 'errorCode()' );
    ok( ! $l->errorString(), 'errorString()' );

    subtest 'OAI request/response' => sub {
        plan tests => 3;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $repo, 'OAI response element text' );
        is($la{ verb }, 'ListSets', 'OAI verb' );
      };

    my @specs = $l->setSpecs();
    ok( scalar(@specs) > 1, 'setSpecs() returns a list of specs' ); 

    subtest 'Enumerate SetSpecs' => sub {
        foreach (@specs ) { 
            ok( $l->setName( $_ ), "setName(\"$_\") = " . $l->setName( $_ ) );
          }
      };
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
