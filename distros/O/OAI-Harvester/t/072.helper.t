use Test::More;
use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

my $repo = 'http://quod.lib.umich.edu/cgi/o/oai/oai';

eval 'use XML::LibXML::SAX::Builder';
if ( $@ ) {
  plan skip_all => "need XML::LibXML::SAX::Builder for this test"}
else {
  plan tests => 9};

use_ok( 'Net::OAI::Harvester' );
use_ok( 'Net::OAI::Record::DocumentHelper' );

my $h = new_ok('Net::OAI::Harvester' => [
    baseURL => $repo,
]);

my $builder = new_ok('XML::LibXML::SAX::Builder');
my $helper = new_ok('Net::OAI::Record::DocumentHelper' => [
    Handler => $builder,
    provideDocumentEvents => 1,
#   finalizeHook => sub {my ($builder) = @_; return $builder->result()->serialize()}
# serialize the fragment specified by the Document root in order to remove the XML declaration
    finalizeHook => sub {my ($builder, $result) = @_; return $result->getDocumentElement->serialize()}
]);

my $recordlist = $h->listRecords(
    metadataPrefix => 'marc21',
    set => 'hathitrust:ump',
    recordHandler => $helper
);

SKIP: {
    my $HTE = HTE($recordlist, $repo);
    skip $HTE, 4 if $HTE;
    
    ok( ! $recordlist->errorCode(), 'errorCode()' );
    if  ( $recordlist->errorCode() ) {
        diag "Received error: ".$recordlist->errorString();
      };
    ok( ! $recordlist->errorString(), 'errorString()' );

    my $rawresponse = $recordlist->xml();
    my $nsubdocs = () = ($rawresponse =~ /<record>/g);
    note "no of records in raw response: $nsubdocs";
    my $count = 0;
    subtest 'Collect Whatever' => sub {
        while( my $r = $recordlist->next() ) {
            $count++;
            isa_ok( $r, 'Net::OAI::Record' );

            my $header = $r->header();
            isa_ok( $header, 'Net::OAI::Record::Header' );
            ok( $header->identifier(), 
        	'header identifier defined: '.$header->identifier() );
            my $identifier;
            unless ( $identifier = $header -> identifier() ) {
                diag explain $header;
                diag "----";
              };

            my $record = $r->recorddata();
            isa_ok( $record, 'Net::OAI::Record::DocumentHelper' );
            my $result = $record->result();
            like($result, qr!>$identifier<!, "serialized response contains identifier $identifier");
            note "matched $identifier for record $count";
#           diag explain $result;
#           diag "====";
          }
        note "collected $count records from $repo";
        done_testing();
      };
  is($count, $nsubdocs, 'no of records and records events coincides');

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

