
# $Id: multi-class.t,v 1.1 2009-07-03 18:21:45 Martin Exp $

use strict;
use warnings;

use blib;
use Data::Dumper;
use Test::More 'no_plan';
use Test::File;
BEGIN
  {
  use_ok('RDF::Simple::Parser');
  use_ok('RDF::Simple::Serialiser');
  } # end of BEGIN block

my $ser = new RDF::Simple::Serialiser;
isa_ok($ser, q{RDF::Simple::Serialiser});
my $par = new RDF::Simple::Parser;
isa_ok($par, q{RDF::Simple::Parser});

test_rdf_file(q{t/multi-class.rdf}, 9);

sub test_rdf_file
  {
  my $sFname = shift or fail;
  my $iCount = shift or fail;
  file_not_empty_ok($sFname);
  my @triples = $par->parse_file($sFname);
  is(scalar(@triples), $iCount, qq{got exactly $iCount triples});
  # print STDERR Dumper($par->getns);
  $ser->addns($par->getns);
  my $rdf = $ser->serialise(@triples);
  # diag($rdf);
  @triples = $par->parse_rdf($rdf);
  is(scalar(@triples), $iCount, qq{got exactly $iCount triple(s) round-tripped});
  } # test_rdf_file

__END__


