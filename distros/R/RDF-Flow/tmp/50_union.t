use strict;
use Test::More;

use RDF::Dumper;

use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
   -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace debug info error)] });

$Carp::Verbose = 1;
use diagnostics -traceonly;
#$ENV{GBVISIL2DB_UPTO} = 'TRACE';

use GBV::RDF::Source::Lobid;
use GBV::RDF::Source::DBInfo;
use GBV::RDF::Source::ISIL2Wikipedia;

use RDF::Source qw(union);

my $lobid_source = GBV::RDF::Source::Lobid->new;
my $gbv_source   = GBV::RDF::Source::DBInfo->new;
my $isil2wikipedia = GBV::RDF::Source::ISIL2Wikipedia->new;

#$isil2wikipedia->load( catfile('dewiki-isil.beacon') );

my $source = union( $gbv_source , $lobid_source, $isil2wikipedia );

my $rdf = $source->retrieve( { 'rdflow.uri' => 'http://lobid.org/organisation/DE-8' });
#http://uri.gbv.de/organization/isil/DE-8' } );
print rdfdump( $rdf )."\n";

done_testing;
