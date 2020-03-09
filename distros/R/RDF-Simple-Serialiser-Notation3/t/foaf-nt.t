
# $Id: foaf-nt.t,v 1.5 2009-07-04 14:49:43 Martin Exp $

use blib;
use Test::More 'no_plan';
use Test::Deep;

my $sMod;

BEGIN
  {
  $sMod = 'RDF::Simple::Serialiser::NT';
  use_ok($sMod);
  } # end of BEGIN block

# This sample ontology is taken from the SYNOPSIS of
# RDF::Simple::Serialiser:
my $ser = new $sMod;
isa_ok($ser, $sMod);
$ser->addns( foaf => 'http://xmlns.com/foaf/0.1/' );
my $node1 = 'a123';
my $node2 = 'a456';
my @triples = (
               [$node1, 'foaf:name', 'Jo Walsh'],
               [$node1, 'foaf:knows', $node2],
               [$node2, 'foaf:name', 'Robin Berjon'],
               [$node2, 'foaf:age', \'26'],
               [$node2, 'foaf:salary', '56789.10'],
               [$node2, 'foaf:address', '123 Main St'],
               [$node1, 'rdf:type', 'foaf:Person'],
               [$node2, 'rdf:type', 'http://xmlns.com/foaf/0.1/Person']
              );
my $rdf = $ser->serialise(@triples);
# print STDERR $rdf;
# exit 88;
my @asN3 = split(/\n/, $rdf);
my @asExpected = <DATA>;
chomp @asExpected;
# The order of axioms in an N3 file is NOT important:
@asExpected = sort @asExpected;
@asN3 = sort @asN3;
is_deeply(\@asN3, \@asExpected);
my @asTriples = grep { /\S/ } @asExpected;
is($ser->get_triple_count, scalar(@asTriples));

__DATA__
_:a456 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
_:a456 <http://xmlns.com/foaf/0.1/name> "Robin Berjon" .
_:a456 <http://xmlns.com/foaf/0.1/age> 26 .
_:a456 <http://xmlns.com/foaf/0.1/salary> 56789.10 .
_:a456 <http://xmlns.com/foaf/0.1/address> "123 Main St" .

_:a123 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
_:a123 <http://xmlns.com/foaf/0.1/name> "Jo Walsh" .
_:a123 <http://xmlns.com/foaf/0.1/knows> _:a456 .
