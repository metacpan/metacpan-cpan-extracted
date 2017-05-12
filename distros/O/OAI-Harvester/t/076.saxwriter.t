use Test::More;
use lib qw( t );
use utf8;
use open IO => ':encoding(utf8)';
use strict;
use warnings;

eval 'use XML::SAX::Writer';
if ( $@ ) {
  plan skip_all => "need XML::SAX::Writer for this test"}
else {
  plan tests => 25};

$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );
use_ok( 'Net::OAI::Record::NamespaceFilter' );

use constant XMLNS_OAIDC => "http://www.openarchives.org/OAI/2.0/oai_dc/";

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $id = 'oai:lcoa1.loc.gov:loc.gmd/g3764s.pm003250';

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

# Method 1: already instantiated Handler

my $xmlstring = "";          
open my $fh, ">:utf8", \$xmlstring;

my $catcher = XML::SAX::Writer->new(Output => $fh);
my $filter1 = Net::OAI::Record::NamespaceFilter->new(
    XMLNS_OAIDC() => $catcher
  );
isa_ok($filter1, 'Net::OAI::Record::NamespaceFilter');

$catcher->start_document({});
my $single1 = $h->getRecord(
    metadataPrefix => 'oai_dc',
    metadataHandler => $filter1,
    identifier => $id,
);
isa_ok( $single1, 'Net::OAI::GetRecord' );
SKIP: {
    my $HTE = HTE($single1, $repo);
    skip $HTE, 7 if $HTE;

    $catcher->end_document({});
    close($fh);

    note "RAW1: ".$single1->xml();
    note "PARSED: $xmlstring";

    ok( ! $single1->errorCode(), 'errorCode()' );
    ok( ! $single1->errorString(), 'errorString()' );

    my $contents1 = $single1->record();
    isa_ok( $contents1, 'Net::OAI::Record' );
    my $object1 = $contents1->metadata();
    isa_ok( $object1, 'Net::OAI::Record::NamespaceFilter' );

    like($xmlstring, qr!<(\w+:)?identifier>http://hdl.loc.gov/loc\.gmd/g3764s\.pm003250</(\w+:)?identifier>!, 'string output contains expected identifier');

    my $resultref1 = $object1->result();
    is(ref($resultref1), "HASH", "result method w/o arguments is working");
    note explain $resultref1;
    my $string1 = $object1->result(XMLNS_OAIDC);
    ok(! defined $string1, "result method is working for single ns");
}

## Method 2: Coderef as constructor

my $listfilter = Net::OAI::Record::NamespaceFilter->new(
       XMLNS_OAIDC() => sub {my $buffer = ''; return XML::SAX::Writer->new(Output => \$buffer)}
  );
isa_ok($listfilter, 'Net::OAI::Record::NamespaceFilter');

my $list = $h->listRecords(
    metadataPrefix => 'oai_dc',
    metadataHandler => $listfilter,
  );
isa_ok( $list, 'Net::OAI::ListRecords' );
SKIP: {
    my $HTE = HTE($list, $repo);
    skip $HTE, 3 if $HTE;

    ok( ! $single1->errorCode(), 'errorCode()' );
    ok( ! $single1->errorString(), 'errorString()' );

    my $raw = $list->xml();
    note "RAW2: ".$list->xml();
    my %rawids;
    while ( $raw =~ m!<dc:identifier>([^<]+)</dc:identifier>!g ) {
        $rawids{$1}++};

    my $count = 0;
    my %ids;
    my $idcount = 0;
    subtest 'Get some records with custom filter' => sub {
      while( my $r = $list->next() ) {
        $count++;
        note "processing record $count";
        isa_ok( $r, 'Net::OAI::Record' );

        my $header = $r->header();
        isa_ok( $header, 'Net::OAI::Record::Header' );
        ok( $header->identifier(), 'header identifier defined: '.$header->identifier() );
        unless ( $header -> identifier() ) {
            diag explain $header;
            diag "----";
          };

        my $data = $r->metadata();
        ok( defined $data, 'custom handler does deliver metadata' );
        isa_ok( $data, 'Net::OAI::Record::NamespaceFilter' );

        my $xmlref = $data->result(XMLNS_OAIDC);
        ok(defined $xmlref, "ns handler has a result");
        is(ref($xmlref), "SCALAR", "ns handler provides a string reference");
        my $xml = $$xmlref;          
        ok(defined $xml, "handler result is a string");
        like($xml, qr!<((?:\w+:)?title)>[^<]+</(\1)>!, 'string output contains dc:title');
        while ( $xml =~ m!<(?:\w+:)?identifier>([^<]+)</(\w+:)?identifier>!g ) {
            $ids{$1}++;
            $idcount ++;
          };
        note "raw: $xml";
        note "====";
      }
    my $distinctids = scalar keys %ids;
    note "collected $count records with $distinctids different ids from $repo";
    my $distinctrawids = scalar keys %rawids;
    is($distinctids, $distinctrawids, "collected records have expected number of differentd ids");
    done_testing();
  };
  note "collected $count records from $repo";
# is($count, $nsubdocs, 'no of records and record events coincides');
  };

### Method 3: class name

# XML::SAX::Writer cannot be used directly since it does not use XML::SAX::Base for base class

my $filter3 = Net::OAI::Record::NamespaceFilter->new(
    '*' => 'MyWriter'
  );
isa_ok($filter3, 'Net::OAI::Record::NamespaceFilter');

my $single3 = $h->getRecord(
    metadataPrefix => 'oai_dc',
    recordHandler => $filter3,
    identifier => $id,
);
isa_ok( $single3, 'Net::OAI::GetRecord' );
SKIP: {
    my $HTE = HTE($single3, $repo);
    skip $HTE, 6 if $HTE;

    note "RAW3: ".$single3->xml();

    ok( ! $single3->errorCode(), 'errorCode()' );
    ok( ! $single3->errorString(), 'errorString()' );

    my $contents3 = $single3->record();
    isa_ok( $contents3, 'Net::OAI::Record' );

    my $object3 = $contents3->recorddata();
    isa_ok( $object3, 'Net::OAI::Record::NamespaceFilter' );

    my $resultref3 = $object3->result();
    is(ref($resultref3), "HASH", "result method w/o arguments is working");
    note explain $resultref3;

    my $collectedref = $object3->result('*');
    like($$collectedref, qr!<(\w+:)?identifier>http://hdl.loc.gov/loc\.gmd/g3764s\.pm003250</(\w+:)?identifier>!, 'string output contains expected identifier');
  };


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

