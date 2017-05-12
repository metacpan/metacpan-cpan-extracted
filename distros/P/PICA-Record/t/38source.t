#!perl -Tw

use strict;
use warnings;
use utf8;

use Test::More qw(no_plan);
use Encode;
use PICA::Source;

my %HTTPRESPONSE = (
    '12345' => '%1E021A+%1FaEine+%40Reise+in+den+Su%CC%88den%1E011%40+%1Fa2009',
    '0815' => '',
    '777' => '%1E',
);

no warnings 'redefine';
*LWP::Simple::get = sub($) { 
    my $ppn = shift; $ppn =~ s/.*PPN=([0-9]*[0-9xX])$/$1/;
    return $HTTPRESPONSE{$ppn}; 
};

#$HTTPRESPONSE = ;
my $source = PICA::Source->new( PSI => "http://example.com" );
my $record = $source->getPPN( 12345 );
is( "$record", "021A \$aEine \@Reise in den Süden\n011\@ \$a2009\n", 'getPPN via PSI' );

$record = $source->getPPN( '0815' );
is( $record, undef, "failed to get record" );
like( $@, qr/HTTP request failed/ );

$record = $source->getPPN( '777' );
is( $record, undef, "failed to get record" );
is( $@, "Failed to parse PICA::Record" );

#### SRU

use PICA::SRUSearchParser;
use PICA::XMLParser;

my $xml = do { local (@ARGV, $/) = "t/files/searchRetrieveResponse-1.xml"; <>; };

my $xmlparser = new PICA::XMLParser();
my $parser = PICA::SRUSearchParser->new( $xmlparser );
$parser->parse( $xml );

is( $parser->numberOfRecords, 2, 'SRU response' );
is( $parser->resultSetId, "SID68ddfabd-11a4S4" );
is( $parser->currentNumber, 2);
is( $xmlparser->counter(), 2 );


$parser = PICA::SRUSearchParser->new();
$xmlparser = $parser->parse( $xml );
is( $xmlparser->counter(), 2 );
is( $parser->currentNumber, 2);


*LWP::Simple::get = sub($) { return $xml; };

$source = PICA::Source->new( SRU => "http://example.com" );
my @records = $source->cqlQuery("pica.ppn=123")->records();
is( scalar @records, 2, 'SRU cql query' );

# differen SRU response
exit;
$xml = do { local (@ARGV, $/) = "t/files/searchRetrieveResponse-2.xml"; <>; };
print $xml;

$parser = PICA::SRUSearchParser->new();
$parser->parse( $xml );
is( $parser->numberOfRecords, 1, 'SRU response' );

# TODO: read from config file
