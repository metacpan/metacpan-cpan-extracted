#!/usr/bin/perl

use RDF::Flow::LinkedData;
use RDF::Dumper;

use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
   -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace)]});

my $source = RDF::Flow::LinkedData->new;

foreach my $uri (@ARGV) {
    my $env = { 'rdflow.uri' => $uri };
    my $rdf = $source->retrieve( $env );
    print rdfdump( $rdf );
}

__END__
#
# RDF::Flow::LinkedData->new(
#   url => sub {
#      return unless shift =~ qr{^http://lobid\.org/organisation/([A-Z]+-[A-Za-z0-9:\/-]+)$};
#      return "http://lobid.org/organisation/data/$1.rdf";
# )
#


        $model->add_statement( statement(
            iri($uri), $NS->uri('owl:sameAs'),
            iri('http://uri.gbv.de/organization/isil/'.$isil)
        ) );
        $model->add_statement( statement(
            iri($uri), $NS->uri('rdf:type'), $NS->daia('Institution')
        ) );
        $model->add_statement( statement(
            iri($uri), $NS->uri('rdf:type'), $NS->foaf('Organization')
        ) );
        $model->add_statement( statement(
            iri($uri), $NS->uri('rdf:type'), $NS->frbr('CorporateBody')
        ) );


