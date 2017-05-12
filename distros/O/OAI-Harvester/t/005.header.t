use Test::More tests => 15;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $header1 = new_ok('Net::OAI::Record::Header');

# basic attributes

$header1->status( 'deleted' );
is( $header1->status(), 'deleted', 'status()' );

$header1->identifier( 'xxx' );
is( $header1->identifier(), 'xxx', 'identifier()' );

$header1->datestamp( 'May-28-1969' );
is( $header1->datestamp(), 'May-28-1969', 'datestatmp()' );

$header1->setSpecs( 'foo', 'bar' );
my @sets1 = $header1->setSpecs();
is( scalar(@sets1), 2, 'setSpecs() 1' );
is( $sets1[0], 'foo', 'setSpecs() 2' );
is( $sets1[1], 'bar', 'setSpecs() 3' );

## fetch a record and see what the status is
## this may need to be changed over time

use_ok( 'Net::OAI::Harvester' );

my $id = 'oai:eprints.dcs.warwick.ac.uk:399';
my $repo = 'http://eprints.dcs.warwick.ac.uk/cgi/oai2';

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

# this will fetch < http://eprints.dcs.warwick.ac.uk/cgi/oai2?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:eprints.dcs.warwick.ac.uk:399 >
# which hopefully exists and is an deleted record
my $r = $h->getRecord( identifier => $id, metadataPrefix => 'oai_dc' );

SKIP: {
    my $HTE = HTE($r, $repo);
    skip $HTE, 5 if $HTE;

    ok( ! $r->errorCode(), "errorCode()" );
    ok( ! $r->errorString(), "errorString()" );

    subtest 'OAI request/response' => sub {
        plan tests => 5;
        like($r->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );

        is($r->request(), $repo, 'scalar OAI response element text' );
        my ($rr, %ra) = $r->request();
        is($rr, $repo, 'OAI response element text' );
        is($ra{ verb }, 'GetRecord', 'OAI verb' );
        is($ra{ identifier }, $id, 'OAI identifier' );
      };

    my $header = $r->header();
    is( $header->identifier, $id, 'identifier()' );
    is( $header->status(), 'deleted', 'status' );
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

