
# This is a test for RT#43688 part 2, long string element gets truncated

use strict;
use warnings;

use Test::More 'no_plan';

use blib;
my $PM;
BEGIN
  {
  $PM = q{RDF::Simple::Serializer};
  use_ok($PM);
  } # BEGIN

my $ser = new $PM ( nodeid_prefix => 'a:' );
isa_ok($ser, $PM);
$ser->addns( foaf => 'http://xmlns.com/foaf/0.1/' );
my $node1 = 'a:123';
my $sURL = 'http://google.com/some/page.html';
my @triples = (
               [$node1, 'foaf:name', 'John Doe'],
               # This is a plain URL:
               [$node1, 'foaf:url', \$sURL],
               # This is an RDF URI:
               [$node1, 'rdf:type', 'http://xmlns.com/foaf/0.1/Person']
              );
my $rdf = $ser->serialise(@triples);
# print STDERR $rdf;
my @asN3 = split(/\n/, $rdf);
my $sExpectedN3 = <<"END_N3";
\@prefix foaf: <http://xmlns.com/foaf/0.1/> .
\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

$node1 a http://xmlns.com/foaf/0.1/Person .
$node1 foaf:name "John Doe" .
$node1 foaf:url $sURL
END_N3
my $sExpectedRDF = <<"END_RDF";
<rdf:RDF
xmlns:foaf="http://xmlns.com/foaf/0.1/"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
>
<foaf:Person rdf:about="$node1">
<foaf:name>John Doe</foaf:name>
<foaf:url>$sURL</foaf:url>
</foaf:Person>
</rdf:RDF>
END_RDF
my @asExpected = split(/\n/, $sExpectedRDF);
chomp @asExpected;
# The order of axioms in an N3 file is NOT important:
@asExpected = sort @asExpected;
@asN3 = sort @asN3;
is_deeply(\@asN3, \@asExpected);

__END__
