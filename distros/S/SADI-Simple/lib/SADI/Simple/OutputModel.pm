package SADI::Simple::OutputModel;
{
  $SADI::Simple::OutputModel::VERSION = '0.15';
}

use SADI::Simple::Utils;
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use RDF::Trine::Node::Resource;
use Log::Log4perl;
use Template;
use Encode;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use constant RDF_TYPE_URI => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
use constant RDF_SUBGRAPH_OF => 'http://www.w3.org/2004/03/trix/rdfg-1/subGraphOf';
 
use base 'RDF::Trine::Model';

sub _init {
	my $self = shift;
	my $service_base = shift;   # this is awful!  Need to refactor the code properly at some point
	$self->{'service_base'} = $service_base;
	$self->setInvocationTime();
	
	my $root_uri = "http://example.org/sadi_service/";  # set to a temporary value
	if ($self->{'service_base'}->{Signature}->URL) { $root_uri = $self->{'service_base'}->{Signature}->URL}; 
	$root_uri =~ s/\/$//;  # REMOVE TRAILING SLASH IF IT EXISTS
	
	my $default_collection_graph = $root_uri."/nanopub_collection/".$self->getInvocationTime();
	$self->{'default_collection_graph'} = $default_collection_graph;   # http://my.service.org/servicename/provenance/1238758

	my $named_graph = $root_uri."/provenance/".$self->getInvocationTime();
	$self->{'provenance_named_graph'} = $named_graph;   # http://my.service.org/servicename/provenance/1238758

	my $publ_named_graph = $root_uri."/publication_info/".$self->getInvocationTime();
	$self->{'pubinfo_named_graph'} = $publ_named_graph;   # http://my.service.org/servicename/provenance/1238758
	
	my $assertion_root = $root_uri."/assertion/";
	$self->{'assertion_statement_root'} = $assertion_root;   # http://my.service.org/servicename/assertion/
	
	my $nanopublication_root = $root_uri."/nanopublication/";  
	$self->{'nanopublication_root'} = $nanopublication_root;  # http://my.service.org/servicename/nanopublication/
	
	my $nanopubCollection_root = $root_uri."/nanopublicationCollection/";  
	$self->{'nanopubCollection_root'} = $$nanopubCollection_root;  # http://my.service.org/servicename/nanopublication/
	
	$self->{'nanopub_ontology_uri'} =  "http://www.nanopub.org/nschema#";
	
	$self->{'assertion_context_hashref'} = {};
	
}


#THIS IS WHAT WE'RE AIMING FOR :-)
#
#
#:head a np:NanopublicationCollection.
# 
#:ABC {
#     :ABC a np:Nanopublication ;
#         np:hasAssertion  :Ass1 ;
#         np:hasProvenance  :Prov ;
#         np:hasPublicationInfo :Info .
#         :ABC rdfg:subGraphOf :head .
#   }
# 
#:DEF {
#     :DEF a np:Nanopublication ;
#         np:hasAssertion  :Ass2 ;
#         np:hasProvenance  :Prov ;
#         np:hasPublicationInfo :Info .
#         :DEF rdfg:subGraphOf :head .
#   }
# 
#   :Ass1 {
#     ex:mosquito ex:transmits ex:malaria .
#   }
# 
#   :Ass2 {
#     ex:tick ex:transmits ex:limedisease .
#   }
# 
#   :Prov {   //  Any/All of these will be allowed
#     :head ex:generatedBy ev:abcdefg .
#     :ABC  ex:somePredicate  ev:qwerty .
#     :DEF  ex:somePredicate  ev:qwerty1 .
#     :Ass1  ex:usingAlgorithm  ev:myalgo .
#   }
# 
#   :Info {
#     :head pav:authoredBy auth:wxyz
#   }
# 


sub add_statement {

    my ($self, $statement, $context_info) = @_;  # context info is the $input  RDF::Trine::Resource currently being analyzed.  Provides the basis of a unique context URI for the quads
    #print STDERR "in add statement with self of type ", ref$self, "  statement $statement  stmpred ", $statement->predicate, "  input $context_info  \n";

    																							# but the same for all assertions of that input
	if (($context_info) && (ref($context_info) =~ /trine/i)){
		#print STDERR "recognized that it is a quad\n\n";
		my $inputURIstring = $context_info->uri();

		my $assertion_context = $self->getCurrentAssertionContext($inputURIstring);
		
		my $sub = $statement->subject; 
		my $pred = $statement->predicate; 
		my $obj = $statement->object;
		my $context = RDF::Trine::Node::Resource->new($assertion_context);
		my $named_statement = RDF::Trine::Statement::Quad->new($sub, $pred, $obj, $context);	# subj  pred  obj   stm_in_assert:AHhfj847hKHJRF	
		RDF::Trine::Model::add_statement($self, $named_statement)
	} else {
		RDF::Trine::Model::add_statement($self, $statement);
	}
	#print STDERR "STATEMENT ADDED\n\n";

}

# problem is that assertion context needs to be re-generated at a later time for a given input... so need to store it in a hash
sub getCurrentAssertionContext {
	my ($self, $URI) = @_;
	my $assertion_context_hashref = $self->{'assertion_context_hashref'};
	if (ref($URI) =~ /trine/i){$URI = $URI->uri()}  # need the stringified for the hash
	# print STDOUT "\n\ncontext of $URI  ...";
	if ($assertion_context_hashref->{$URI}){
		# print STDOUT "found context $assertion_context_hashref->{$URI}\n\n\n";
		return $assertion_context_hashref->{$URI}
	} else {
		# print STDOUT " context not found ...\n\n\n";
		my $AssertionContextID = md5_hex($URI . $self->getInvocationTime());   # invocation time increments with every new nanopub, so each gets a unique assertion context
	    my $assertion_context = $self->{'assertion_statement_root'} . $AssertionContextID;          # this will be different for every input
		$assertion_context_hashref->{$URI} = $assertion_context;
		return $assertion_context;
	}
}


sub getCurrentNanopubID {
	my ($self, $URI) = @_;
	return $self->{'nanopublication_root'} . md5_hex($URI . $self->getInvocationTime());   # a hash of the input and timestamp of service invocation
	
}

sub resetInvocationTime {
	return setInvocationTime();
}
sub setInvocationTime {
	my ($self) = @_;	
	$self->{'invocation_timestamp'} = time; 
	return $self->{'invocation_timestamp'};
	
}

sub getInvocationTime {
	my ($self) = @_;	
	return $self->{'invocation_timestamp'};
}


sub nanopublish_result_for {
	my ($self, $input) = @_;  # self is the output model RDF::Trine::Model
	return unless ($self->{'service_base'}->get_response_content_type =~ /quads/i);  # only do this if requesting quads
	return unless ($self->{'service_base'}->{'Signature'}->NanoPublisher);
    # nanopub:AHhfj847hKHJRF  np:hasAassertion assert:AHhfj847hKHJRF
    # nanopub:AHhfj847hKHJRF  np:hasProvenance $self->{'provenance_named_graph'}   (this is the same for all different nanopubs in a multiplexed invocation of the service)																						  
	# nanopub:AHhfj847hKHJRF  rdf:type  np:Nanopublication
	# assert:AHhfj847hKHJRF   rdf:type  np:Assertion

	my $np = $self->{'nanopub_ontology_uri'};

	my $NanopubCollection = RDF::Trine::Node::Resource->new($self->{'default_collection_graph'});
	my $NanopublicationCollectionType =  RDF::Trine::Node::Resource->new($np."NanopublicationCollection");
	my $NanopublicationType =  RDF::Trine::Node::Resource->new($np."Nanopublication");
	my $AssertionType =  RDF::Trine::Node::Resource->new($np."Assertion");
	my $ProvenanceType =  RDF::Trine::Node::Resource->new($np."Provenance");
	my $PubInfoType =  RDF::Trine::Node::Resource->new($np."PublicationInfo");
	my $rdfType = RDF::Trine::Node::Resource->new(RDF_TYPE_URI);
	my $rdfSubgraphOf = RDF::Trine::Node::Resource->new(RDF_SUBGRAPH_OF);


	my $inputURIstring = $input->uri();
	
    
    my $AssertionContextURI = $self->getCurrentAssertionContext($inputURIstring);   
    																				    																												  
	my $NanopublicationURI = $self->getCurrentNanopubID($inputURIstring);
    
    
	my $Nanopub = RDF::Trine::Node::Resource->new($NanopublicationURI);
	my $hasAssertion = RDF::Trine::Node::Resource->new($np."hasAssertion");
	my $Assertion =  RDF::Trine::Node::Resource->new($AssertionContextURI);
	my $np_hasAssertion_Assertion = RDF::Trine::Statement::Quad->new($Nanopub, $hasAssertion, $Assertion, $Nanopub);
	$self->add_statement($np_hasAssertion_Assertion); 
	
	my $provenance_named_graph = RDF::Trine::Node::Resource->new($self->{'provenance_named_graph'});	
	my $hasProvenance = RDF::Trine::Node::Resource->new($np."hasProvenance");
	my $np_hasProvenance_Provenance = RDF::Trine::Statement::Quad->new($Nanopub, $hasProvenance, $provenance_named_graph, $Nanopub);
	$self->add_statement($np_hasProvenance_Provenance); 

	my $pubinfo_named_graph = RDF::Trine::Node::Resource->new($self->{'pubinfo_named_graph'});	
	my $hasPubInfo = RDF::Trine::Node::Resource->new($np."hasPublicationInfo");
	my $np_hasPubInfo_Pubinfo = RDF::Trine::Statement::Quad->new($Nanopub, $hasPubInfo, $pubinfo_named_graph, $Nanopub);
	$self->add_statement($np_hasPubInfo_Pubinfo); 


	$self->add_statement(RDF::Trine::Statement::Quad->new($Nanopub, $rdfType, $NanopublicationType, $Nanopub));
	$self->add_statement(RDF::Trine::Statement::Quad->new($pubinfo_named_graph, $rdfType, $PubInfoType, $Nanopub));
	$self->add_statement(RDF::Trine::Statement::Quad->new($Assertion, $rdfType, $AssertionType, $Nanopub));
	$self->add_statement(RDF::Trine::Statement::Quad->new($provenance_named_graph, $rdfType, $ProvenanceType, $Nanopub));
	$self->add_statement(RDF::Trine::Statement::Quad->new($Nanopub, $rdfSubgraphOf, $NanopubCollection, $Nanopub));
	$self->add_statement(RDF::Trine::Statement::Quad->new($NanopubCollection, $rdfType,$NanopublicationCollectionType, $Nanopub));


	unless ($self->{provenance_added}){
	    $self->_add_provenance($NanopubCollection, $provenance_named_graph);
	    $self->_add_pubinfo($NanopubCollection, $pubinfo_named_graph);
		
	}
    
    $self->resetInvocationTime();  # be ready to create a new NanoPublication URI
    
}


sub _add_provenance {
	my ($self, $NanopubCollection, $provenance_named_graph) = @_;
	use DateTime;
#	   name - the name of the SADI service
#      uri  - the service uri
#      type - the service type
#      input - the input class URI
#      output - the output class URI
#      desc - a description for this service
#      id - a unique identifier (LSID, etc)
#      email - the providers email address
#      format - the category of service (sadi)
#      nanopublisher - can the service publish nquads for nanopubs?
#      url - the service url
#      authoritative - whether or not the service is authoritative
#      authority - the service authority URI
#      sigURL - the url to the service signature
	my $signature = $self->{'service_base'}->{Signature};

	# remember this is adding quads!
	my $Identifier = RDF::Trine::Node::Literal->new($signature->ServiceURI,"","http://www.w3.org/2001/XMLSchema#string" );  # this is a URI, so I need to cast it as a string before sending it into the statement, otherwise it will be cast as a resource
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/terms/created", [DateTime->now,"", "http://www.w3.org/2001/XMLSchema#dateTime",""], $provenance_named_graph);
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/terms/creator", [$signature->Authority, "", "http://www.w3.org/2001/XMLSchema#string",], $provenance_named_graph) if $signature->Authority ;
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/elements/1.1/coverage", ["Output from SADI Service", "en"], $provenance_named_graph);
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/elements/1.1/description", ["Service Description: ".$signature->Description, "en"], $provenance_named_graph) if $signature->Description;
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/elements/1.1/identifier", [$Identifier], $provenance_named_graph) if $signature->ServiceURI;
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/elements/1.1/publisher", [$signature->Authority,"", "http://www.w3.org/2001/XMLSchema#string" ], $provenance_named_graph) if $signature->Authority;
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/elements/1.1/source", [$signature->URL],  $provenance_named_graph) if $signature->URL;
	$self->_add_statement($NanopubCollection, "http://purl.org/dc/elements/1.1/title", [$signature->ServiceName, "","http://www.w3.org/2001/XMLSchema#string"], $provenance_named_graph) if $signature->ServiceName;
	
	$self->{provenance_added} = 1;  # raise a flag so that this routine is not called again!
}



sub _add_pubinfo {
	my ($self, $Nanopub, $pubinfo_named_graph) = @_;
	use DateTime;
	# remember this is adding quads!
	my $signature = $self->{'service_base'}->{Signature};
	my $Identifier = RDF::Trine::Node::Literal->new($signature->ServiceURI,"","http://www.w3.org/2001/XMLSchema#string" );  # this is a URI, so I need to cast it as a string before sending it into the statement, otherwise it will be cast as a resource
	
	$self->_add_statement($Nanopub, "http://purl.org/dc/terms/created", [DateTime->now,"", "http://www.w3.org/2001/XMLSchema#dateTime",""], $pubinfo_named_graph);
	$self->_add_statement($Nanopub, "http://purl.org/dc/terms/creator", ["Perl SADI::Simple Library version $VERSION", "", "http://www.w3.org/2001/XMLSchema#string",], $pubinfo_named_graph);
#	$self->_add_statement($Nanopub, "http://swan.mindinformatics.org/ontologies/1.2/pav/createdBy", [$Identifier], $pubinfo_named_graph);
	$self->_add_statement($Nanopub, "http://swan.mindinformatics.org/ontologies/1.2/pav/createdBy", [$signature->ServiceURI], $pubinfo_named_graph);
	
}

sub _add_statement {
        my ($self, $s, $p, $o, $c) = @_;
        my ($obj, $lang, $datatype, $canonicalflag) = @$o;
        unless (ref($s) =~ /trine/i){
                $s = RDF::Trine::Node::Resource->new($s);
        }
	unless (ref($p) =~ /trine/i){
                $p = RDF::Trine::Node::Resource->new($p);
        }
	if (ref($obj) =~ /trine/i){
                $o = $obj;
        } else {
                if (($obj =~ /^http:\/\//i) || ($obj =~ /^\<http:\/\//i)){
                        $o = RDF::Trine::Node::Resource->new($obj);
                } else {
                        $o = RDF::Trine::Node::Literal->new($obj, $lang, $datatype, $canonicalflag);
                }
        }
	if ($c){
		unless (ref($c) =~ /trine/i){
			$c = RDF::Trine::Node::Resource->new($c);
		}
	}
	if ($c){
		my $stm = RDF::Trine::Statement::Quad->new($s, $p, $o, $c);
		$self->add_statement($stm);
	}  else {
		my $stm = RDF::Trine::Statement->new($s, $p, $o);
		$self->add_statement($stm);
	}

}
1;

__END__

=head1 NAME

SADI::Simple::OutputModel - a light wrapper around RDF::Trine::Model that simplifies NanoPublications in SADI

=head1 SYNOPSIS

 my $output_model = SADI::Simple::OutputModel->new();
 $output_model->_init( $output_model->_init($implements_ServiceBase);))
 

=head1 DESCRIPTION

 There are various things that an output model can do to itself to 
 automatically generate NanoPublications.  This object wraps RDF::Trine::Model
 exposing its API, but adding these new functionalities.
 
 All of the functionalities for NanoPublishers will be ignored if present
 in a service that does not NanoPublish, so feel free to include them
 in your service to avoid having to update the service later when you
 decide that NanoPublishing is pretty cool...

=head1 SUBROUTINES
 
=head2 add_statement

 $output_model->add_statement( $statement, [$input]);
 
 Allows you to add the context for a NanoPubs Assertion named graph.
 Second parameter is optional, and can be present but undef in a service
 that does not publish nanopubs, but might be a nanopublisher one day.
 The $input is the RDF::Trine::Node::Resource that is currently 
 being analyzed in the service "process it" loop.


=head2 nanopublish_result_for 

 $output_model->nanopublish_result_for($input);
 
 in the context of the "process it" loop of a SADI service, this method
 should be invoked at the end of the loop to complete the
 NanoPublication of the output from the given $input.
 
 If it is present in a non-NanoPublishing service, it will be ignored.

=cut


