use strict;
use warnings;

use Test::More;
use RDF::Flow qw(:all);
use RDF::Flow::LinkedData;

#use Log::Contextual::SimpleLogger;
#use Log::Contextual qw( :log ),
#    -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace error)]});
#    -logger => [qw(trace error)]

my $source = sub { die "boom!" };
my $env;

$env = { 'rdflow.uri' => 'http://example.org/' };
my $rdf = rdflow( $source )->retrieve( $env );
is( $rdf->size, 0, 'source died' );
like( $env->{'rdflow.error'}, qr{^boom! at .+ line \d+$}, 'but nothing broken' );

$source = RDF::Flow::LinkedData->new;
$env = { 'rdflow.uri' => 'xxx' };
$rdf = $source->retrieve( $env );
like( $env->{'rdflow.error'}, qr{^failed to retrieve RDF from xxx: not an URL}, 'linked data error' );

done_testing
