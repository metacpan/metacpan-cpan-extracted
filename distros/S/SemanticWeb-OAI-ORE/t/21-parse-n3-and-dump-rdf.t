#!/usr/bin/perl -T
#
# Test this module with a simple N3 example and check against an RDFXML example
#
# 2013-07-31 - It appears from CPAN test that with new perl installations
# (5.19.xx etc) the RDFXML dumps have attributes in different order than earlier
# installations, not sure what change causes this. RDFXML still correct but
# means that direct comparison of the XML string is not possible.
#
# $Id: 21-parse-n3-and-dump-rdf.t,v 1.5 2013-07-31 15:29:53 simeon Exp $
use strict;
use warnings;

use lib qw(t/lib);
use English qw(-no_match_vars);
use Diff qw(diff);
use Test::More;
plan('tests'=>11);

use_ok( 'SemanticWeb::OAI::ORE::ReM' );
use_ok( 'SemanticWeb::OAI::ORE::N3' );
use_ok( 'SemanticWeb::OAI::ORE::RDFXML' );

%ENV=();

my $n3_src_file='t/examples/datamodel-overview/combined.n3';
my $rdfxml_file='t/examples/datamodel-overview/combined.rdf.dump';

#note("Using test file $n3_src_file\n");
if (not -r $n3_src_file) {
  BAIL_OUT("Configuration problem, can't find test file $n3_src_file\n");
}

my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
if (not $rem->parsefile('n3',$n3_src_file)) {
  BAIL_OUT("Parse error with $n3_src_file: errstr=".$rem->errstr()."\n");
}
ok($rem,"Parsed n3 file $n3_src_file");
my $test_rdfxml=$rem->model->as_rdfxml;

# a few regex tests on the rdfxml
like($test_rdfxml, qr/xmlns:\w+="http:\/\/www.openarchives.org\/ore\/terms\/"/,
     "RDFXML has ORE namespace");
like($test_rdfxml, qr/<rdf:Description rdf:about="ReM-1">/,
     "RDFXML talks about ReM-1");
like($test_rdfxml, qr/<rdf:Description rdf:about="A-1">/,
     "RDFXML talks about A-1");
like($test_rdfxml, qr/<rdf:Description rdf:about="AR-3">/,
     "RDFXML talks about AR-3");

# now reparse the rdfxml and check statements match original
my $rem2=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
ok( $rem2->parse('rdfxml',$test_rdfxml,'ReM-1'), "Reparsed RDFXML");
is( $rem2->model->countStmts, 15,  "Got 15 statements");
my @stmts1 = get_stmts($rem->model);
my @stmts2 = get_stmts($rem2->model);
my $diff = diff( \@stmts1, \@stmts2 );
is( $diff, undef, "Reparsed RDFXML has same RDF statements as original");

# Sorted list of statements for comparison, does nothing
# to handle blank nodes but this is OK since we don't
# (shouldn't) have any in the test.
sub get_stmts {
    my $model=shift;
    my @stmts = ();
    # code from http://search.cpan.org/~dpokorny/RDF-Core-0.51/lib/RDF/Core/Serializer.pm
    my $enumerator = $model->getStmts;
    my $statement = $enumerator->getFirst;
    while (defined $statement) {
	my $s = $statement->getLabel;
        $s =~ s#uri:/##g; #get rid of bogus URI prefix from RDFXML read of relative URIs
        push(@stmts, $s."\n");
	$statement = $enumerator->getNext
    }
    $enumerator->close;
    return(sort @stmts);
}
