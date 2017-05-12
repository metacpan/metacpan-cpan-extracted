# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OWLParser.t'

#########################

use Test::More tests => 6;

#########################

use Carp;
use strict;
use warnings;

SKIP:
{
	eval 'use XML::Parser';
	skip ('because XML::Parser is required for testing the OWLParser parser', 6) if $@;
	ok(1);
	
	require OBO::Parser::OWLParser;
	my $my_parser = OBO::Parser::OWLParser->new();
	ok(1);	
	
	my $owl_test_file = "./t/data/test_ulo_apo2.owl";
	
	my $onto = $my_parser->work($owl_test_file);
	ok($onto->get_number_of_terms() == 11);
	ok($onto->has_term($onto->get_term_by_id("APO:U0000009")));
	ok($onto->has_term($onto->get_term_by_id("APO:U0000001")));
	
	# export to OBO
	open (FH, ">./t/data/test_ulo_apo2.obo") || die "Run as root the tests: ", $!;
	$onto->export('obo', \*FH);
	close FH;
	                     
	ok(1);
}
