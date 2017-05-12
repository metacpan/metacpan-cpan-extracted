use strict;
use warnings;

use Test::More;
use Test::RDF;
use RDF::Trine qw(statement iri literal);
use RDF::Trine::Iterator;
use RDF::Flow qw(cached rdflow);
use RDF::Flow::Source qw(rdflow_uri empty_rdf);

{
    package OneTimeCache; # expires after being accessed once
    sub new { bless { }, shift }
    sub get { $_ = $_[0]->{$_[1]}; delete $_[0]->{$_[1]}; $_; }
    sub set { $_[0]->{$_[1]} = $_[2] }

    package EternalCache; # never expires
    sub new { bless { }, shift }
    sub get { $_[0]->{$_[1]}; }
    sub set { $_[0]->{$_[1]} = $_[2] }
}

sub amodel {
    my $model = RDF::Trine::Model->new;
    $model->add_statement(statement(
        iri($_[0]), iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#value'),
        literal($_[1])));
    return $model;
}

my $count = 1;
sub counting_source {
    amodel( rdflow_uri(shift), $count++ )
}

my $cache = OneTimeCache->new;
my $source = cached( \&counting_source, $cache );

my $env = { 'rdflow.uri' => 'x:foo' };
my $rdf = $source->retrieve( $env );
isomorph_graphs( $rdf, amodel('x:foo', 1), 'first request: foo' );
ok( !$env->{'rdflow.cached'}, 'not cached' );

$env->{'rdflow.uri'} = 'x:bar';
$rdf = $source->retrieve( $env );
isomorph_graphs( $rdf, amodel('x:bar', 2), 'second request: bar' );
ok( !$env->{'rdflow.cached'}, 'not cached' );

$env->{'rdflow.uri'} = 'x:foo';
$rdf = $source->retrieve( $env );
isomorph_graphs( $rdf, amodel('x:foo', 1), 'second request: foo' );
ok( $env->{'rdflow.cached'}, 'cached' );
# specific form of timestamp depends on OS
like( $env->{'rdflow.timestamp'}, qr{\d\d\d\d}, 'with timestamp' );

$env = { 'rdflow.uri' => 'x:foo' };
$rdf = $source->retrieve( $env );
isomorph_graphs( $rdf, amodel('x:foo', 3), 'third request: foo' );
ok( !$env->{'rdflow.cached'}, 'not cached' );

my $model = amodel('x:foo', 'bar');
$source = rdflow( sub { $model->as_stream; } );
$cache = OneTimeCache->new;
$source = cached( $source, $cache );

$env = { 'rdflow.uri' => 'x:foo' };
$rdf = $source->retrieve( $env );
isomorph_graphs( $rdf, $model, 'new from iterator source' );
ok( !$env->{'rdflow.cached'}, 'not cached' );

$env = { 'rdflow.uri' => 'x:foo' };
$rdf = $source->retrieve( $env );
ok( $env->{'rdflow.cached'}, 'now cached' );

# test caching with guard
$count = 0;
my $guard = OneTimeCache->new;

my $do_source = 1;
$source = cached(
    sub {
        amodel( rdflow_uri(shift), $count++ ) if $do_source;
    },
    EternalCache->new,
    guard => $guard
);

# first call: no guard, no cache, so the source is used
ok( !$guard->{'u:uri'}, 'next is not guarded' );
isomorph_graphs( $source->retrieve('u:ri'), amodel('u:ri', 0), 'first get' );

$env = { 'rdflow.uri' => 'u:ri' };
isomorph_graphs( $source->retrieve($env), amodel('u:ri', 0), 'cached source' );
ok( $env->{'rdflow.cached'}, 'is cached' );

isomorph_graphs( $source->retrieve('u:ri'), amodel('u:ri', 1), 'guarded source' );

isomorph_graphs( $source->retrieve('u:ri'), amodel('u:ri', 1), 'cached source' );
isomorph_graphs( $source->retrieve('u:ri'), amodel('u:ri', 2), 'guarded source' );

$do_source = 0;
isomorph_graphs( $source->retrieve('u:ri'), amodel('u:ri', 2), 'cached source' );
isomorph_graphs( $source->retrieve('u:ri'), amodel('u:ri', 2), 'guarded source' );

#ok( empty_rdf( $source->retrieve( 'u:ri' ) ), 'not guardd' );

done_testing;
