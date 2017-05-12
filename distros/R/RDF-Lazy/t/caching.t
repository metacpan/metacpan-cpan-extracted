use strict;
use warnings;

use Test::More;
use RDF::Lazy;
use RDF::Trine qw(statement iri literal);

{
    package MyCache;
    sub new { bless {}, shift }
    sub get { $_[0]->{$_[1]} }
    sub set { $_[0]->{$_[1]} = $_[2] }
}

my $cache = MyCache->new;
my $rdf = RDF::Lazy->new(
    cache => $cache,
    namespaces => { ex => 'http://example.org/' }
);

no warnings 'redefine';
*RDF::Trine::Parser::parse_url_into_model = sub {
    my ($self, $uri, $model) = @_;
    $model->add_statement( statement(
         iri("http://example.com/"), iri("http://example.org/foo"), literal("x")
    ) );
};

my $node = $rdf->resource('http://example.com/');

is( $rdf->load("http://example.com/"), 1 );
is( $node->ex_foo."", "x", "loaded triple" );
is( $rdf->load("http://example.com/"), 0, "loaded from cache" );
is( $node->ex_foo."", "x" );

$cache->{"http://example.com/"} = "<> a <http://example.org/thing>.";
is( $rdf->load("http://example.com/"), 1, "loaded from cache" );
ok $node->a('<http://example.org/thing>');

done_testing;
