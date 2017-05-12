
# $Id: foaf-n3.t,v 1.7 2009-07-04 14:49:43 Martin Exp $

use blib;
use Test::More 'no_plan';
use Test::Deep;

my $sMod;

BEGIN
  {
  $sMod = 'RDF::Simple::Serialiser::N3';
  use_ok($sMod);
  } # end of BEGIN block

# This sample ontology is taken from the SYNOPSIS of
# RDF::Simple::Serialiser:
my $ser = new $sMod (
                     # nodeid_prefix => 'a:'
                    );
isa_ok($ser, $sMod);
$ser->addns( foaf => 'http://xmlns.com/foaf/0.1/' );
my $node1 = 'a:123';
my $node2 = 'a:456';
my @triples = (
               [$node1, 'foaf:name', 'Jo Walsh'],
               [$node1, 'foaf:knows', $node2],
               [$node2, 'foaf:name', 'Robin Berjon'],
               [$node2, 'foaf:age', 26],
               [$node2, 'foaf:salary', '56789.10'],
               [$node2, 'foaf:address', '123 Main St'],
               [$node1, 'rdf:type', 'foaf:Person'],
               [$node2, 'rdf:type', 'http://xmlns.com/foaf/0.1/Person']
              );
my $rdf = $ser->serialise(@triples);
my @asN3 = split(/\n/, $rdf);
my @asExpected = <DATA>;
# The order of axioms in an N3 file is NOT important:
@asExpected = sort @asExpected;
# diag(@asExpected);
chomp @asExpected;
@asN3 = sort @asN3;
is_deeply(\@asN3, \@asExpected, q{sorted arrays match});
my @asTriples = grep { /\./ } @asExpected;
is($ser->get_triple_count, scalar(@asTriples));

__DATA__
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

a:456 a foaf:Person .
a:456 foaf:name "Robin Berjon" .
a:456 foaf:age 26 .
a:456 foaf:salary 56789.10 .
a:456 foaf:address "123 Main St" .

a:123 a foaf:Person .
a:123 foaf:name "Jo Walsh" .
a:123 foaf:knows a:456 .
