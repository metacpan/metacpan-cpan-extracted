#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/42_parser_xml.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/29/2006
# Revision:	$Id: 42_parser_xml.t,v 1.2 2009-11-23 19:37:22 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw(no_plan);
use Data::Dumper;

use strict;
use warnings;

BEGIN {
	use_ok('ODO::Parser::XML');
	
	no warnings;
}


my $BASEURI = 'http://testuri.org/';

my $RDF=<<EORDF;
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:eg="http://example.org/foovocab#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/">
        <foaf:Person rdf:nodeID="p1">
            <foaf:name>Alice</foaf:name>
            <foaf:knows>
                <foaf:Person rdf:nodeID="p2">
                    <foaf:name>Bob</foaf:name>
                    <foaf:url>http://www.ibm.com</foaf:url>
                    <eg:secretlyStalking rdf:nodeID="p1"/>
                </foaf:Person>
            </foaf:knows>
            <eg:acquaintance rdf:nodeID="p2"/>
            <eg:archNemesis rdf:nodeID="p2"/>
        </foaf:Person>
</rdf:RDF>
EORDF

my $RDF2=<<EORDF;
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:cd="http://www.recshop.fake/cd">

<rdf:Description>
  <cd:artist>Bob Dylan</cd:artist>
  <cd:country>USA</cd:country>
  <cd:company>Columbia</cd:company>
  <cd:price>10.90</cd:price>
  <cd:year>1985</cd:year>
</rdf:Description>

</rdf:RDF>
EORDF

my $errorIsOk = {

	'rdf-charmod-literals/error001.rdf'=> 1,
	'rdf-charmod-literals/error002.rdf'=> 1,
	
	'rdf-containers-syntax-vs-schema/error002.rdf'=> 1,
	'rdf-containers-syntax-vs-schema/test005.rdf'=> 1,
	
	'rdfms-rdf-names-use/error-001.rdf'=> 1,
	'rdfms-rdf-names-use/error-002.rdf'=> 1,
	'rdfms-rdf-names-use/error-003.rdf'=> 1,
	'rdfms-rdf-names-use/error-004.rdf'=> 1,
	'rdfms-rdf-names-use/error-005.rdf'=> 1,
	'rdfms-rdf-names-use/error-006.rdf'=> 1,
	'rdfms-rdf-names-use/error-007.rdf'=> 1,
	'rdfms-rdf-names-use/error-008.rdf'=> 1,
	'rdfms-rdf-names-use/error-009.rdf'=> 1,
	'rdfms-rdf-names-use/error-010.rdf'=> 1,
	'rdfms-rdf-names-use/error-011.rdf'=> 1,
	'rdfms-rdf-names-use/error-012.rdf'=> 1,
	'rdfms-rdf-names-use/error-013.rdf'=> 1,
	'rdfms-rdf-names-use/error-014.rdf'=> 1,
	'rdfms-rdf-names-use/error-015.rdf'=> 1,
	'rdfms-rdf-names-use/error-016.rdf'=> 1,
	'rdfms-rdf-names-use/error-017.rdf'=> 1,
	'rdfms-rdf-names-use/error-018.rdf'=> 1,
	'rdfms-rdf-names-use/error-019.rdf'=> 1,
	'rdfms-rdf-names-use/error-020.rdf'=> 1,
	'rdfms-rdf-names-use/test-011.rdf'=> 1,
	'rdfms-syntax-incomplete/error001.rdf'=> 1,
	'rdfms-syntax-incomplete/error002.rdf'=> 1,
	'rdfms-syntax-incomplete/error003.rdf'=> 1,
	'rdfms-syntax-incomplete/error004.rdf'=> 1,
	'rdfms-syntax-incomplete/error005.rdf'=> 1,
	'rdfms-syntax-incomplete/error006.rdf'=> 1,
	
	#'rdf-element-not-mandatory/test001.rdf'=> 1, # The W3C validator doesn't pass this test
	
	'rdfms-abouteach/error001.rdf'=> 1,
	'rdfms-abouteach/error002.rdf'=> 1,
	
	'rdfms-not-id-and-resource-attr/test003.rdf'=> 1, # rdf:bagID is withdrawn
	'rdf-ns-prefix-confusion/test0002.rdf'=> 1, # rdf:bagID is withdrawn
	'rdf-ns-prefix-confusion/test0007.rdf'=> 1, # rdf:aboutEach is withdrawn
	'rdf-ns-prefix-confusion/test0008.rdf'=> 1, # rdf:aboutEachPrefix is withdrawn
	
	'rdfms-empty-property-elements/error001.rdf'=> 1,
	'rdfms-empty-property-elements/error002.rdf'=> 1,
	'rdfms-empty-property-elements/error003.rdf'=> 1,
	
	'rdf-ns-prefix-confusion/error0001.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0002.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0003.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0004.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0005.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0006.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0007.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0008.rdf'=> 1,
	'rdf-ns-prefix-confusion/error0009.rdf'=> 1,
	
	'xmlbase/test012.rdf'=> 1, # "Test case WITHDRAWN in light of 2396bis"
	
	'rdfms-rdf-id/error001.rdf'=> 1,
	'rdfms-rdf-id/error002.rdf'=> 1,
	'rdfms-rdf-id/error003.rdf'=> 1,
	'rdfms-rdf-id/error004.rdf'=> 1,
	'rdfms-rdf-id/error005.rdf'=> 1,
	'rdfms-rdf-id/error006.rdf'=> 1,
	'rdfms-rdf-id/error007.rdf'=> 1,
	
	'rdfms-nested-bagIDs/test001.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test002.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test003.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test004.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test005.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test006.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test007.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test008.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test009.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test010.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test011.rdf'=> 1, # rdf:bagID is withdrawn
	'rdfms-nested-bagIDs/test012.rdf'=> 1, # rdf:bagID is withdrawn

	'rdfms-parseType/error001.rdf'=> 1,
	'rdfms-parseType/error002.rdf'=> 1,
	'rdfms-parseType/error003.rdf'=> 1,
	
};

my $parser;
my $result;

$parser = ODO::Parser::XML->new();
isa_ok($parser, 'ODO::Parser::XML', 'Verify object creation');

($result, my $imports ) = $parser->parse($RDF2);
ok($result, 'Parse successful');


cmp_ok(scalar( @{ $result }), '==', 5, 'Make sure we have the right number of triples');

if(! -e 't/rdf' ) {
	print STDERR "Please download the latest approved test cases and place them in t/rdf.\n";
	print STDERR "See http://www.w3.org/2000/10/rdf-tests/rdfcore/latest_Approved.zip\n";
	exit;
}

ok(open(RDFTESTS, 't/data/rdf_tests.txt'), 'Opening list of RDF tests');

while(<RDFTESTS>) {
	chomp();
	ok(open(TESTFILE, $_), "Opening test file: $_");
	local $/=undef;
	my $rdfData = <TESTFILE>;
	
	$result = undef;
	eval { $result = $parser->parse($rdfData); };

	# Some tests are supposed to generate an error in the parser	
	my $check = $_;
	$check =~ s#^t/rdf/##;

	if(exists($errorIsOk->{ $check })) {
		ok(!defined($result), "Purposfully invalid RDF in file: $_");		
	}
	else {
		isa_ok($result, 'ARRAY', '   Verify the results returned');
		
		print STDERR $parser->{_ERROR}
			unless($result);
	
		cmp_ok(scalar( @{ $result }), '>=', '0', "Parse of file: $_")
			if($result);
			
		foreach my $t (@{ $result }) {
			print STDERR "Undefined triple\n"
				if(!$t);
		}
	}
	
	close(TESTFILE);
}

close(RDFTESTS);


__END__
