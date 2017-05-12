use Test::More tests => 16;

use strict;
use warnings;

$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

my $l = $h->listRecords( metadataPrefix => 'oai_dc', set => 'papr' );
isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords()' );

SKIP: {
    my $HTE = HTE($l, $repo);
    skip $HTE, 9 if $HTE;

    ok( ! $l->errorCode(), 'errorCode()' );
    ok( ! $l->errorString(), 'errorString()' );

    subtest 'OAI request/response' => sub {
        plan tests => 5;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $repo, 'OAI response element text' );
        is($la{ verb }, 'ListRecords', 'OAI verb' );
        is($la{ metadataPrefix }, 'oai_dc', 'OAI metadata Prefix' );
        is($la{ set }, 'papr', 'OAI set' );
      };

    subtest 'Collect Result' => sub {

# per recipe in Test::More documentation: Get rid of "wide character in print" diagnostics
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

        my $count = 0;
        while ( my $r = $l->next() ) { 
            $count ++;
            isa_ok( $r, 'Net::OAI::Record' );
            my $header = $r->header();
            isa_ok( $header, 'Net::OAI::Record::Header' );
            ok( $header->identifier(), 
        	'header identifier defined: '.$header->identifier() );
            my $metadata = $r->metadata();
            isa_ok( $metadata, 'Net::OAI::Record::OAI_DC' );
            ok( $metadata->title(), 
        	'metadata title defined: '.$metadata->title() );
          }
        note "collected $count records from $repo";
        done_testing;
      };

## resumption token

    my $r = $l->resumptionToken();
    isa_ok( $r, 'Net::OAI::ResumptionToken' );
    ok( $r->token(), 'token() '.$r->token() );

## these may not return stuff but we must be able to call the methods
    eval { $r->expirationDate() }; 
    ok( ! $@, 'expirationDate()' );

    eval { $r->completeListSize() };
    ok( ! $@, 'completeListSize()' );

    eval { $r->cursor() };
    ok( ! $@, 'cursor()' );

}

use lib qw( t ); ## so harvester will be able to locate our handler

$l = $h->listRecords( 
    metadataPrefix  => 'oai_dc', 
    metadataHandler => 'MyMDHandler',
    set		    => 'papr' 
);

isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords() with metadataHandler' );

SKIP: {
    my $HTE = HTE($l, $repo);
    skip $HTE, 1 if $HTE;

    subtest 'Collect custom metadataHandler result' => sub {
        my $count = 0;
        while ( my $r = $l->next() ) {
            $count ++;
            isa_ok( $r, 'Net::OAI::Record' );
            my $header = $r->header();
            isa_ok( $header, 'Net::OAI::Record::Header' );
            my $metadata = $r->metadata();
            isa_ok( $metadata, 'MyMDHandler' );
            ok( ! defined $r->recorddata(), 'custom metadata handler does not deliver all record data' );
          };
        note "collected $count records from $repo";
      };
}


$l = $h->listRecords( 
    metadataPrefix  => 'oai_dc', 
    recordHandler => 'MyRCHandler',
    set		    => 'papr' 
);

isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords() with recordHandler' );

SKIP: {
    my $HTE = HTE($l, $repo);
    skip $HTE, 1 if $HTE;

    subtest 'Collect custom recordHandler result' => sub {
        my $count = 0;
        while ( my $r = $l->next() ) {
            $count ++;
            isa_ok( $r, 'Net::OAI::Record' );
            my $header = $r->header();
            isa_ok( $header, 'Net::OAI::Record::Header' );
            my $recorddata = $r->recorddata();
            isa_ok( $recorddata, 'MyRCHandler' );
            ok( ! defined $r->metadata(), 'custom record handler does not deliver metadata' );
            is($recorddata->OAIdentifier, $header->identifier, "collected OAI identifiers coincide for record $count");
          };
        note "collected $count records from $repo";
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

