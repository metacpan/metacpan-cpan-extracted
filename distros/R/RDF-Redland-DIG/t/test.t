package LWP::Mock;

use Data::Dumper;

use base qw(LWP::UserAgent);

sub request {
	my $self = shift;
	my $req  = shift;
	
	my $response;
	
	if( index( $req->content, '<getIdentifier') != -1){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header, "OK");	
	} elsif( index ( $req->content, '<newKB') != -1){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<kb uri="urn:uuid:abcdefgh-1234-1234-12345689ab"/>
		</responses>|);
	} elsif( index ( $req->content, '<releaseKB') != -1){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<ok/></responses>|);
	} elsif( index ( $req->content, '<tells') != -1){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<ok/></responses>|);
	} elsif( index ($req->content, '<allConceptNames') != -1) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
    	<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>	
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
 		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		<conceptSet id="1"><synonyms><catom name="class"/></synonyms></conceptSet>
		</responses>|);	
	} elsif( index ($req->content, '<allRoleNames') != -1) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<roleSet id="1"><synonyms><ratom name="role"/></synonyms></roleSet>
    	<roleSet id="1"><synonyms><ratom name="role"/></synonyms></roleSet>
		<roleSet id="1"><synonyms><ratom name="role"/></synonyms></roleSet>
		<roleSet id="1"><synonyms><ratom name="role"/></synonyms></roleSet>
		<roleSet id="1"><synonyms><ratom name="role"/></synonyms></roleSet>
		<roleSet id="1"><synonyms><ratom name="role"/></synonyms></roleSet>
		</responses>|);
	} elsif( index ($req->content, '<allIndividuals') != -1) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<individualSet id="1"><individual name="individual"/></individualSet>
		<individualSet id="1"><individual name="individual"/></individualSet>
		<individualSet id="1"><individual name="individual"/></individualSet>
		<individualSet id="1"><individual name="individual"/></individualSet>
		</responses>|);
	} elsif( index ($req->content, '<satisfiable') != -1 ) {
			my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		</responses>|);
	} elsif( index ($req->content, '<subsumes') != -1 ) {
			my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<true id="http://www.owl-ontologies.com/Ontology1206537648.owl#NamedPizza"/>
    	<false id="http://www.owl-ontologies.com/Ontology1206537648.owl#NamedPizza"/>
    	<true id="http://www.owl-ontologies.com/Ontology1206537648.owl#NamedPizza"/></responses>|);
	} elsif( index ($req->content, '<disjoint') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<true id="http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza"/>
    	<true id="http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza"/>
    	<false id="http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza"/>
		</responses>|);
	} elsif( index ($req->content, '<parents id="http://www.owl-ontologies.com/Ontology1206537648.owl#VegetableTopping"') != -1 ||
	         index ($req->content, '<children id="http://www.owl-ontologies.com/Ontology1206537648.owl#VegetableTopping"') != -1 ||
	         index ($req->content, '<ancestors id="http://www.owl-ontologies.com/Ontology1206537648.owl#VegetableTopping"') != -1 ||
	         index ($req->content, '<descendants id="http://www.owl-ontologies.com/Ontology1206537648.owl#VegetableTopping"') != -1 ||
	         index ($req->content, '<equivalents id="http://www.owl-ontologies.com/Ontology1206537648.owl#VegetableTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="1"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="2"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="3"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="4"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="5"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="6"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="7"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="8"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="9"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="10"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="11"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="12"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="13"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="14"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="15"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="16"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="17"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="18"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="19"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="20"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="21"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="22"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="23"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="24"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="25"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="26"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="27"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="28"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="29"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="30"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="31"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="32"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="33"><synonyms><catom name="0"/></synonyms></conceptSet>
		</responses>|);
	} elsif (index ($req->content, '<parents id="http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanHotPizza"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanHotPizza"><synonyms><catom name="0"/></synonyms></conceptSet>
		</responses>|);
	} elsif (index ($req->content, '<children id="http://www.owl-ontologies.com/Ontology1206537648.owl#MeatTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#MeatTopping">
		<synonyms><catom name="1"/></synonyms><synonyms><catom name="2"/></synonyms>
		<synonyms><catom name="3"/></synonyms><synonyms><catom name="4"/></synonyms>
		</conceptSet>
		</responses>|);
	} elsif (index ($req->content, '<ancestors id="http://www.owl-ontologies.com/Ontology1206537648.owl#GreenPepperTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#GreenPepperTopping">
		<synonyms><catom name="1"/></synonyms><synonyms><catom name="2"/></synonyms>
		<synonyms><catom name="3"/></synonyms></conceptSet></responses>|);
	} elsif (index ($req->content, '<descendants id="http://www.owl-ontologies.com/Ontology1206537648.owl#PizzaTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#PizzaTopping">
		<synonyms><catom name="1"/></synonyms><synonyms><catom name="2"/></synonyms>
		<synonyms><catom name="3"/></synonyms><synonyms><catom name="4"/></synonyms>
		<synonyms><catom name="5"/></synonyms><synonyms><catom name="6"/></synonyms>
		<synonyms><catom name="7"/></synonyms><synonyms><catom name="8"/></synonyms>
		<synonyms><catom name="9"/></synonyms><synonyms><catom name="10"/></synonyms>
		<synonyms><catom name="11"/></synonyms><synonyms><catom name="12"/></synonyms>
		<synonyms><catom name="13"/></synonyms><synonyms><catom name="14"/></synonyms>
		<synonyms><catom name="15"/></synonyms><synonyms><catom name="16"/></synonyms>
		<synonyms><catom name="17"/></synonyms><synonyms><catom name="18"/></synonyms>
		<synonyms><catom name="19"/></synonyms><synonyms><catom name="20"/></synonyms>
		<synonyms><catom name="21"/></synonyms><synonyms><catom name="22"/></synonyms>
		</conceptSet></responses>|);
	} elsif (index ($req->content, '<equivalents id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza">
		<synonyms><catom name="0"/><catom name="1"/></synonyms>
		</conceptSet></responses>|);
	} elsif ( index ($req->content, '<rparents id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasTopping"') != -1 ||
	          index ($req->content, '<rchildren id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasTopping"') != -1 ||
	          index ($req->content, '<rancestors id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasTopping"') != -1 ||
	          index ($req->content, '<rdescendants id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<roleSet id="1"><synonyms><ratom name="0"/></synonyms></roleSet>
		<roleSet id="2"><synonyms><ratom name="0"/></synonyms></roleSet>
		<roleSet id="3"><synonyms><ratom name="0"/></synonyms></roleSet>
		<roleSet id="4"><synonyms><ratom name="0"/></synonyms></roleSet>
		<roleSet id="5"><synonyms><ratom name="0"/></synonyms></roleSet>
		<roleSet id="6"><synonyms><ratom name="0"/></synonyms></roleSet>
		</responses>|);
	} elsif ( index ($req->content, '<rparents id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase"') != -1 ){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<roleSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase"><synonyms><ratom name="0"/></synonyms></roleSet>
		</responses>|);
	} elsif ( index ($req->content, '<rchildren id="http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf"') != -1 ){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<roleSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf">
		<synonyms><ratom name="0"/></synonyms><synonyms><ratom name="1"/></synonyms>
		</roleSet></responses>|);
	} elsif ( index ($req->content, '<rancestors id="http://www.owl-ontologies.com/Ontology1206537648.owl#isBaseOf"') != -1 ){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<roleSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#isBaseOf">
		<synonyms><ratom name="0"/></synonyms><synonyms><ratom name="1"/></synonyms>
		</roleSet></responses>|);
	} elsif ( index ($req->content, '<rdescendants id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase"') != -1 ){
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<roleSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase"><synonyms><ratom name="0"/></synonyms></roleSet>
		</responses>|);
	} elsif ( index ($req->content, '<instances id="http://www.owl-ontologies.com/Ontology1206537648.owl#VegetableTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<individualSet id="1"/><individualSet id="2"/><individualSet id="3"/>
		<individualSet id="4"/><individualSet id="5"/><individualSet id="6"/>
		<individualSet id="7"/><individualSet id="8"/><individualSet id="9"/>
		<individualSet id="10"/><individualSet id="11"/><individualSet id="12"/>
		<individualSet id="13"/><individualSet id="14"/><individualSet id="15"/>
		<individualSet id="16"/><individualSet id="17"/><individualSet id="18"/>
		<individualSet id="19"/><individualSet id="20"/><individualSet id="21"/>
		<individualSet id="22"/><individualSet id="23"/><individualSet id="24"/>
		<individualSet id="25"/><individualSet id="26"/><individualSet id="27"/>
		<individualSet id="28"/><individualSet id="29"/><individualSet id="30"/>
		<individualSet id="31"/><individualSet id="32"/><individualSet id="33"/> 
		</responses>|);
	} elsif ( index ($req->content, '<instances id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<individualSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza">
        <individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"/>
    	</individualSet>
		</responses>|);
	} elsif ( index ($req->content, '<types id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="1"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="2"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="3"><synonyms><catom name="0"/></synonyms></conceptSet>
		<conceptSet id="4"><synonyms><catom name="0"/></synonyms></conceptSet>
		</responses>|);
	} elsif ( index ($req->content, '<types id="http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza1"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		<conceptSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza1">
        <synonyms><catom name="http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza"/></synonyms>
        <synonyms><catom name="http://www.w3.org/2002/07/owl#Thing"/></synonyms>
        <synonyms><catom name="http://www.owl-ontologies.com/Ontology1206537648.owl#NamedPizza"/></synonyms>
        <synonyms><catom name="http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza"/></synonyms>
    	</conceptSet></responses>|);
	} elsif( index ($req->content, '<instance') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		    <false id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"/>
		    <true id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"/>
		    <true id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"/>
		</responses>|);
	} elsif( index ($req->content, '<roleFillers') != -1 ) {
			my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
    		<individualSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1">
	        <individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#MozzarellaTopping2"/>
        	<individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#DeepPanBase1"/>
		    </individualSet>
		</responses>|);
	} elsif ( index ($req->content, '<relatedIndividuals id="http://www.owl-ontologies.com/Ontology1206537648.owl#hasTopping"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		    <individualPairSet id="1"><individualPair>
		    <individual name="1a"/><individual name="1b"/>
        	</individualPair></individualPairSet>
   		    <individualPairSet id="2"><individualPair>
		    <individual name="1a"/><individual name="1b"/>
        	</individualPair></individualPairSet>
        	<individualPairSet id="3"><individualPair>
		    <individual name="1a"/><individual name="1b"/>
        	</individualPair></individualPairSet>
        	<individualPairSet id="4"><individualPair>
		    <individual name="1a"/><individual name="1b"/>
        	</individualPair></individualPairSet>
        	<individualPairSet id="5"><individualPair>
		    <individual name="1a"/><individual name="1b"/>
        	</individualPair></individualPairSet>
        	<individualPairSet id="6"><individualPair>
		    <individual name="1a"/><individual name="1b"/>
        	</individualPair></individualPairSet>
		</responses>|);
	} elsif ( index ($req->content, '<relatedIndividuals id="http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf"') != -1 ) {
		my $header = HTTP::Headers->new;
		$header->header ('Content-Type' => 'text/xml');
		$response = HTTP::Response -> new (200, "OK", $header);	
		
		$response->content(q|<?xml version="1.0" encoding="UTF-8"?>
		<responses xmlns="http://dl.kr.org/dig/2003/02/lang">
		    <individualPairSet id="http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf">
        	<individualPair>
            <individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#MozzarellaTopping2"/>
            <individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"/>
	        </individualPair><individualPair>
            <individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#DeepPanBase1"/>
            <individual name="http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1"/>
        	</individualPair></individualPairSet></responses>|);
	}
	
	return $response;
}

1;

use constant GETID_REQ => q|<?xml version="1.0"?>
<getIdentifier xmlns="http://dl.kr.org/dig/2003/02/lang"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
|;


use strict;
use Test::More qw(no_plan);
use RDF::Redland;
use LWP::UserAgent;

my ($url, $ua) = _probe_ua ('http://localhost:8081', 'http://localhost:3490');

sub _probe_ua {
    my $ua = LWP::UserAgent->new;
    $ua->agent ('Test User Agent');
    $ua->timeout(3);
    foreach my $url (@_) {
	my $req = HTTP::Request->new(POST => $url);
	$req->content_type('text/xml');
	$req->content(GETID_REQ);
	my $res = $ua->request ($req);
	return ($url, $ua) if $res->is_success;
    }
    return ('http://does.not.matter/', LWP::Mock->new);
}

warn "# operating with: ".ref ($ua).' against '.$url;

# test cases reasoner
use RDF::Redland::DIG;
my $r = new RDF::Redland::DIG ($url, ua => $ua);
isa_ok ($r, 'RDF::Redland::DIG');

eval {
  ok(! new RDF::Redland::DIG);
}; like ($@, qr/no URL/, 'no URL provided ok');

eval {
  ok(! new RDF::Redland::DIG('http://localhost:9999/'));
}; like ($@, qr/could not be contacted/, 'incorrect URL provided ok');

#use LWP::Mock;
$ua->agent ('My User Agent');

$r = new RDF::Redland::DIG ($url, ua => $ua);
ok($r->{ua}->agent eq "My User Agent", 'own user agent ok');

use RDF::Redland::DIG::KB;
my $kb = $r->kb;
isa_ok ($kb, 'RDF::Redland::DIG::KB');

# test cases knowledge base

my $kb2 = RDF::Redland::DIG::KB->new($r);
isa_ok($kb2, 'RDF::Redland::DIG::KB');

eval {
  ok(! $kb->tell);
}; like ($@, qr/no model/, 'no model provided ok');

undef $/;
my $rdf_string = <DATA>;
my $model = _createModelFromString($rdf_string);
eval {
  ok($kb->tell($model), 'tell request ok');
};

# primitive concept retrieval

my $len = $kb->allConceptNames;
ok( $len == 35 , 'allConceptNames ok');

$len = $kb->allRoleNames;
ok ( $len == 6, 'allRoleNames ok');

$len = $kb->allIndividuals;
ok ($len == 4, 'allIndividuals ok');

# unsatisfiable

$len = $kb->unsatisfiable;
ok ($len == 0, 'no unsatisfiable nodes ok');

# subsumes

eval {
  ok (! $kb->subsumes );
}; like ($@, qr/no data/, 'subsumes no data provided ok');

my %data = (
 'http://www.owl-ontologies.com/Ontology1206537648.owl#NamedPizza' => 
 	['http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza', 
 	 'http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza', 
 	 'http://www.owl-ontologies.com/Ontology1206537648.owl#MargheritaPizza'], 
);

my %res;
my @arr;
my $arrs;

eval {
  %res = $kb->subsumes(\%data);
  $arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#NamedPizza'};
  $len = @ $arrs;
  ok( $len == 2, 'subsumes data provided ok');
};

# disjoint

eval {
  ok (! $kb->disjoint );
}; like ($@, qr/no data/, 'disjoint no data provided ok');

%data = (
 'http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza' => 
 ['http://www.owl-ontologies.com/Ontology1206537648.owl#RedPepperTopping', 
  'http://www.owl-ontologies.com/Ontology1206537648.owl#PizzaTopping', 
  'http://www.owl-ontologies.com/Ontology1206537648.owl#MargheritaPizza'], 
);

eval {
  %res = $kb->disjoint(\%data);
  $arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza'};
  $len = @ $arrs;
  ok( $len == 2, 'disjoint data provided ok');
};

# parents

%res = $kb->parents;
@arr = keys (%res);
$len = @arr;
ok ( $len == 33, 'parents no data provided ok' );

%res = $kb->parents ('http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanHotPizza');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanHotPizza'};
$len = @ $arrs;

ok( $len == 1, 'parents data provided ok');

# children 

%res = $kb->children;
@arr = keys (%res);
$len = @arr;
ok ( $len == 33, 'children no data provided ok' );

%res = $kb->children ('http://www.owl-ontologies.com/Ontology1206537648.owl#MeatTopping');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#MeatTopping'};
$len = @ $arrs;

ok( $len == 4, 'children data provided ok');

# descendants

%res = $kb->descendants;
@arr = keys (%res);
$len = @arr;
ok ( $len == 33, 'descendants no data provided ok' );

%res = $kb->descendants ('http://www.owl-ontologies.com/Ontology1206537648.owl#PizzaTopping');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#PizzaTopping'};
$len = @ $arrs;

ok( $len == 22, 'descendants data provided ok');

# ancestors

%res = $kb->ancestors;
@arr = keys (%res);
$len = @arr;
ok ( $len == 33, 'ancestors no data provided ok' );

%res = $kb->ancestors ('http://www.owl-ontologies.com/Ontology1206537648.owl#GreenPepperTopping');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#GreenPepperTopping'};
$len = @ $arrs;

ok( $len == 3, 'ancestors data provided ok');

# equivalents

%res = $kb->equivalents;
@arr = keys (%res);
$len = @arr;
ok ( $len == 33, 'equivalents no data provided ok' );

%res = $kb->equivalents ('http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza'};
$len = @ $arrs;

ok( $len == 2, 'equivalents data provided ok');

# rparents

%res = $kb->rparents;
@arr = keys (%res);
$len = @arr;
ok ( $len == 6, 'rparents no data provided ok' );

%res = $kb->rparents ('http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase'};
$len = @ $arrs;

ok( $len == 1, 'rparents data provided ok');

# rchildren 

%res = $kb->rchildren;
@arr = keys (%res);
$len = @arr;
ok ( $len == 6, 'rchildren no data provided ok' );

%res = $kb->rchildren ('http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf'};
$len = @ $arrs;

ok( $len == 2, 'rchildren data provided ok');

# rdescendants

%res = $kb->rdescendants;
@arr = keys (%res);
$len = @arr;
ok ( $len == 6, 'rdescendants no data provided ok' );

%res = $kb->rdescendants ('http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#hasBase'};
$len = @ $arrs;

ok( $len >= 0, 'rdescendants data provided ok');

# rancestors

%res = $kb->rancestors;
@arr = keys (%res);
$len = @arr;
ok ( $len == 6, 'rancestors no data provided ok' );

%res = $kb->rancestors ('http://www.owl-ontologies.com/Ontology1206537648.owl#isBaseOf');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#isBaseOf'};
$len = @ $arrs;

ok( $len >= 1, 'rancestors data provided ok');

# instances

%res = $kb->instances;
@arr = keys (%res);
$len = @arr;
ok ( $len == 33, 'instances no data provided ok' );

%res = $kb->instances ('http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza'};
$len = @ $arrs;

ok( $len == 1, 'instances data provided ok');

# types

%res = $kb->types;
@arr = keys (%res);
$len = @arr;
ok ( $len == 4, 'types no data provided ok' );

%res = $kb->types ('http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza1');
$arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza1'};
$len = @ $arrs;

ok( $len >= 1, 'types data provided ok');

# instance

eval {
  ok (! $kb->instance );
}; like ($@, qr/no data/, 'instance no data provided ok');

%data = (
  'http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1' => 
 ['http://www.owl-ontologies.com/Ontology1206537648.owl#AmericanaPizza', 
  'http://www.owl-ontologies.com/Ontology1206537648.owl#Pizza', 
  'http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza2'] 
);

eval {
  %res = $kb->instance(\%data);
  $arrs = $res {'http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1'};
  $len = @ $arrs;
  ok( $len == 2, 'instance data provided ok');
};

# roleFillers

eval {
  ok (! $kb->roleFillers );
}; like ($@, qr/no data/, 'roleFillers no data provided ok');

%data = (
  'http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1' => 
  ['http://www.owl-ontologies.com/Ontology1206537648.owl#hasIngredient'], 
);

eval {
  @arr = $kb->roleFillers('http://www.owl-ontologies.com/Ontology1206537648.owl#CheesyPizza1',
  						  'http://www.owl-ontologies.com/Ontology1206537648.owl#hasIngredient');
  $len = @ arr;
  ok( $len >= 2, 'roleFillers data provided ok');
};

# relatedIndividuals

eval {
  ok (! $kb->relatedIndividuals );
}; like ($@, qr/no data/, 'relatedIndividuals no data provided ok');

@arr = $kb->relatedIndividuals ('http://www.owl-ontologies.com/Ontology1206537648.owl#isIngredientOf');
$len = @arr;
ok( $len >= 2, 'relatedIndividuals data provided ok');

sub _createModelFromString{
	my $rdf_string = shift;
	
	use RDF::Redland;
	
	#create a new parser
	my $parser = new RDF::Redland::Parser (undef, "application/rdf+xml")
    or die "Failed to find parser\n";
	
	my $storage = new RDF::Redland::Storage (
                  "hashes",
                  "test",
                  "new='yes', hash-type='memory'")
      or die "Failed to create RDF::Redland::Storage";

	
	# create a new model
	my $model = new RDF::Redland::Model ($storage, "")
      or die "Failed to create RDF::Redland::Model for storage";
	
	my $uri = new RDF::Redland::URI ("http://rumsti");
	# write data from file into model
	$parser->parse_string_into_model ($rdf_string, $uri, $model);

	return $model;

}


__DATA__
<?xml version="1.0"?>


<!DOCTYPE rdf:RDF [
    <!ENTITY owl "http://www.w3.org/2002/07/owl#" >
    <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
]>


<rdf:RDF xmlns="http://www.owl-ontologies.com/Ontology1206537648.owl#"
     xml:base="http://www.owl-ontologies.com/Ontology1206537648.owl"
     xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
     xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
     xmlns:owl="http://www.w3.org/2002/07/owl#">
    <owl:Ontology rdf:about=""/>
    <owl:Class rdf:ID="AmericanaPizza">
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#PepperoniTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#TomatoTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#MozzarellaTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf rdf:resource="#NamedPizza"/>
    </owl:Class>
    <AmericanaPizza rdf:ID="AmericanaPizza1"/>
    <owl:Class rdf:ID="AmericanHotPizza">
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#JalapenoPepperTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#PepperoniTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#TomatoTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#MozzarellaTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf rdf:resource="#NamedPizza"/>
    </owl:Class>
    <owl:Class rdf:ID="AnchovyTopping">
        <rdfs:subClassOf rdf:resource="#SeafoodTopping"/>
        <owl:disjointWith rdf:resource="#PrawnTopping"/>
        <owl:disjointWith rdf:resource="#TunaTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="CaperTopping">
        <rdfs:subClassOf rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#OnionTopping"/>
        <owl:disjointWith rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#MushroomTopping"/>
        <owl:disjointWith rdf:resource="#OliveTopping"/>
        <owl:disjointWith rdf:resource="#TomatoTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="CheeseTopping">
        <rdfs:subClassOf rdf:resource="#PizzaTopping"/>
        <owl:disjointWith rdf:resource="#SeafoodTopping"/>
        <owl:disjointWith rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#MeatTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="CheesyPizza">
        <owl:equivalentClass>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#CheeseTopping"/>
            </owl:Restriction>
        </owl:equivalentClass>
        <rdfs:subClassOf rdf:resource="#Pizza"/>
    </owl:Class>
    <CheesyPizza rdf:ID="CheesyPizza1">
        <hasBase rdf:resource="#DeepPanBase1"/>
        <hasTopping rdf:resource="#MozzarellaTopping2"/>
    </CheesyPizza>
    <owl:Class rdf:ID="CheesyPizza2">
        <owl:equivalentClass>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#CheeseTopping"/>
            </owl:Restriction>
        </owl:equivalentClass>
        <rdfs:subClassOf rdf:resource="#Pizza"/>
    </owl:Class>
    <owl:Class rdf:ID="DeepPanBase">
        <rdfs:subClassOf rdf:resource="#PizzaBase"/>
        <owl:disjointWith rdf:resource="#ThinAndCrispyBase"/>
    </owl:Class>
    <DeepPanBase rdf:ID="DeepPanBase1">
        <isBaseOf rdf:resource="#CheesyPizza1"/>
    </DeepPanBase>
    <owl:Class rdf:ID="GreenPepperTopping">
        <rdfs:subClassOf rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#JalapenoPepperTopping"/>
        <owl:disjointWith rdf:resource="#RedPepperTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="HamTopping">
        <rdfs:subClassOf rdf:resource="#MeatTopping"/>
        <owl:disjointWith rdf:resource="#SalamiTopping"/>
        <owl:disjointWith rdf:resource="#PepperoniTopping"/>
        <owl:disjointWith rdf:resource="#SpicyBeefTopping"/>
    </owl:Class>
    <owl:ObjectProperty rdf:ID="hasBase">
        <rdf:type rdf:resource="&owl;FunctionalProperty"/>
        <rdfs:domain rdf:resource="#Pizza"/>
        <rdfs:range rdf:resource="#PizzaBase"/>
        <owl:inverseOf rdf:resource="#isBaseOf"/>
        <rdfs:subPropertyOf rdf:resource="#hasIngredient"/>
    </owl:ObjectProperty>
    <owl:ObjectProperty rdf:ID="hasIngredient">
        <rdf:type rdf:resource="&owl;TransitiveProperty"/>
        <owl:inverseOf rdf:resource="#isIngredientOf"/>
    </owl:ObjectProperty>
    <owl:ObjectProperty rdf:ID="hasTopping">
        <rdfs:domain rdf:resource="#Pizza"/>
        <rdfs:range rdf:resource="#PizzaTopping"/>
        <owl:inverseOf rdf:resource="#isToppingOf"/>
        <rdfs:subPropertyOf rdf:resource="#hasIngredient"/>
    </owl:ObjectProperty>
    <owl:ObjectProperty rdf:ID="isBaseOf">
        <rdf:type rdf:resource="&owl;InverseFunctionalProperty"/>
        <rdfs:domain rdf:resource="#PizzaBase"/>
        <rdfs:range rdf:resource="#Pizza"/>
        <owl:inverseOf rdf:resource="#hasBase"/>
        <rdfs:subPropertyOf rdf:resource="#isIngredientOf"/>
    </owl:ObjectProperty>
    <owl:ObjectProperty rdf:ID="isIngredientOf">
        <owl:inverseOf rdf:resource="#hasIngredient"/>
    </owl:ObjectProperty>
    <owl:ObjectProperty rdf:ID="isToppingOf">
        <rdfs:domain rdf:resource="#PizzaTopping"/>
        <rdfs:range rdf:resource="#Pizza"/>
        <owl:inverseOf rdf:resource="#hasTopping"/>
        <rdfs:subPropertyOf rdf:resource="#isIngredientOf"/>
    </owl:ObjectProperty>
    <owl:Class rdf:ID="JalapenoPepperTopping">
        <rdfs:subClassOf rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#GreenPepperTopping"/>
        <owl:disjointWith rdf:resource="#RedPepperTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="MargheritaPizza">
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#TomatoTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasTopping"/>
                <owl:someValuesFrom rdf:resource="#MozzarellaTopping"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf rdf:resource="#NamedPizza"/>
    </owl:Class>
    <owl:Class rdf:ID="MeatTopping">
        <rdfs:subClassOf rdf:resource="#PizzaTopping"/>
        <owl:disjointWith rdf:resource="#SeafoodTopping"/>
        <owl:disjointWith rdf:resource="#CheeseTopping"/>
        <owl:disjointWith rdf:resource="#VegetableTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="MozzarellaTopping">
        <rdfs:subClassOf rdf:resource="#CheeseTopping"/>
        <owl:disjointWith rdf:resource="#ParmezanTopping"/>
    </owl:Class>
    <MozzarellaTopping rdf:ID="MozzarellaTopping2">
        <isToppingOf rdf:resource="#CheesyPizza1"/>
    </MozzarellaTopping>
    <owl:Class rdf:ID="MushroomTopping">
        <rdfs:subClassOf rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#CaperTopping"/>
        <owl:disjointWith rdf:resource="#OnionTopping"/>
        <owl:disjointWith rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#OliveTopping"/>
        <owl:disjointWith rdf:resource="#TomatoTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="NamedPizza">
        <rdfs:subClassOf rdf:resource="#Pizza"/>
    </owl:Class>
    <owl:Class rdf:ID="OliveTopping">
        <rdfs:subClassOf rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#CaperTopping"/>
        <owl:disjointWith rdf:resource="#OnionTopping"/>
        <owl:disjointWith rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#MushroomTopping"/>
        <owl:disjointWith rdf:resource="#TomatoTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="OnionTopping">
        <rdfs:subClassOf rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#CaperTopping"/>
        <owl:disjointWith rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#MushroomTopping"/>
        <owl:disjointWith rdf:resource="#OliveTopping"/>
        <owl:disjointWith rdf:resource="#TomatoTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="ParmezanTopping">
        <rdfs:subClassOf rdf:resource="#CheeseTopping"/>
        <owl:disjointWith rdf:resource="#MozzarellaTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="PepperoniTopping">
        <rdfs:subClassOf rdf:resource="#MeatTopping"/>
        <owl:disjointWith rdf:resource="#HamTopping"/>
        <owl:disjointWith rdf:resource="#SalamiTopping"/>
        <owl:disjointWith rdf:resource="#SpicyBeefTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="PepperTopping">
        <rdfs:subClassOf rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#CaperTopping"/>
        <owl:disjointWith rdf:resource="#OnionTopping"/>
        <owl:disjointWith rdf:resource="#MushroomTopping"/>
        <owl:disjointWith rdf:resource="#OliveTopping"/>
        <owl:disjointWith rdf:resource="#TomatoTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="Pizza">
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="#hasBase"/>
                <owl:someValuesFrom rdf:resource="#PizzaBase"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf rdf:resource="&owl;Thing"/>
        <owl:disjointWith rdf:resource="#PizzaBase"/>
        <owl:disjointWith rdf:resource="#PizzaTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="PizzaBase">
        <owl:disjointWith rdf:resource="#Pizza"/>
        <owl:disjointWith rdf:resource="#PizzaTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="PizzaTopping">
        <owl:disjointWith rdf:resource="#PizzaBase"/>
        <owl:disjointWith rdf:resource="#Pizza"/>
    </owl:Class>
    <owl:Class rdf:ID="PrawnTopping">
        <rdfs:subClassOf rdf:resource="#SeafoodTopping"/>
        <owl:disjointWith rdf:resource="#AnchovyTopping"/>
        <owl:disjointWith rdf:resource="#TunaTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="RedPepperTopping">
        <rdfs:subClassOf rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#JalapenoPepperTopping"/>
        <owl:disjointWith rdf:resource="#GreenPepperTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="SalamiTopping">
        <rdfs:subClassOf rdf:resource="#MeatTopping"/>
        <owl:disjointWith rdf:resource="#HamTopping"/>
        <owl:disjointWith rdf:resource="#PepperoniTopping"/>
        <owl:disjointWith rdf:resource="#SpicyBeefTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="SeafoodTopping">
        <rdfs:subClassOf rdf:resource="#PizzaTopping"/>
        <owl:disjointWith rdf:resource="#CheeseTopping"/>
        <owl:disjointWith rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#MeatTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="SpicyBeefTopping">
        <rdfs:subClassOf rdf:resource="#MeatTopping"/>
        <owl:disjointWith rdf:resource="#HamTopping"/>
        <owl:disjointWith rdf:resource="#SalamiTopping"/>
        <owl:disjointWith rdf:resource="#PepperoniTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="ThinAndCrispyBase">
        <rdfs:subClassOf rdf:resource="#PizzaBase"/>
        <owl:disjointWith rdf:resource="#DeepPanBase"/>
    </owl:Class>
    <owl:Class rdf:ID="TomatoTopping">
        <rdfs:subClassOf rdf:resource="#VegetableTopping"/>
        <owl:disjointWith rdf:resource="#CaperTopping"/>
        <owl:disjointWith rdf:resource="#OnionTopping"/>
        <owl:disjointWith rdf:resource="#PepperTopping"/>
        <owl:disjointWith rdf:resource="#MushroomTopping"/>
        <owl:disjointWith rdf:resource="#OliveTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="TunaTopping">
        <rdfs:subClassOf rdf:resource="#SeafoodTopping"/>
        <owl:disjointWith rdf:resource="#PrawnTopping"/>
        <owl:disjointWith rdf:resource="#AnchovyTopping"/>
    </owl:Class>
    <owl:Class rdf:ID="VegetableTopping">
        <rdfs:subClassOf rdf:resource="#PizzaTopping"/>
        <owl:disjointWith rdf:resource="#SeafoodTopping"/>
        <owl:disjointWith rdf:resource="#CheeseTopping"/>
        <owl:disjointWith rdf:resource="#MeatTopping"/>
    </owl:Class>
</rdf:RDF>
