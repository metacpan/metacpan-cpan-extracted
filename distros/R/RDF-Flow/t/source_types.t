use strict;
use warnings;

use Test::More;
use Test::RDF;
use RDF::Trine qw(statement iri);
use RDF::Flow qw(rdflow previous cascade union pipeline);
use RDF::Flow::Source qw(rdflow_uri);
use RDF::Flow::Union;
use RDF::Flow::Cascade;
use RDF::Flow::Pipeline;

my ($src, $rdf, $env);

#use Log::Contextual::SimpleLogger;
#use Log::Contextual qw( :log ),
#   -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace info)]});

sub foo {
    my $uri = rdflow_uri(shift);
    return model() unless $uri =~ /[a-z]$/;
    return model( $uri , 'x:a', 'y:foo');
};
sub bar {
    model( rdflow_uri( shift ), 'x:a', 'y:bar');
};

my $foo = rdflow \&foo, name => 'foo';
my $bar = rdflow \&bar, name => 'bar';

my $empty = rdflow sub { model(); };
my $nil   = rdflow sub { undef; };

$src = RDF::Flow::Union->new( $empty, $foo, $foo, $nil, \&bar );

$rdf = $src->retrieve( query('/foo') );
ok($rdf);

isomorph_graphs( $rdf, model(qw(
http://example.org/foo x:a y:foo
http://example.org/foo x:a y:bar)), 'union' );

$src = RDF::Flow::Cascade->new( $empty, $foo, \&bar );
$rdf = $src->retrieve( query('/foo') );
isomorph_graphs( $rdf, model(qw(http://example.org/foo x:a y:foo)), 'cascade' );

$src = cascade( $empty, \&bar, $foo );
$rdf = $src->retrieve( query('/foo') );
isomorph_graphs( $rdf, model(qw(http://example.org/foo x:a y:bar)), 'cascade' );

$env = query('/hi');
$src = pipeline( $foo, $bar );
$rdf = $src->retrieve( $env );
isomorph_graphs( $rdf, model(qw(http://example.org/hi x:a y:bar)), 'pipeline' );
is( $rdf, $env->{'rdflow.data'}, 'pipeline sets rdflight.data' );

$src = pipeline( $foo, $bar, $empty );
$rdf = $src->retrieve( query('/123') );
isomorph_graphs( $rdf, model(), 'empty source nils pipeline' );

# pipeline as conditional: if $foo has content then union of $foo and $bar
$src = $foo->pipe_to( union( previous, $bar ) );
$rdf = $src->retrieve( query('/abc') );
isomorph_graphs( $rdf, model(qw(
http://example.org/abc x:a y:foo
http://example.org/abc x:a y:bar)), 'conditional' );

$rdf = $src->retrieve( query('/1') );

isomorph_graphs( $rdf, model(), 'conditional' );

done_testing;

# helper methods to create models and iterators
sub model {
    my $m = RDF::Trine::Model->new;
    $m->add_statement(statement( iri(shift), iri(shift), iri(shift) )) while @_;
    $m; }

sub iterator { model(@_)->as_stream; }

sub query {
    return { HTTP_HOST => 'example.org', PATH_INFO => shift };
}

