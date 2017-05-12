#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Parser/XML/Slow.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/10/2004
# Revision:	$Id: Slow.pm,v 1.48 2009-11-25 17:54:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Parser::XML::Slow;

use strict;
use warnings;

use ODO::Exception;
use ODO::Parser::XML::RDFAttributes;

use XML::SAX qw/Namespaces Validation/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.50 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Parser::XML/;

__PACKAGE__->mk_accessors(qw/base_uri/);

our $VERBOSE = 0;

=head1 NAME

ODO::Parser::XML::Slow

=head1 SYNOPSIS

 my $parser = ODO::Parser::XML->new();
 my $statements = $parser->parse($RDF);

 foreach my $stmt (@{ $statements }) {
 	# Manipulate the ODO::Statement($stmt) here
 }
	
=head1 DESCRIPTION

=head1 METHODS

=over

=item parse_rdf( $rdf | GLOB ) 

 Parameters:

   $rdf - Required. 

 Returns:

   An array ref of ODO::Statement's or 
   undef if there is an error parsing the RDF

=cut

sub parse_rdf {
	my ($self, $rdf) = @_;

	my $factory = XML::SAX::ParserFactory->new();
	$factory->require_feature(Namespaces);
	
	my $handler = ODO::Parser::XML::Slow::Handler->new(base_uri=> $self->base_uri());
	$handler->verbose($VERBOSE);
	
	my $parser = $factory->parser(Handler=> $handler );
	
	my $method = 'parse_string';
	
	$method = 'parse_file'
		if(ref $rdf eq 'GLOB');
	
	eval {  $parser->$method($rdf);  };
	
	throw ODO::Exception::RDF::Parse(error=> "Unable to parse RDF: $@")
		if($@);
	my $statements = (scalar( @{ $handler->statements() }) >= 0) ? $handler->statements() : undef;
	my $imports = (scalar( @{ $handler->owl_imports() }) >= 0) ? $handler->owl_imports() : undef;
	return ($statements, $imports);
}

sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/base_uri/);
	return $self;
}

=back

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut


package ODO::Parser::XML::Fragment;

use strict;
use warnings;

use base qw/ODO/;

our @METHODS = qw/base_uri subject language uri qname attributes parent children xtext text/;

__PACKAGE__->mk_accessors(@METHODS);

sub init {
	my ($self, $config) = @_;
	
	$self->params($config, @METHODS);
	
	$self->uri( $config->{'namespace'} . $config->{'name'} )
		unless(exists($config->{'uri'}));
	
	$self->qname( $config->{'namespace'} . ':' . $config->{'name'} )
		unless(exists($config->{'qname'}));

	$self->xtext( [] );
	$self->children( [] );
	
	return $self;
}


package ODO::Parser::XML::Slow::Handler;

use strict;
use warnings;

use ODO::Node;
use ODO::Statement;

use URI;
use Encode qw/encode decode/; # For Unicode processing 

use XML::RegExp;

use XML::Namespace
	xml=> 'http://www.w3.org/XML/1998/namespace#',
	xsd=> 'http://www.w3.org/2001/XMLSchema#',
	rdfs=> 'http://www.w3.org/2000/01/rdf-schema#',
	rdf=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	owl => 'http://www.w3.org/2002/07/owl#'
;

use Data::Dumper;

use base qw/XML::SAX::Base ODO/;

__PACKAGE__->mk_accessors(qw/verbose base_uri blank_node_uri_prefix stack seen_id statements blank_nodes owl_imports gatherOwlImports/);


our $RESERVED = [
		'RDF',
		'ID',
		'about',
		'parseType',
		'type',
		'resource',
		'nodeID',
		'aboutEach',
		'aboutEachPrefix',
		'bagID',
		'datatype',
		'li',
];

our $FORBIDDEN_PROPERTY = [
		'Description',
		'RDF',
		'ID',
		'about',
		'parseType',
		'bagID',
		'resource',
		'nodeID',
		'aboutEach',
		'aboutEachPrefix',
];


sub new {
	my $self = shift;
	$self = $self->SUPER::new(@_);

	$self->stack( [] );
	$self->statements( [] );
    $self->owl_imports( [] );
    $self->gatherOwlImports([]);

	$self->seen_id( {} );
	$self->blank_nodes( {} );
	if ($self->base_uri()) {
		my $uri = $self->base_uri();
		$uri =~ s/#+$//;
		$self->base_uri($uri);
	}

	return $self;
}


sub add_statement {
	my ($self, $s, $p, $o) = @_;
	
	unless(UNIVERSAL::isa($s, 'ODO::Node')
		&& UNIVERSAL::isa($p, 'ODO::Node')
		&& UNIVERSAL::isa($o, 'ODO::Node')) {
	
		my $str = '';
		
		$str = 'Subject is undefined, '
			unless($s);
		
		$str .= 'Predicate is undefined, '
			unless($p);
		
		$str .= 'Object is undefined '
			unless($o);
		throw XML::SAX::Exception::Parse(Message=> 'Fatal error in parsing, statement has undefined elements: ' . $str);
	}
	
	my $statement = ODO::Statement->new(s=> $s, p=> $p, o=> $o);
	throw XML::SAX::Exception::Parse(Message=> 'Cannot add an undefined statement.')
		unless(UNIVERSAL::isa($statement, 'ODO::Statement'));
	push @{ $self->statements() }, $statement;
}


sub is_reserved_uri {
	my ($self, $uri) = @_;
	
	my $rdfNS = rdf->uri();
	
	foreach my $name (@{ $RESERVED } ) {
		return 1
			if($uri eq "${rdfNS}${name}");
	}
	
	return 0;
}


sub is_forbidden_property {
	my ($self, $uri) = @_;
	
	my $rdfNS = rdf->uri();
		
	foreach my $name (@{ $FORBIDDEN_PROPERTY } ) {
		return 1
			if($uri eq "${rdfNS}${name}");
	}
	
	return 0;
}


sub validate_NodeElement_attributes {
	my ($self, $attributes) = @_;
	
	if ( $attributes->{ rdf->uri('ID') } && $attributes->{ rdf->uri('nodeID') }) {
		throw XML::SAX::Exception::Parse(Message=> 'Cannot have rdf:nodeID and rdf:ID.');
	}	
	elsif ( $attributes->{ rdf->uri('about') } && $attributes->{ rdf->uri('nodeID') }) {
		throw XML::SAX::Exception::Parse(Message=> 'Cannot have rdf:nodeID and rdf:about.');
	}
	elsif ( $attributes->{ rdf->uri('nodeID') } && $attributes->{ rdf->uri('resource') }) {
		throw XML::SAX::Exception::Parse(Message=> 'Cannot have rdf:nodeID and rdf:resource.');
	}
	else {
		return 1;
	}
}

sub validate_PropertyElt_attributes {
	my ($self, $attributes) = @_;
	
	if(   exists($attributes->{ rdf->uri('about') }) 
	   && exists($attributes->{ rdf->uri('nodeID') }) ) {
		throw XML::SAX::Exception::Parse(Message=> 'Cannot have rdf:nodeID and rdf:about.');
	}
	elsif(   exists($attributes->{ rdf->uri('nodeID') }) 
		  && exists($attributes->{ rdf->uri('resource') }) ) {
		throw XML::SAX::Exception::Parse(Message=> 'Cannot have rdf:nodeID and rdf:resource.');
	}
	elsif(   exists($attributes->{ rdf->uri('parseType') })
		  && $attributes->{ rdf->uri('parseType') } eq 'Literal'
		  && exists($attributes->{ rdf->uri('resource') }) ) {
		throw XML::SAX::Exception::Parse(Message=> 'This is not legal RDF; specifying an rdf:parseType of "Literal" and an rdf:resource attribute at the same time is an error.');
	}
	elsif(   exists($attributes->{ rdf->uri('parseType') })
		  && $attributes->{ rdf->uri('parseType') } eq 'Literal') {
		# We can't allow parseType='Literal' and allow random properties which would make
		# this _NOT_ a Literal 
		# This is a lot like the previous check		
		foreach my $attr (keys(%{ $attributes })) {
			my $xml_uri = xml->uri();
			next 
				if($attr eq rdf->uri('parseType') || $attr =~ /^ $xml_uri/);
			
			throw XML::SAX::Exception::Parse(Message=> 'Cannot have property attributes with attribute: rdf:parseType="Literal"');
		}
	}
	else {
		# Check for invalid parseType (ParseType, parsetype, Parsetype)
		# This seems bizarre
		foreach my $attr (keys(%{ $attributes })) {
			throw XML::SAX::Exception::Parse(Message=> 'This RDF is not legal because the parseType attribute is mis-spelled.')
				if($attr =~ m/^.*(parsetype|Parsetype|ParseType)$/);
		}	
	}
	
	return 1;
}


sub blank_node {
	my ($self, $nodeID) = @_;

	# We record new blank node IDs after we 'see' them, once we've seen
	# an ID it must be returned every time we see it in the future
	unless($nodeID && exists($self->blank_nodes()->{ $nodeID })) {
		# Some nodes may not have a URI so we need to generate one
		unless($nodeID) {
			# The current time as well as a random number should be sufficient.
			# I'm not sure what is in the spec as far as valid unique node IDs are
			# concerned
			do {
				$nodeID = sprintf( "genid%08x%04x", time(), int(rand(0xFFFF)) );
	
				$nodeID = $self->blank_node_uri_prefix() . $nodeID
					if($self->blank_node_uri_prefix());
				
			} while(exists($self->blank_nodes()->{ $nodeID }));
		}
		
		$self->blank_nodes()->{ $nodeID } = "_:$nodeID";
	}
	
	return $self->blank_nodes()->{ $nodeID };
}


sub reify_statement {
	my ($self, $r, $s, $p, $o) = @_;
	
	# S, P, O of statement quad
	$self->add_statement($r, ${ODO::Parser::REIFY_SUBJECT}, $s);
	$self->add_statement($r, ${ODO::Parser::REIFY_PREDICATE}, $p);
	$self->add_statement($r, ${ODO::Parser::REIFY_OBJECT}, $o);

	# Statement itself
	$self->add_statement($r, ${ODO::Parser::RDF_TYPE}, ${ODO::Parser::REIFY_STATEMENT});
}


sub start_element {
	my ($self, $sax) = @_;
	
	my $attributes = ODO::Parser::XML::RDF::Attributes->new(%{ $sax->{'Attributes'} });

	my $parent = undef;
	my $base_uri = $self->base_uri();
	if ( scalar(@{ $self->stack() }) > 0 ) {
		$parent = $self->stack()->[-1];
		$base_uri = ( $self->stack()->[-1]->base_uri() || $self->base_uri() );
	}
	
	my $element = ODO::Parser::XML::Fragment->new(
		{
			namespace=> $sax->{'NamespaceURI'}, 
			prefix=> $sax->{'Prefix'}, 
			name=> $sax->{'LocalName'},
			parent=> $parent,
			attributes=> $attributes,
			base_uri=> $base_uri,
		}
	);
	if ($element->uri() eq rdf->uri('RDF')) {
		my $baseURI = $element->attributes()->{xml->uri('base')};
		if ($baseURI) {
			# strip all trailing # from URI
			$baseURI =~ s/#*$//i;
			# append a hash unless uri ends with /
			$baseURI .= '#' unless $baseURI =~ m/\/$/;
			$element->base_uri( $baseURI );
			$self->base_uri( $baseURI );
		}
    } elsif ($element->uri() eq owl->uri('Ontology')) {
        if (scalar @{$self->gatherOwlImports()} >= 1) {
        	my $import = $element->attributes()->{rdf->uri('resource')};
        	$import = $element->attributes()->{rdf->uri('about')} unless defined $import and $import ne '';
            push @{ $self->owl_imports() }, $import if defined $import and $import ne '';
        }
        push @{$self->gatherOwlImports()}, "ontology";
    } elsif ($element->uri() eq owl->uri('imports') and scalar(@{$self->gatherOwlImports()}) > 0) {
    	my $import = $element->attributes()->{rdf->uri('resource')};
    	push @{ $self->owl_imports() }, $import if defined $import and $import ne '';        
    }
    
	 
	
	push @{ $element->xtext() }, '<' .$sax->{'Prefix'} . ' ' . ODO::Parser::XML::RDF::Attributes->to_string($element->attributes()) . '>';
	push @{ $self->stack() }, $element;
}

sub characters {
	my ($self, $chars) = @_;
	# trim space from characters
	$chars->{'Data'} =~ s/^\s+//gm;
	$chars->{'Data'} =~ s/\s+$//gm;
	# if there is no text, return
	return if $chars->{'Data'} eq ''; 
	$self->stack()->[-1]->text($chars->{'Data'});
	push @{ $self->stack()->[-1]->xtext() }, $chars->{'Data'};
}

sub end_element {
	my ($self, $sax) = @_;
	
	my $element = pop @{ $self->stack() };
	push @{ $element->xtext() }, '</' . $sax->{'Name'} . '>';
	
	# stop processing owl imports - well at least pop array
	if ($element->uri() eq owl->uri('Ontology')) {
        pop @{$self->gatherOwlImports()};
    }
    
	if ( scalar(@{ $self->stack() }) > 0 ) {
		push @{ $self->stack()->[-1]->children() }, $element;
		@{ $element->xtext() } = grep { defined($_) } @{ $element->xtext() };
		$self->stack()->[-1]->xtext()->[1] = join('', @{ $element->xtext() } );
	}
	else {
		# The root element might not be rdf:RDF so we locate it for further
		# processing according to:
		#
		# doc =
		#   RDF | nodeElement
		#
		# Locate the RDF URI for production:
		#
		# RDF =
		#   element rdf:RDF {
		#      xmllang?, xmlbase?, nodeElementList
		# }
		# FIXME: This is TEMPORARY!
		my $rdf_root_element = $element;
		
		unless($element->uri() eq rdf->uri('RDF')) {
			foreach my $c (@{ $element->children() }) {
				if($c->uri() eq rdf->uri('RDF')) {
				
					# Found the rdf:RDF root element
					$rdf_root_element = $c;
					last;
				}
			}
		}
		
		# FIXME: Should we look for xml:base attributes here?
		# If we didn't find the element process the node as a nodeElement
		$self->nodeElement($element)
			unless($rdf_root_element);
		
		
		# Proceed down the RDF path of the grammar
		return
			unless (scalar(@{ $element->children() }) > 0 );
		
		# The rdf:RDF element may have an xml:base attribute setting the base
		# namespace of a relative URI
		$element->base_uri( $rdf_root_element->attributes()->{xml->uri('base')} )
			if(exists($rdf_root_element->attributes()->{xml->uri('base')}));
		
		# TODO: Handle the xml:lang attribute

		# Now we begin the nodeElementList processing:
		#
		# nodeElementList = 
		#   nodeElement*
		#
		foreach my $e (@{ $rdf_root_element->children() }) {
			# Children inherit the baseURI of their parent
			$e->base_uri( $rdf_root_element->base_uri() );

			eval { $self->nodeElement($e) };
			if($@) {
				$self->{'statements'} = [];
				throw XML::SAX::Exception::Parse(Message=> $@);
			}		
		}
	}
}


# 7.2.11 Production nodeElement
#
# nodeElement =
#   element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                 rdf:resource | rdf:nodeID | rdf:datatype | rdf:li |
#                 rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID ) {
#       (idAttr | nodeIdAttr | aboutAttr )?, xmllang?, xmlbase?, propertyAttr*, propertyEltList
#   }
#
sub nodeElement {	
	my ( $self, $e ) = @_;

	throw XML::SAX::Exception::Parse(Message=> 'URI: ' . $e->uri() . ' is reserved from nodeElement names')
		if($e->uri() ne rdf->uri('type') && $self->is_reserved_uri( $e->uri() ));
	
	my $baseURI = ($e->base_uri() || $self->base_uri());

	$baseURI = $e->attributes()->{xml->uri('base')}
		if(exists($e->attributes()->{xml->uri('base')}));
	$baseURI = $baseURI || '';
	
	my $s;
	
	# Throws an XML::SAX::Exception
	$self->validate_NodeElement_attributes( $e->attributes() );

	# These can be processed in any order:
	if ( $e->attributes()->{ rdf->uri('ID') } ) {

		# If there is an attribute a with a.URI == rdf:ID, 
		# then e.subject := uri(identifier := resolve(e, concat("#", a.string-value))).
		throw XML::SAX::Exception::Parse(Message=> 'The value of rdf:ID must match the XML Name production, (as modified by XML Namespaces).')
			if(!$e->attributes()->{ rdf->uri('ID') } =~ m/$XML::RegExp::NCName/);
		# use $baseURI if we dont already have a URI
		my $idURI = $e->attributes->{rdf->uri('ID')};
		if ($idURI =~ m|.*://|){
			$s = ODO::Node::Resource->new( $idURI );
		} else {
			$idURI =~ s/^#*// if $idURI;
			$idURI = $baseURI . $idURI if $baseURI =~ m/#$/ or $baseURI =~ m/\/$/;
			$idURI = $baseURI . '#'. $idURI unless $baseURI =~ m/#$/ or $baseURI =~ m/\/$/;
			$s = ODO::Node::Resource->new( $idURI);
		}
		
		
		throw XML::SAX::Exception::Parse(Message=> 'Duplicate rdf:ID specified: ' . $s->value())
			if(exists($self->seen_id()->{ $s->value() }));

		$e->subject( $s );
		$self->seen_id()->{ $s->value() } = 1;
	}
	elsif ( $e->attributes()->{ rdf->uri('nodeID') } ) {
		# If there is an attribute a with a.URI == rdf:nodeID, 
		# then e.subject := bnodeid(identifier:=a.string-value).
		throw XML::SAX::Exception::Parse(Message=> 'The value of rdf:nodeID must match the XML Name production, (as modified by XML Namespaces).')
			if(!$e->attributes()->{ rdf->uri('nodeID') } =~ m/$XML::RegExp::NCName/);
	
		$s = ODO::Node::Blank->new();		
		$s->uri( $self->blank_node( $e->attributes()->{ rdf->uri('nodeID') } ) );
		
		$e->subject( $s );
	}
	elsif ( $e->attributes()->{ rdf->uri('about') } ) {
		# If there is an attribute a with a.URI == rdf:about 
		# then e.subject := uri(identifier := resolve(e, a.string-value)).
		my $aboutUri = $e->attributes()->{ rdf->uri('about') };
		if ($aboutUri =~ m|.*://|) {
			$s = ODO::Node::Resource->new( $aboutUri);
		} else {
			$aboutUri =~ s/^#*//;
			if ($baseURI) {
				$baseURI =~ s/#*$//g;
				$baseURI .= '#' unless $baseURI =~ m/\/$/;
			}
			$s = ODO::Node::Resource->new( ($baseURI || '') . $aboutUri);
		}
		$e->subject( $s );
	}
	elsif ( !$e->subject() ) {
		# If e.subject is empty, then e.subject := bnodeid(identifier := generated-blank-node-id()).
		$s = ODO::Node::Blank->new($self->blank_node());
		
		$e->subject($s);
	}
	else {
		# Nothing to do here in the spec
	}

	my $p;
	my $o;
	
	#  If e.URI != rdf:Description then the following statement is added to the graph:
	if ( $e->uri() ne rdf->uri('Description') ) {
		$p = ODO::Node::Resource->new(rdf->uri('type'));
		$o = ODO::Node::Resource->new($e->uri());

		$self->add_statement($e->subject(), $p, $o);
	}

	# If there is an attribute a in propertyAttr with a.URI == rdf:type 
	# then u:=uri(identifier:=resolve(a.string-value)) and the following tiple is added to the graph:	
	if ( $e->attributes()->{ rdf->uri('type') } ) {
		$p = ODO::Node::Resource->new( rdf->uri('type') );
		$o = ODO::Node::Resource->new( $e->attributes()->{ rdf->uri('type') } );
		$self->add_statement($e->subject(), $p, $o);
	}
	
	# For each attribute a matching propertyAttr (and not rdf:type), 
	# the Unicode string a.string-value SHOULD be in Normal Form C[NFC], 
	# o := literal(literal-value := a.string-value, literal-language := e.language) 
	# and the following statement is added to the graph:
	foreach my $k ( keys(%{ $e->attributes() }) ) {
		if ( !$self->is_reserved_uri( $k ) ) {
	
			$p = ODO::Node::Resource->new( $k );

			$o = ODO::Node::Literal->new();
			$o->value( $e->attributes->{ $k } );
			$o->language( $e->language() );
			$self->add_statement($e->subject(), $p ,$o);
		}
	}

	# Handle the propertyEltList children events in document order.
	#
	# propertyEltList = 
	#   propertyElt*		
	#
	foreach my $propertyElement (@{ $e->children() }) {
		# Propagate the baseURI that was selected to the children
		if ($baseURI) {
			$baseURI =~ s/#*$//i;
            $baseURI .= '#';
			$propertyElement->base_uri( $baseURI );
		}

		$self->propertyElt($propertyElement);
	}
}


# 7.2.14 Production propertyElt
#
# propertyElt = 
#   resourcePropertyElt | 
#   literalPropertyElt | 
#   parseTypeLiteralPropertyElt |
#   parseTypeResourcePropertyElt |
#   parseTypeCollectionPropertyElt |
#   parseTypeOtherPropertyElt |
#   emptyPropertyElt
#
sub propertyElt {
	my ($self, $e) = @_;

	# If element e has e.URI = rdf:li then apply the list expansion rules on 
	# element e.parent in section 7.4 to give a new URI u and e.URI := u.
	if ( $e->uri() eq rdf->uri('li') ) {
		$e->parent()->{'liCounter'} ||= 1;
		$e->uri( rdf->uri($e->parent()->{'liCounter'}) );
		$e->parent()->{'liCounter'}++;
	}
	
	throw XML::SAX::Exception::Parse(Message=> 'URI ' . $e->uri() . ' is forbidden in propertyElement names')
		if($self->is_forbidden_property($e->uri()));
	
	# Throws an XML::SAX::Exception
	$self->validate_PropertyElt_attributes($e->attributes());

	# TODO: Add warnings for things like rdf:foo
	if (( scalar(@{ $e->children() }) == 1 ) && ( !exists($e->attributes()->{ rdf->uri('parseType') } )) ) {
		$self->resourcePropertyElt($e);
	}
	elsif ( ( scalar(@{ $e->children() }) == 0 ) && defined($e->text()) ) {
		$self->literalPropertyElt($e);
	}
	elsif ( my $ptype = $e->attributes()->{ rdf->uri('parseType') } ) {
		if ( $ptype eq 'Resource' ) {
			$self->parseTypeResourcePropertyElt($e);
		}
		elsif ( $ptype eq 'Collection' ) {	
			$self->parseTypeCollectionPropertyElt($e);
		}
		else {
			# parseType="Literal" parseType="Other items that are not Collection or Resource"			
			$self->parseTypeLiteralPropertyElt($e);
		}
	}
	elsif ( ! defined($e->text()) ) {
		$self->emptyPropertyElt($e);
	}
	else {
		# TODO: XML Exception?	
	}
}

# 7.2.15 Production resourcePropertyElt
#
# resourcePropertyElt = 
#   element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                 rdf:resource | rdf:nodeID | rdf:datatype |
#                 rdf:Description | rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID |
#                 xml:* ) {
#       idAttr?, xmllang?, xmlbase?, nodeElement
#   }
#
sub resourcePropertyElt {
	my ($self, $e) = @_;

	my $n = $e->children()->[0];
	
	# For element e, and the single contained nodeElement n, first n must be processed 
	# using production nodeElement:
	$self->nodeElement($n);

	my $p = ODO::Node::Resource->new( $e->uri() );
	
	# Then the following statement is added to the graph:
	$self->add_statement( $e->parent()->subject(), $p, $n->subject() )
		if ( $e->parent() );

	# If the rdf:ID attribute a is given, the above statement is reified with:
	if ( $e->attributes->{ rdf->uri('ID') } ) {
		my $baseURI = ($e->base_uri() || $self->base_uri() || '');
		
		my $i = ODO::Node::Resource->new( $baseURI . '#' . $e->attributes()->{ rdf->uri('ID') } );
		
		$self->reify_statement($i, $e->parent()->subject(), $p, $n->subject());
	}
}


# 7.2.16 Production literalPropertyElt
#
# literalPropertyElt =
#   element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                 rdf:resource | rdf:nodeID | rdf:datatype |
#                 rdf:Description | rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID |
#                 xml:* ) {
#       (idAttr | datatypeAttr )?, xmllang?, xmlbase?, text 
#   }
#
sub literalPropertyElt {
	my ($self, $e) = @_;
	
	# These are used in the reificatio so becareful with $p and $o
	my $p = ODO::Node::Resource->new();
	$p->uri($e->uri());
	
	my $o = ODO::Node::Literal->new();
	$o->value( $e->text() );
	$o->language( $e->language() );
	$o->datatype( $e->attributes()->{ rdf->uri('datatype') } );

	# For element e, and the text event t. The Unicode string t.string-value SHOULD be in Normal Form C[NFC]. 
	# If the rdf:datatype attribute d is given then o := typed-literal(literal-value := t.string-value, 
	# literal-datatype := d.string-value) otherwise o := literal(literal-value := t.string-value,
	# literal-language := e.language) and the following statement is added to the graph:
	if(!$e->parent()){
		throw XML::SAX::Exception::Parse(Message=> 'Missing parent element');	
	}
	
	$self->add_statement( $e->parent()->subject(), $p, $o);

	# If the rdf:ID attribute a is given, the above statement is reified with:
	if ( $e->attributes()->{ rdf->uri('ID') } ) {
		my $baseURI = ($e->base_uri() || $self->base_uri() || '');
		
		my $i = ODO::Node::Resource->new( $baseURI . '#' . $e->attributes()->{ rdf->uri('ID') } );
				
		$self->reify_statement($i, $e->parent()->subject(), $p, $o);
	}
}


# 7.2.17 Production parseTypeLiteralPropertyElt
#
# parseTypeLiteralPropertyElt = 
#   element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                 rdf:resource | rdf:nodeID | rdf:datatype |
#                 rdf:Description | rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID |
#                 xml:* ) {
#       idAttr?, parseLiteral, xmllang?, xmlbase?, literal 
#   }
#
sub parseTypeLiteralPropertyElt {
	my ($self, $e) = @_;
	
	# These are used below in the reification so don't modify $p or $o unless necesssary!
	my $p = ODO::Node::Resource->new( $e->uri() );
	
	my $o = ODO::Node::Literal->new();
	$o->value( $e->xtext()->[1] );
	$o->language( $e->language() );
	$o->datatype( rdf->uri('XMLLiteral'));
	
	# Then o := typed-literal(literal-value := x, 
	# literal-datatype := http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral ) and the 
	# following statement is added to the graph:
	$self->add_statement( $e->parent()->subject(), $p, $o );
	
	# If the rdf:ID attribute a is given, the above statement is reified with:
	if ( $e->attributes()->{ rdf->uri('ID') } ) {
		my $baseURI = ($e->base_uri() || $self->base_uri() || '');

		my $i = ODO::Node::Resource->new( $baseURI .  '#' . $e->attributes()->{ rdf->uri('ID') } );

		$e->subject($i);
		
		$self->reify_statement($i, $e->parent()->subject(), $p, $o);
	}
}


# 7.2.18 Production parseTypeResourcePropertyElt
#
# parseTypeResourcePropertyElt = 
#   element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                 rdf:resource | rdf:nodeID | rdf:datatype |
#                 rdf:Description | rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID |
#                 xml:* ) {
#       idAttr?, parseResource, xmllang?, xmlbase?, propertyEltList
#   }
#
sub parseTypeResourcePropertyElt {
	my ($self, $e) = @_;
	
	# For element e with possibly empty element content c:
	my $p = ODO::Node::Resource->new( $e->uri() );

	my $o = ODO::Node::Resource->new( $self->blank_node() );
	
	# Add the following statement to the graph:
	$self->add_statement( $e->parent()->subject(), $p, $o);
		
	# If the rdf:ID attribute a is given, the statement above is reified with:
	if ( $e->attributes()->{ rdf->uri('ID') } ) {
		my $baseURI = ($e->base_uri() || $self->base_uri() || '');

		my $i = ODO::Node::Resource->new( $baseURI . '#' . $e->attributes()->{ rdf->uri('ID') } );

		$e->subject($i);
		
		$self->reify_statement($i, $e->parent()->subject(), $p, $o);
	}

	# If the element content c is not empty, then use event n to create a new sequence of events as follows:
	my $c = ODO::Parser::XML::Fragment->new(
		{
			namespace=> rdf->uri(), 
			prefix=> 'rdf', 
			name=> 'Description', 
			parent=> $e->parent(), 
			attributes=> $e->attributes(),
			base_uri=> $e->base_uri()
		}
	);
	
	$c->subject($o);
	
	my $children = [];
	
	foreach (@{ $e->children() } ) {
		
		$_->parent($c);
		push @{ $children }, $_;
	}

	$c->children( $children );

	# Then process the resulting sequence using production nodeElement:
	$self->nodeElement($c);
}


# 7.2.19 Production parseTypeCollectionPropertyElt
#
# parseTypeCollectionPropertyElt = 
#   element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                 rdf:resource | rdf:nodeID | rdf:datatype |
#                 rdf:Description | rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID |
#                 xml:* ) {
#       idAttr?, xmllang?, xmlbase?, parseCollection, nodeElementList
#   }
#
sub parseTypeCollectionPropertyElt {
	my ($self, $e) = @_;
		
	my @s;

	foreach (@{ $e->children() }) {
		$self->nodeElement($_);
		
		# Generate blank nodes for all of the children
		my $b = ODO::Node::Blank->new( $self->blank_node() );
		
		push @s, $b;
	}
	
	my $p = ODO::Node::Resource->new( $e->uri() );
	
	my $reifyObject;
	
	# If s is not empty, n is the first event identifier in s and the following statement 
	# is added to the graph:
	if ( scalar(@s) > 0 ) {
		$self->add_statement($e->parent()->subject(), $p, $s[0]);

		# Used in the reification for later
		$reifyObject = $s[0];

		foreach my $n (@s) {
			$self->add_statement($n, ${ODO::Parser::RDF_TYPE}, ${ODO::Parser::RDF_LIST});
		}
		
		# For each event n in s and the corresponding element event f in l, the following statement 
		# is added to the graph:
		for ( 0 .. scalar(@s) - 1 ) {
			$self->add_statement($s[$_], ${ODO::Parser::RDF_FIRST}, $e->children()->[$_]->subject());
		}
		
		# For each consecutive and overlapping pair of events (n, o) in s, the following statement 
		# is added to the graph:
		for ( 0 .. ( scalar(@s) - 2 ) ) {
			$self->add_statement($s[$_], ${ODO::Parser::RDF_REST}, $s[ $_ + 1 ] );
		}

		# If s is not empty, n is the last event identifier in s, the following statement 
		# is added to the graph:
		$self->add_statement($s[-1], ${ODO::Parser::RDF_REST}, ${ODO::Parser::RDF_NIL});
	}
	else {	
		# otherwise the following statement is added to the graph:
		$self->add_statement( $e->parent()->subject(), $p, ${ODO::Parser::RDF_NIL});

		# Reification for later on				
		$reifyObject = ${ODO::Parser::RDF_NIL};
	}
	
	# If the rdf:ID attribute a is given, either of the the above statements is reified with:
	if(exists($e->attributes()->{ rdf->uri('ID') })) {
		my $baseURI = ($e->base_uri() || $self->base_uri() || '');

		my $i = ODO::Node::Resource->new( $baseURI . '#' . $e->attributes()->{ rdf->uri('ID') } );
		
		$e->subject($i);
		
		$self->reify_statement($i, $e->parent()->subject(), $p, $reifyObject);
	}
}


# 7.2.21 Production emptyPropertyElt
#
# emptyPropertyElt =
#    element * - ( local:* | rdf:RDF | rdf:ID | rdf:about | rdf:parseType |
#                  rdf:resource | rdf:nodeID | rdf:datatype |
#                  rdf:Description | rdf:aboutEach | rdf:aboutEachPrefix | rdf:bagID |
#                  xml:* ) {
#        idAttr?, (resourceAttr | nodeIdAttr)?, xmllang?, xmlbase?, propertyAttr*
#    }
#
sub emptyPropertyElt {
	my ($self, $e) = @_;

	my $baseURI = ($e->base_uri() || $self->base_uri());
	my $resource;
	
	# This is used in all code paths and potentially 2 simultaneously
	my $elementURI = ODO::Node::Resource->new( $e->uri() );
	
	# If there are no attributes or only the optional rdf:ID attribute i then
	# o := literal(literal-value:="", literal-language := e.language) and 
	# the following statement is added to the graph:
	if (exists($e->attributes()->{ rdf->uri('ID') }) && values( %{ $e->attributes() }) == 1 ) {
		throw XML::SAX::Exception::Parse(Message=> 'The value of rdf:ID must match the XML Name production, (as modified by XML Namespaces).')
			if(!$e->attributes()->{ rdf->uri('ID') } =~ m/$XML::RegExp::NCName/);

		$resource = ODO::Node::Literal->new();
		$resource->value('');
		$resource->language( $e->language() );

		$self->add_statement($e->parent()->subject(), $elementURI, $resource);
	}
	else {
		# Otherwise:
		#    * If rdf:resource attribute i is present,
		#	then r := uri(identifier := resolve(e, i.string-value))
		#    * If rdf:nodeID attribute i is present, then r := bnodeid(identifier := i.string-value)
		#    * If neither, r := bnodeid(identifier := generated-blank-node-id())
		if ( $e->attributes()->{ rdf->uri('resource') } ) {
			$resource = ODO::Node::Resource->new();
			
			my $uri;

			$uri = ($baseURI) ? 
						URI->new_abs($e->attributes()->{ rdf->uri('resource') }, $baseURI) :
					    URI->new($e->attributes()->{ rdf->uri('resource') });

			$resource->uri( $uri->as_string() );

			throw XML::SAX::Exception::Parse(Message=> 'Error creating URI object')
				unless($resource->uri());
		}
		elsif ( $e->attributes()->{ rdf->uri('nodeID') } ) {
			throw XML::SAX::Exception::Parse(Message=> 'The value of rdf:nodeID must match the XML Name production, (as modified by XML Namespaces).')
				if(!$e->attributes->{ rdf->uri('nodeID') } =~ m/$XML::RegExp::NCName/);
			
			$resource = ODO::Node::Blank->new();			
			$resource->uri($self->blank_node( $e->attributes()->{ rdf->uri('nodeID') } ));
		}
		else {
			$resource = ODO::Node::Blank->new();			
			$resource->uri($self->blank_node());
		}

		# The following are done in any order:
		#  For all propertyAttr attributes a (in any order)
		foreach my $attr (keys(%{ $e->attributes() })) {
			# Skip RDF reserved URIs
			next 
				if($self->is_reserved_uri($attr));

			# If a.URI == rdf:type  then u:=uri(identifier:=resolve(a.string-value)) 
			# and the following statement is added to the graph:
			if ( $attr eq rdf->uri('type') ) {
				my $uri;
				
				$uri = ($baseURI) ? 
							URI->new_abs($e->attributes()->{ $attr }, $baseURI) :
						    URI->new($e->attributes()->{ $attr });				

				my $o = ODO::Node::Resource->new($uri->as_string());
				
				throw XML::SAX::Exception::Parse(Message=> 'Error creating URI object')
					unless($o->uri());
				
				$self->add_statement($resource, ${ODO::Parser::RDF_TYPE}, $o);
			}
			else {
				# Otherwise Unicode string a.string-value  SHOULD be in Normal Form C[NFC], 
				# o := literal(literal-value := a.string-value, literal-language := e.language) 
				# and the following statement is added to the graph:				
				my $p = ODO::Node::Resource->new($attr);
				
				my $o = ODO::Node::Literal->new();
				$o->value($e->attributes()->{ $attr });
				$o->language( $e->language() );

				$self->add_statement($resource, $p, $o);
			}
		}

		# Add the following statement to the graph:
		$self->add_statement($e->parent()->subject(), $elementURI, $resource);
	}

	# ... and then if i is given, the above statement is reified 
	# with uri(identifier := resolve(e, concat("#", i.string-value))) 
	# using the reification rules in section 7.3.
	if ( $e->attributes()->{ rdf->uri('ID') } ) {
		my $i = ODO::Node::Resource->new( ($baseURI || '') . '#' . $e->attributes()->{ rdf->uri('ID') } );
		$self->reify_statement($i, $e->parent()->subject(), $elementURI, $resource);
	}
}

1;

__END__
