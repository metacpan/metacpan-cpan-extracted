# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *	version 0.1 - 2000/11/03 at 04:30 CEST
# *	version 0.2
# * 		- fixed bug in parsefile() to read URL-less filenames
# *		  (version0.1 was working only with 'file:' URL prefix)
# *		- fixed a lot of bugs/inconsistences in new(), parse(), setSource(), parsestring()
# *		  processXML() in the fetchSchema part, normalizeResourceIdentifier()
# *		- added parse_start a la XML::parser for no-blocking stream
# *		  parsing using XML::Parser::ExpatNB
# *		- pod documentation updated
# *             - does not use URI::file anymore
# *		- Modified createResource(), RDFStore::Parser::SiRPAC::Element and 
# *		  RDFStore::Parser::SiRPAC::DataElement accordingly to rdf-api-2000-10-30 
# *		- General bug fixing accordingly to rdf-api-2000-10-30
# *		  NOTE: Expat supports well XML Namespaces and SiRPAC could use all the
# *		  XML::Parser Namespace methods (e.g. generate_namespace()) to generate the
# *		  corresponding Qname; it uses arrays and simple operations instead for efficency
# *	version 0.3
# *		- fixed bug in expandAttributes() when expand rdf:value
# *		- Modified addOrder() expandAttributes() accordingly to rdf-api-2000-11-13
# *		- fixed bug in parse() parse_start() to set the Source right
# *		- fixed bug in RDFXML_StartElementHandler() when parseLiteral process attributes also
# *		- fixed bug in processTypedNode() to manage new attlist way
# *		- fixed bug in processPredicate() to manage new attlist way
# *		- fixed bugs due to the modifications due rdf-api-2000-10-30. Now $n->{tag} is either
# *		  $n->name() or $n->localName(); code got more clear also
# *		- fixed addTriple() and reify() - more checking and modified to manage right $subject
# *     version 0.31
# *             - updated documentation
# *		- fixed bug in parse_start() and parse() to check $file_or_uri
# *		  is a reference to an URI object
# *		- changed wget() Socket handle to work with previous Perl versions (not my $handle) and
# *		  do HTTP GET even on HTTP 'Location' redirect header
# *		- fixed bug in RDFXML_CharacterDataHand() when trim text and $preserveWhiteSpace
# *		- fixed bug in processTypedNode() when remove attributes
# *		- commented off croak in expandAttributes() when 'expanding predicate element' for 
# *		  production http://www.w3.org/TR/REC-rdf-syntax/#typedNode for xhtml2rdf stuff
# *     version 0.4
# *		- changed way to return undef in subroutines
# *		- now creation of Bag instances for each Description block is an option
# *		- fixed a few warnings
# *		- fixed bug in getAttributeValue() when check attribute name
# *		- fixed bug in setSource() when add trailing '#' char
# *		- added bug fixing in RDFXML_StartElementHandler(), newReificationID() and processPredicate() by rob@eorbit.net
# *		- fixed warnings in getAttributeValue(), RDFXML_StartElementHandler()
# *		- added GenidNumber parameter
# *		- updated accordingly to http://www.w3.org/RDF/Implementations/SiRPAC/
# *		- bug fix in reify() when generate the subject property triple
# *		- added getReificationCounter()
# *     version 0.41
# *		- fixed bug with XML::Parser 2.30 using expat-1.95.1
# *		     * XMLSCHEMA set to http://www.w3.org/XML/1998/namespace (see http://www.w3.org/TR/1999/REC-xml-names-19990114/#ns-using)
# *		     * added XMLSCHEMA_prefix
# *		- changed RDF_SCHEMA_NS to http://www.w3.org/2000/01/rdf-schema#
# *     version 0.42
# *		- updated accordingly to RDF Core Working Group decisions (see
# *		  http://www.w3.org/2000/03/rdf-tracking/#attention-developers)
# *			* rdf-ns-prefix-confusion (carp if error)
# *			* rdfms-abouteachprefix (removed aboutEachPrefix)
# *			* rdfms-empty-property-elements (updated  processDescription() and processPredicate())
# *			* rdf-containers-formalmodel (updated processListItem())
# *		- added RDFCore_Issues option
# *		- fixed bug when calling setSource() internally
# *		- updated normalizeResourceIdentifier()
# *		- fixed bug in processListItem() when calling processContainer()
# *		- fixed bug in processPredicate() for empty predicate elements having zero attributes
# *     version 0.43
# *		- fixed bug in processDescription()
# *		- fixed bug in processTypedNode() when removeAttribute
# *		- fixed bug in normalizeResourceIdentifier() when LocalName contains '#'
# *		- removed xml:space handling in RDFXML_CharacterDataHandler()
# *		- fixed bug in processPredicate() - does not generate triples when PCDATA is pure whitespaces stuff and there are XML subelements
# *		- fixed bug in processListItem() when generate rdf:li elements
# *		- added rdfcroak() instead of using $expat->xpcroak()
# *		- updated newReificationID()
# *		- added RDFMS_nodeID and RDFMS_datatype
# *		- updated reify()
# *		- added rdf:nodeID support
# *		- added rdf:parseType="Collection" support to processPredicate()
# *		- fixed bug in processPredicate() to force resource object nodes for rdf:type on predicate with rdf:resource
# *		- removed parse_start() method and added parsestream() to do expat no-blocking parseing of large XML streams
# *		- removed processListItem() - new specs require to process containers as nomral predicates and simply enumerating elements
# *		- fixed bug in processContainer() to treat RDF containers just like any other typed node but with rdf:li or rdf:_n nodes
# *		- added xml:base support
# *		- added xml:lang support
# *		- added manage_bNodes callback/hanlder
# *		- updated bNode identifier generation algorithm - now parser run wide unique - see newReificationID()
# *		- various fixes when using getAttributeValue()
# *		- updated rdfcroak() to return source name too when failing
# *		- updated processXML() - removed the fetchSchema part
# *		- force source to STDIN: if not defined
# *		- removed RDFCore_Issues option - now default
# *		- added rdfwarn()
# *		- added warnings()
# *		- moved common code to RDFStore::Parser
# *		- added rdf:datatype support
# *		- added rdfstore:context support
# *     version 0.44
# *		- updated wget() method invocation
# *		- force rdf:parseType="Literal" if rdf:dataType="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
# *		- fixed bug in processDescription() when expanding rdf:nodeID on predicate with inline typed node
# *

package RDFStore::Parser::SiRPAC;
{
	use vars qw($VERSION %Built_In_Styles $RDF_SYNTAX_NS $RDF_SCHEMA_NS $RDFX_NS $XMLSCHEMA_prefix $XMLSCHEMA $XML_space $XML_lang $XMLNS $RDFMS_parseType $RDFMS_type $RDFMS_about $RDFMS_bagID $RDFMS_resource $RDFMS_aboutEach $RDFMS_ID $RDFMS_RDF $RDFMS_Description $RDFMS_Seq $RDFMS_Alt $RDFMS_Bag $RDFMS_predicate $RDFMS_subject $RDFMS_object $RDFMS_Statement $RDFMS_nodeID $RDFMS_datatype $RDFMS_first $RDFMS_rest $RDFMS_nil $RDFSTORESCHEMA $RDFSTORESCHEMA_prefix $RDFSTORE_context $RDFSTORE_contextnodeID $RDFSTORE_EmptyContext );
	use strict;
	use Carp qw(carp croak cluck confess);
	use URI;
	use URI::Escape;

	use RDFStore::Parser;
        @RDFStore::Parser::SiRPAC::ISA = qw( RDFStore::Parser );

BEGIN
{
	require XML::Parser::Expat;
    	$VERSION = '0.44';
    	croak "XML::Parser::Expat.pm version 2 or higher is needed"
		unless $XML::Parser::Expat::VERSION =~ /^2\./;
}

$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
$RDFStore::Parser::SiRPAC::RDF_SCHEMA_NS="http://www.w3.org/2000/01/rdf-schema#";
$RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix="xml";
$RDFStore::Parser::SiRPAC::XMLSCHEMA="http://www.w3.org/XML/1998/namespace";
$RDFStore::Parser::SiRPAC::XML_space=$RDFStore::Parser::SiRPAC::XMLSCHEMA."space";
$RDFStore::Parser::SiRPAC::XML_base=$RDFStore::Parser::SiRPAC::XMLSCHEMA."base";
$RDFStore::Parser::SiRPAC::XML_lang=$RDFStore::Parser::SiRPAC::XMLSCHEMA."lang";
$RDFStore::Parser::SiRPAC::XMLNS="xmlns";
$RDFStore::Parser::SiRPAC::RDFMS_parseType = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "parseType";
$RDFStore::Parser::SiRPAC::RDFMS_type = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "type";
$RDFStore::Parser::SiRPAC::RDFMS_about = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "about";
$RDFStore::Parser::SiRPAC::RDFMS_bagID = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "bagID";
$RDFStore::Parser::SiRPAC::RDFMS_resource = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "resource";
$RDFStore::Parser::SiRPAC::RDFMS_aboutEach = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "aboutEach";
$RDFStore::Parser::SiRPAC::RDFMS_ID = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "ID";
$RDFStore::Parser::SiRPAC::RDFMS_RDF = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "RDF";
$RDFStore::Parser::SiRPAC::RDFMS_Description = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Description";
$RDFStore::Parser::SiRPAC::RDFMS_Seq = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Seq";
$RDFStore::Parser::SiRPAC::RDFMS_Alt = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Alt";
$RDFStore::Parser::SiRPAC::RDFMS_Bag = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Bag";
$RDFStore::Parser::SiRPAC::RDFMS_predicate = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "predicate";
$RDFStore::Parser::SiRPAC::RDFMS_subject = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "subject";
$RDFStore::Parser::SiRPAC::RDFMS_object = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "object";
$RDFStore::Parser::SiRPAC::RDFMS_Statement = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Statement";
$RDFStore::Parser::SiRPAC::RDFMS_nodeID = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "nodeID";
$RDFStore::Parser::SiRPAC::RDFMS_datatype = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "datatype";
$RDFStore::Parser::SiRPAC::RDFMS_rest = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "rest";
$RDFStore::Parser::SiRPAC::RDFMS_first = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "first";
$RDFStore::Parser::SiRPAC::RDFMS_nil = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "nil";

#special RDFStore hacked properties fro contexts - see http://rdfstore.sourceforge.net/contexts/
$RDFStore::Parser::SiRPAC::RDFSTORESCHEMA_prefix="rdfstore";
$RDFStore::Parser::SiRPAC::RDFSTORESCHEMA="http://rdfstore.sourceforge.net/contexts/";
$RDFStore::Parser::SiRPAC::RDFSTORE_context=$RDFStore::Parser::SiRPAC::RDFSTORESCHEMA."context";
$RDFStore::Parser::SiRPAC::RDFSTORE_contextnodeID=$RDFStore::Parser::SiRPAC::RDFSTORESCHEMA."contextnodeID";
$RDFStore::Parser::SiRPAC::RDFSTORE_EmptyContext=$RDFStore::Parser::SiRPAC::RDFSTORESCHEMA."EmptyContext";

sub new {
	my ($pkg) = shift;

        my $self = $pkg->SUPER::new(@_);

        bless $self,$pkg;
	};

sub parse {
	my $class = shift;

	$class->SUPER::parse( @_ );

	my $arg  = shift;
	my $file_or_uri = shift;

	my @expat_options = ();
	my ($key, $val);
	while (($key, $val) = each %{$class}) {
		push(@expat_options, $key, $val) 
			unless exists $class->{Non_Expat_Options}->{$key};
      	}

	#Run Expat
	my @parser_parameters=(	@expat_options,
				@_,
				( Namespaces => 1 ) ); #RDF needs Namespaces option on :)

    	my $first;
	if(exists $class->{'ExpatNB_Stream_Parsing'}) {
		$first = new XML::Parser::ExpatNB(@parser_parameters);
		$first->{_State_} = 1;
	} else {
		$first = new XML::Parser::Expat(@parser_parameters);
		};

	$first->{SiRPAC} = {};

	$first->{warnings} = $class->{warnings};

	#keep me in that list :)
	$first->{SiRPAC}->{parser} = $class;

	#from libwww & SiRPAC
  	$first->{SiRPAC}->{elementStack} = [];
  	$first->{SiRPAC}->{root}='';
  	$first->{SiRPAC}->{EXPECT_Element}='';
  	$first->{SiRPAC}->{iReificationCounter}= ( ($class->{GenidNumber}) && (int($class->{GenidNumber})) ) ? $class->{GenidNumber} : 0;
	$class->{iReificationCounter} = \$first->{SiRPAC}->{iReificationCounter};
  	$first->{SiRPAC}->{'timestamp'}=time();
  	$first->{SiRPAC}->{'rand_seed'}=unpack("H*", rand());
	if(	(exists $class->{Source}) && 
			(defined $class->{Source}) &&
			( (!(ref($class->{Source}))) || (!($class->{Source}->isa("URI"))) )	) {
		if(-e $class->{Source}) {
			$class->{Source}=URI->new('file:'.$class->{Source});
		} else {
			$class->{Source}=URI->new($class->{Source});
		};
	} elsif(	(defined $file_or_uri) && (ref($file_or_uri)) &&
		($file_or_uri->isa("URI"))	) {
		$class->{Source}=$file_or_uri;
	} else {
		$class->{Source}='STDIN:';
		};

  	$first->{'sSource'}= $class->setSource( ( (ref($class->{Source})) && ($class->{Source}->isa("URI")) ) ?
							$class->{Source}->as_string :
							$class->{Source} );

	$first->base( $first->{'sSource'} );

	# The following two variables may be changed on the fly
	# to change the behaviour of the parser
	#
	# createBags method allows one to determine whether SiRPAC
	# produces Bag instances for each Description block.
	# The default setting is to generate them. - to be checked......
  	$first->{SiRPAC}->{bCreateBags}=( ($class->{bCreateBags}) && (int($class->{bCreateBags})) ) ? $class->{bCreateBags} : 0;

	# The following flag indicates whether the XML markup
	# should be stored into a string as a literal value for RDF
  	$first->{SiRPAC}->{parseElementStack} = [];
  	$first->{SiRPAC}->{parseTypeStack} = [];
  	$first->{SiRPAC}->{scanMode} = 'SKIPPING';
	$first->{SiRPAC}->{sLiteral} = '';
	croak "Missing NodeFactory"
		unless(	(defined $class->{NodeFactory}) && 
			($class->{NodeFactory}->isa("RDFStore::NodeFactory")) );
  	$first->{SiRPAC}->{nodeFactory} = $class->{NodeFactory};
	$first->{SiRPAC}->{bases} = {};
	$first->{SiRPAC}->{langs} = {};
	$first->{SiRPAC}->{'xml:lang'} = '';

	# stack up also special RDFStore contexts things - complete hack for the moment
	$first->{SiRPAC}->{'contexts'} = {};
	$first->{SiRPAC}->{'rdfstore:context'} = ''; #assuming some special namespace http://rdfstore.sourceforge.net/contexts/

    	my %handlers = %{$class->{Handlers}}
		if( (defined $class->{Handlers}) && (ref($class->{Handlers}) =~ /HASH/) );

    	my $init = delete $handlers{Init};
    	my $final = delete $handlers{Final};

    	$first->setHandlers(	Start => \&RDFXML_StartElementHandler,
				End => \&RDFXML_EndElementHandler,
				Char => \&RDFXML_CharacterDataHandler );

	#Trigger 'Init' event
    	&$init($first) 
		if defined($init);

	my $result;
	my @result=();

	my $ioref;
	if (	(exists $class->{'ExpatNB_Stream_Parsing'}) &&
		(defined $arg) ) {
    		if (ref($arg) and UNIVERSAL::isa($arg, 'IO::Handle')) {
      			$ioref = $arg;
    		} elsif (tied($arg)) {
      			my $c = ref($arg);
      			no strict 'refs';
      			$ioref = $arg if defined &{"${c}::TIEHANDLE"};
    		} else {
      			eval { $ioref = *{$arg}{IO}; };
      			undef $@;
    			};
  		};

	eval {
		if (	(exists $class->{'ExpatNB_Stream_Parsing'}) &&
			(defined($ioref)) ) {
			my $bytes=0;
        		while(<$ioref>) {
				s/\s+\<\?xml/\<\?xml/mig;
				$bytes+=length($_);
                		$first->parse_more($_);
        			};
			if($bytes==0) {
                        	die "Cannot parse RDF in $ioref: empty input (0 bytes read)";
                	} else {
        			$result = $first->parse_done();
                		};
		} else {
    			$result = $first->parse($arg);
			};
		};

	my $err = $@;
	if($err) {
		$first->release
			unless(	(exists $class->{'ExpatNB_Stream_Parsing'}) &&
				(defined($ioref)) );
		my $source = $first->{'sSource'};
		$err =~ s/ at line/ in $source at line/;
		croak $err;
		};

	$first->{parser_parameters} = \@parser_parameters;

	if ( (defined $result) and (defined $final) ) {
		#Trigger 'Final' event
    		if(wantarray) {
      			@result = &$final($first);
    		} else {
			$result = &$final($first);
    		};
	};
	$first->release
		unless(	(exists $class->{'ExpatNB_Stream_Parsing'}) &&
			(defined($ioref)) );

	return unless defined wantarray;
	return wantarray ? @result : $result;
};

sub warnings {
	return @{ $_[0]->{warnings} };
	};

sub getReificationCounter {
	return ${$_[0]->{iReificationCounter}};
	};

sub parsestream {
	my $class = shift;

	$class->SUPER::parsestream( @_ );

	my $arg = shift;
	my $namespace = shift;

	$class->{'ExpatNB_Stream_Parsing'} = 1;

	return $class->parse($arg,$namespace,@_);
	};

sub parsestring {
	my ($class) = shift;

	$class->SUPER::parsestring( @_ );

	return $class->parse(@_);
	};

sub parsefile {
	my $class = shift;

	$class->SUPER::parsefile( @_ );

	my $file = shift;

	if( (defined $file) && ($file ne '') ) {
		my $ret;
		my @ret=();
		my $file_uri;
		my $scheme;
		$scheme='file:'
			if( (-e $file) || (!($file =~ /^\w+:/)) );
                $file_uri= URI->new(((defined $scheme) ? $scheme : '' ).$file);
		if (	(defined $file_uri) && (defined $file_uri->scheme)	&&
			($file_uri->scheme ne 'file') ) {
  			my $content = $class->wget($file_uri);
			if(defined $content) {
				if (wantarray) { 	
					eval {
						@ret = $class->parsestring($content, $file_uri,@_);
    					};
				} else {
					eval {
						$ret = $class->parsestring($content, $file_uri,@_);
    					};
				};
    				my $err = $@;
    				croak $err 	
					if $err;
                        } else {
				croak "Cannot fetch '$file_uri'";
			};
    		} else {
			my $filename= $file_uri->file;

			# FIXME: it might be wrong in some cases
			local(*FILE);
			open(FILE, $filename) 
				or  croak "Couldn't open $filename:\n$!";
			binmode(FILE);
			if (wantarray) { 	
				eval {
					@ret = $class->parse(*FILE,$file_uri,@_);
    				};
			} else {
				eval {
					$ret = $class->parse(*FILE,$file_uri,@_);
    				};
			};
    			my $err = $@;
    			close(FILE);
    			croak $err 	
				if $err;
		};
		return unless defined wantarray;
		return wantarray ? @ret : $ret;
  	};
};

sub getAttributeValue {
	my ($expat,$attlist, $elName) = @_;

#print STDERR "getAttributeValue(@_): ".(caller)[2]."\n";

  	return
		if( (ref($attlist) =~ /ARRAY/) && (!@{$attlist}) );
	my $n;
	for($n=0; $n<=$#{$attlist}; $n+=2) {
    		my $attname;
		if(ref($attlist->[$n]) =~ /ARRAY/) {
    			#$attname = $attlist->[$n]->[0].$attlist->[$n]->[1];
    			$attname = $attlist->[$n]->[0];
    			$attname .= $attlist->[$n]->[1]
				if(defined $attlist->[$n]->[1]);
		} else {
			$attname = $attlist->[$n];
		};

    		return $attlist->[$n+1]
			if ($attname eq $elName);
  	};
  	return;
}

sub RDFXML_StartElementHandler {
	my $expat = shift;
	my $tag = shift;
	my @attlist = @_;

	my @rdf_attlist;

	my $xml_tag = $tag; # save it for later

	my $sNamespace = $expat->namespace($tag);

	my $parseLiteral = (($expat->{SiRPAC}->{scanMode} ne 'SKIPPING') && (parseLiteral($expat)));

	if(not(defined $sNamespace)) {			
		my ($prefix,$suffix) = split(':',$tag);
		if($prefix eq $RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix) {
			$sNamespace = $RDFStore::Parser::SiRPAC::XMLSCHEMA;
			$tag = $expat->generate_ns_name($suffix,$sNamespace);
		} else {
			if( (defined $prefix) && (defined $suffix) ) {
				die rdfcroak($expat,"Unresolved namespace prefix '$prefix' for '$suffix'");
			} else {
				unless($parseLiteral) {
					my $msg = rdfwarn($expat,"Using node element '$tag' without a namespace is forbidden.");
					push @{ $expat->{warnings} },$msg;
					warn $msg;
					return;
					};
				};
			};
        	};

	my $newElement;

	my $setScanModeElement = 0;
	if($expat->{SiRPAC}->{scanMode} eq 'SKIPPING') {
		if( $sNamespace.$tag eq $RDFStore::Parser::SiRPAC::RDFMS_RDF ) {
                        $expat->{SiRPAC}->{scanMode} = 'RDF';
                        $setScanModeElement = 1;
		} else { # allow rdf/xml documents to start with a nodeElement production in addition 
			 # to rdf:RDF - see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2003Oct/0071.html
                        $expat->{SiRPAC}->{scanMode} = 'TOP_DESCRIPTION';
                        $setScanModeElement = 1;
                	};
	} elsif($expat->{SiRPAC}->{scanMode} eq 'RDF') {
		$expat->{SiRPAC}->{scanMode} = 'DESCRIPTION';
		$setScanModeElement = 1;
		};

	my $xml_atts=0;
	my $rdf_atts=0;
	my $rdfstore_atts=0;
	if($expat->{SiRPAC}->{scanMode} ne 'SKIPPING') {
		my $n;
		for($n=0; $n<=$#attlist; $n+=2) {
    			my $attname = $attlist[$n];
			my $namespace = $expat->namespace($attname);

			# set/use xml:base
			if (	(defined $attlist[$n+1]) &&
				( $attlist[$n+1] ne '' ) &&
				( ( $RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix.':'.'base' eq $attname ) ||
				  ( $RDFStore::Parser::SiRPAC::XML_base eq $attname ) ||
				  (	( defined $namespace ) &&
					( $namespace eq $RDFStore::Parser::SiRPAC::XMLSCHEMA ) &&
					( $attname eq 'base' ) ) ) ) {
				$expat->{SiRPAC}->{bases}->{ join('', ( $expat->context, $xml_tag ) ) } = $expat->base;
				$expat->base( $attlist[$n+1] );
				$xml_atts++;

				next;
				};

			# set/use xml:lang
			# NOTE: we will need to check if xml:lang is really valid accordingly to that ISO standard ;)
			if (	(defined $attlist[$n+1]) &&
				( ( $RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix.':'.'lang' eq $attname ) ||
				  ( $RDFStore::Parser::SiRPAC::XML_lang eq $attname ) ||
				  (	( defined $namespace ) &&
					( $namespace eq $RDFStore::Parser::SiRPAC::XMLSCHEMA ) &&
					( $attname eq 'lang' ) ) ) ) {
				$expat->{SiRPAC}->{langs}->{ join('', ( $expat->context, $xml_tag ) ) } = $expat->{SiRPAC}->{'xml:lang'};
				$expat->{SiRPAC}->{'xml:lang'} = $attlist[$n+1];
				$xml_atts++;

				next;
				};

			# set/use/eat rdfstore:context attribute - see http://rdfstore.sourceforge.net/contexts/
			if (	(defined $attlist[$n+1]) &&
				( ( $RDFStore::Parser::SiRPAC::RDFSTORESCHEMA_prefix.':'.'context' eq $attname ) ||
				  ( $RDFStore::Parser::SiRPAC::RDFSTORE_context eq $attname ) ||
				  (	( defined $namespace ) &&
					( $namespace eq $RDFStore::Parser::SiRPAC::RDFSTORESCHEMA ) &&
					( $attname eq 'context' ) ) ) ) {
				$expat->{SiRPAC}->{'contexts'}->{ join('', ( $expat->context, $xml_tag ) ) } = $expat->{SiRPAC}->{'rdfstore:context'};
				#take it easy - simply bNode for the moment - not forced either anywhere else in the API anyway
				my $ctx;
				unless( $attlist[$n+1] eq $RDFStore::Parser::SiRPAC::RDFSTORE_EmptyContext ) { #or NULL context :)
					my $ctx_uri = normalizeResourceIdentifier($expat, $attlist[$n+1]);
					$ctx = $expat->{SiRPAC}->{nodeFactory}->createResource( $ctx_uri );
					};
				$expat->{SiRPAC}->{'rdfstore:context'} = $ctx;
				$rdfstore_atts++;

				# rdfstore:context attributes are passed through to croak if not used as property (but a bit special)
				# they are being "stopped/ignored" in when addTriple() anyway i.e. do not emit any semantics for this parser
				# NOTE: this is needed to allow other (3rd part) RDF/XML parsers to render such special props as normal ones
				};

			# set/use/eat rdfstore:contextnodeID attribute (then bNode context)
			if (	(defined $attlist[$n+1]) &&
				( ( $RDFStore::Parser::SiRPAC::RDFSTORESCHEMA_prefix.':'.'contextnodeID' eq $attname ) ||
				  ( $RDFStore::Parser::SiRPAC::RDFSTORE_contextnodeID eq $attname ) ||
				  (	( defined $namespace ) &&
					( $namespace eq $RDFStore::Parser::SiRPAC::RDFSTORESCHEMA ) &&
					( $attname eq 'contextnodeID' ) ) ) ) {
				$expat->{SiRPAC}->{'contexts'}->{ join('', ( $expat->context, $xml_tag ) ) } = $expat->{SiRPAC}->{'rdfstore:context'};
				#take it easy - simply bNode for the moment - not forced either anywhere else in the API anyway
				my $ctx = $expat->{SiRPAC}->{nodeFactory}->createAnonymousResource($attlist[$n+1])
					if(	(defined $attlist[$n+1]) &&
						($attlist[$n+1] ne '') &&
						($attlist[$n+1] !~ m/^\s+$/m) ); # we allow also empty things (NULL) :) rdfstore:contextnodeID=""
				$expat->{SiRPAC}->{'rdfstore:context'} = $ctx;
				$rdfstore_atts++;

				# rdfstore:context attributes are passed through to croak if not used as property (but a bit special)
				# they are being "stopped/ignored" in when addTriple() anyway i.e. do not emit any semantics for this parser
				# NOTE: this is needed to allow other (3rd part) RDF/XML parsers to render such special props as normal ones
				};

			# ingore any XML reserved attributes - correct?
			if (	( $attname =~ m/^xml/ ) ||
                        	(	( defined $namespace ) &&
                                	( $namespace eq $RDFStore::Parser::SiRPAC::XMLSCHEMA ) ) ) {
				next;
				};

			# set/use rdf:datatype
			# NOTE: we will need to check if rdf:datatype is also valid accordingly to XML-Schema data types
			if (	(defined $attlist[$n+1]) &&
				(	( defined $namespace ) &&
					( $namespace.$attname eq $RDFStore::Parser::SiRPAC::RDFMS_datatype ) ) ) {
				$expat->{SiRPAC}->{'rdf:datatype'} = normalizeResourceIdentifier($expat, $attlist[$n+1]);

				next;
				};
					
			unless(	(defined $namespace) &&
				($namespace ne '') ) { #default namespace
				my ($prefix,$suffix) = split(':',$attname);
				if( (defined $prefix) && (defined $suffix) ) {
					if($prefix eq $RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix) {
						$namespace = $RDFStore::Parser::SiRPAC::XMLSCHEMA;
						push @rdf_attlist, [$namespace,$suffix];
						push @rdf_attlist, $attlist[$n+1];
					} else {
						die rdfcroak($expat,"Unresolved namespace prefix '$prefix' for '$suffix'");
						};
				} else {
					if(	($attname eq 'resource') 	|| 
						($attname eq 'ID') 		|| 
						($attname eq 'about') 		|| 
						($attname eq 'aboutEach') 	|| 
						($attname eq 'bagID')		||
						($attname eq 'nodeID')		||
						($attname eq 'datatype')	||
						($attname eq 'parseType')	||
						($attname eq 'type') ) {

						my $msg = rdfwarn($expat,"Unqualified use of 'rdf:$attname' attribute has been deprecated - see http://www.w3.org/2000/03/rdf-tracking/#rdf-ns-prefix-confusion");
						push @{ $expat->{warnings} },$msg;
						warn $msg;

						#default to RDFMS
						$namespace = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS;
					} else {
						die rdfcroak($expat,"Using property attribute '$attname' without a namespace is forbidden.")
							unless($parseLiteral);
                                        	};
					push @rdf_attlist, [$namespace,$attname];
					push @rdf_attlist, $attlist[$n+1];
					};
			} else {
				push @rdf_attlist, [$namespace,$attname];
				push @rdf_attlist, $attlist[$n+1];
				};

			$rdf_atts++
				if(	($namespace eq $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS) &&
					($attname ne 'nodeID') ); # see http://www.w3.org/TR/2003/PR-rdf-syntax-grammar-20031215/#section-Syntax-parsetype-resource
  			};
		};

	# If we have parseType="Literal" set earlier, this element
        # needs some additional attributes to make it stand-alone
        # piece of XML
	if($parseLiteral) {
		#ignored for the moment
		$newElement =  RDFStore::Parser::SiRPAC::Element->new($sNamespace,$tag,\@rdf_attlist, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
	} else {
		#....and probably Expat has already something like this.....
		$newElement =  RDFStore::Parser::SiRPAC::Element->new($sNamespace,$tag,\@rdf_attlist, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
	};

	$expat->{SiRPAC}->{EXPECT_Element} = $newElement
		if($setScanModeElement);

	my $sLiteralValue;
	if($expat->{SiRPAC}->{scanMode} ne 'SKIPPING') {

		# goes through the attributes of newElement to see
	 	# 1. if there are symbolic references to other nodes in the data model.
		# in which case they must be stored for later resolving with
		# resolveLater method (fix aboutEach on streaming!!!)
		# 2. if there is an identity attribute, it is registered using
		# registerResource or registerID method. 
	
       		my $sResource;
       		$sResource = getAttributeValue($expat,$newElement->{attlist}, $RDFStore::Parser::SiRPAC::RDFMS_resource);
		if (defined $sResource) {
       	 		$newElement->{sResource} = normalizeResourceIdentifier($expat,$sResource);
		} else {
       			$sResource = getAttributeValue($expat,$newElement->{attlist}, $RDFStore::Parser::SiRPAC::RDFMS_nodeID);
			if (defined $sResource) {
       	 			$sResource = 'rdf:nodeID:'.$sResource;
       	 			$newElement->{sResource} = $sResource;
				};
			};

		my $sAboutEach = getAttributeValue($expat,$newElement->{attlist},
                                $RDFStore::Parser::SiRPAC::RDFMS_aboutEach);
                $newElement->{sAboutEach} = $sAboutEach
                        if(defined $sAboutEach);

        	my $sAbout = getAttributeValue($expat,$newElement->{attlist}, $RDFStore::Parser::SiRPAC::RDFMS_about);
		my $bnode=0;
        	if(defined $sAbout) {
        		$newElement->{sAbout} = normalizeResourceIdentifier($expat,$sAbout);
		} else {
        		$sAbout = getAttributeValue($expat,$newElement->{attlist}, $RDFStore::Parser::SiRPAC::RDFMS_nodeID);
			if ( defined $sAbout ) {
        			$sAbout = 'rdf:nodeID:'.$sAbout;
        			$newElement->{sAbout} = $sAbout;
				$bnode=1;
				};
        		};

        	my $sBagID = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_bagID);

        	if (defined $sBagID) {
        		$newElement->{sBagID} = normalizeResourceIdentifier($expat,$sBagID);
			$sBagID = $newElement->{sBagID};
        		};

        	my $sID = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_ID);
        	if (defined $sID) {
        		$newElement->{sID} = normalizeResourceIdentifier($expat,'#'.$sID);
			$sID = $newElement->{sID};
        		};
		if(defined $sAboutEach) {
			#any idea how to support it? caching and backrefs??
			die rdfcroak($expat,"aboutEach is not supported on stream parsing ");
			};

		if(	(defined $sID) && 
			(defined $sAbout) &&
			(! $bnode) ) {
			die rdfcroak($expat,"A description block cannot use both 'ID' and 'about' attributes - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#idAboutAttr\">[6.5]</a>");
			};

		# Check parseType
		$sLiteralValue = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_parseType);

		if(	(defined $sLiteralValue) &&
			($sLiteralValue eq 'Resource') &&
			( (scalar(@{$newElement->{attlist}})/2) > ($xml_atts+$rdfstore_atts+$rdf_atts+1) ) ) {
			die rdfcroak($expat,"Property attributes and the rdf:nodeID attribute are not permitted on a description using rdf:parseType='Resource'.");
			};

		if (	(defined $sLiteralValue) && 
			($sLiteralValue ne 'Resource') && 
			($sLiteralValue ne 'Collection') ) {
			# This is the management of the element where
                	# parseType="Literal" appears
                	#
                	# You should notice RDF V1.0 conforming implementations
                	# must treat other values than Literal, Resource and Collection as
                	# Literal. This is why the condition is !equals("Resource") and !equals("Collection")
			# see also parseLiteral() subroutine for this

			if(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) {
				my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
				push @{$e->{children}},$newElement;
			};
        		# Place the new element into the stack
			push @{$expat->{SiRPAC}->{elementStack}},$newElement;
			push @{$expat->{SiRPAC}->{parseElementStack}},$newElement;
			$expat->{SiRPAC}->{sLiteral} = '';

                	return;
		};
		if($parseLiteral) {
                	# This is the management of any element nested within
                	# a parseType="Literal" declaration

			#Trigger 'Start_XML_Literal' event
			my $start_literal = $expat->{SiRPAC}->{parser}->{Handlers}->{Start_XML_Literal}
				if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
			$expat->{SiRPAC}->{sLiteral} .= &$start_literal($expat,$xml_tag,@attlist)
				if(defined $start_literal);
			push @{$expat->{SiRPAC}->{elementStack}},$newElement;
			return;
        	};
        };

	# Update the containment hierarchy with the stack
	# Prevent hooking up of 1st level descriptions to the root element
	if (	(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) &&
		(!$setScanModeElement) ) {
		my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
		push @{$e->{children}},$newElement;
	};

        # Place the new element into the stack
	push @{$expat->{SiRPAC}->{elementStack}},$newElement;

	if ( (defined $sLiteralValue) && ($sLiteralValue eq 'Collection') ) {
		$newElement->{isCollection} = 1;
		$expat->{SiRPAC}->{sLiteral} = '';
	} elsif ( (defined $sLiteralValue) && ($sLiteralValue eq 'Resource') ) {
		push @{$expat->{SiRPAC}->{parseElementStack}},$newElement;
		$expat->{SiRPAC}->{sLiteral} = '';

                # Since parseType="Resource" implies the following
                # production must match Description, let's create
                # an additional Description node here in the document tree.
                my $desc = RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description,
								\@rdf_attlist, $expat->{SiRPAC}->{'xml:lang'}, 
								$expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});

		if(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) {
                	my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
                	push @{$e->{children}},$desc;
        	};
		push @{$expat->{SiRPAC}->{elementStack}},$desc;
	};
};

sub RDFXML_EndElementHandler {
	my $expat = shift;
	my $tag = shift;

	my $ccc = join('', $expat->context, $tag );

    	my $bParseLiteral = parseLiteral($expat);
    	$expat->{SiRPAC}->{root} = pop @{$expat->{SiRPAC}->{elementStack}};

	if($expat->{SiRPAC}->{scanMode} eq 'SKIPPING') {
		if ( exists $expat->{SiRPAC}->{bases}->{ $ccc } ) {
			$expat->base( $expat->{SiRPAC}->{bases}->{ $ccc } ); #get back the old base
			delete( $expat->{SiRPAC}->{bases}->{ $ccc } );
			};
		if ( exists $expat->{SiRPAC}->{langs}->{ $ccc } ) {
			$expat->{SiRPAC}->{'xml:lang'} = $expat->{SiRPAC}->{langs}->{ $ccc }; #get back the old lang
			delete( $expat->{SiRPAC}->{langs}->{ $ccc } );
			};
		if ( exists $expat->{SiRPAC}->{'contexts'}->{ $ccc } ) {
			$expat->{SiRPAC}->{'rdfstore:context'} = $expat->{SiRPAC}->{'contexts'}->{ $ccc }; #get back the old rdfstore:context
			delete( $expat->{SiRPAC}->{'contexts'}->{ $ccc } );
			};
		delete($expat->{SiRPAC}->{'rdf:datatype'});

		return;
		};

	if ($bParseLiteral) {
                my $pe = $expat->{SiRPAC}->{parseElementStack}->[$#{$expat->{SiRPAC}->{parseElementStack}}];
		if($pe != $expat->{SiRPAC}->{root}) {
			#Trigger 'Stop_XML_Literal' event
			my $stop_literal = $expat->{SiRPAC}->{parser}->{Handlers}->{Stop_XML_Literal}
				if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
			$expat->{SiRPAC}->{sLiteral} .= &$stop_literal($expat,$tag)
				if(defined $stop_literal);
		} else {
			# we would want resource because parseType="Literal" is text/xml (see RFC 2397)
			push @{$expat->{SiRPAC}->{root}->{children}},RDFStore::Parser::SiRPAC::DataElement->new($expat->{SiRPAC}->{sLiteral}, 1, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'},$expat->{SiRPAC}->{'rdfstore:context'});
                	pop @{$expat->{SiRPAC}->{parseElementStack}};
			};
	} elsif(parseResource($expat)) {
		# If we are doing parseType="Resource"
         	# we need to explore whether the next element in
         	# the stack is the closing element in which case
         	# we remove it as well (remember, there's an
         	# extra Description element to be removed)
		if(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) {
                	my $pe = $expat->{SiRPAC}->{parseElementStack}->[$#{$expat->{SiRPAC}->{parseElementStack}}];
                	my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
            		if ($pe == $e) {
                		$e = pop @{$expat->{SiRPAC}->{elementStack}};
                		pop @{$expat->{SiRPAC}->{parseElementStack}};
            		};
		};
	};

	if($expat->{SiRPAC}->{scanMode} eq 'RDF') {
		$expat->{SiRPAC}->{scanMode} = 'SKIPPING';

		if ( exists $expat->{SiRPAC}->{bases}->{ $ccc } ) {
			$expat->base( $expat->{SiRPAC}->{bases}->{ $ccc } ); #get back the old base
			delete( $expat->{SiRPAC}->{bases}->{ $ccc } );
			};
		if ( exists $expat->{SiRPAC}->{langs}->{ $ccc } ) {
			$expat->{SiRPAC}->{'xml:lang'} = $expat->{SiRPAC}->{langs}->{ $ccc }; #get back the old lang
			delete( $expat->{SiRPAC}->{langs}->{ $ccc } );
			};
		if ( exists $expat->{SiRPAC}->{'contexts'}->{ $ccc } ) {
                        $expat->{SiRPAC}->{'rdfstore:context'} = $expat->{SiRPAC}->{'contexts'}->{ $ccc }; #get back the old rdfstore:context
                        delete( $expat->{SiRPAC}->{'contexts'}->{ $ccc } );
                        };
		delete($expat->{SiRPAC}->{'rdf:datatype'});

		return;
		};

	# we are deep inside - I do not understand this by AR
	if($expat->{SiRPAC}->{EXPECT_Element} != $expat->{SiRPAC}->{root}) {
		if ( exists $expat->{SiRPAC}->{bases}->{ $ccc } ) {
			$expat->base( $expat->{SiRPAC}->{bases}->{ $ccc } ); #get back the old base
			delete( $expat->{SiRPAC}->{bases}->{ $ccc } );
			};
		if ( exists $expat->{SiRPAC}->{langs}->{ $ccc } ) {
			$expat->{SiRPAC}->{'xml:lang'} = $expat->{SiRPAC}->{langs}->{ $ccc }; #get back the old lang
			delete( $expat->{SiRPAC}->{langs}->{ $ccc } );
			};
		if ( exists $expat->{SiRPAC}->{'contexts'}->{ $ccc } ) {
                        $expat->{SiRPAC}->{'rdfstore:context'} = $expat->{SiRPAC}->{'contexts'}->{ $ccc }; #get back the old rdfstore:context
                        delete( $expat->{SiRPAC}->{'contexts'}->{ $ccc } );
                        };
		delete($expat->{SiRPAC}->{'rdf:datatype'});

		return;
		};

	if($expat->{SiRPAC}->{scanMode} eq 'TOP_DESCRIPTION') {
		processXML($expat,$expat->{SiRPAC}->{EXPECT_Element});
		$expat->{SiRPAC}->{scanMode} = 'SKIPPING';
	} elsif($expat->{SiRPAC}->{scanMode} eq 'DESCRIPTION') {
		processXML($expat,$expat->{SiRPAC}->{EXPECT_Element});
		$expat->{SiRPAC}->{scanMode} = 'RDF';
		};

	if ( exists $expat->{SiRPAC}->{bases}->{ $ccc } ) {
		$expat->base( $expat->{SiRPAC}->{bases}->{ $ccc } ); #get back the old base
		delete( $expat->{SiRPAC}->{bases}->{ $ccc } );
		};
	if ( exists $expat->{SiRPAC}->{langs}->{ $ccc } ) {
		$expat->{SiRPAC}->{'xml:lang'} = $expat->{SiRPAC}->{langs}->{ $ccc }; #get back the old lang
		delete( $expat->{SiRPAC}->{langs}->{ $ccc } );
		};
	if ( exists $expat->{SiRPAC}->{'contexts'}->{ $ccc } ) {
		$expat->{SiRPAC}->{'rdfstore:context'} = $expat->{SiRPAC}->{'contexts'}->{ $ccc }; #get back the old rdfstore:context
                delete( $expat->{SiRPAC}->{'contexts'}->{ $ccc } );
                };
	delete($expat->{SiRPAC}->{'rdf:datatype'});
	};

sub RDFXML_CharacterDataHandler {
	my $expat = shift;
	my $text = shift;
   
	if(parseLiteral($expat)) {
		#Trigger 'Char_Literal' event
		my $char_literal = $expat->{SiRPAC}->{parser}->{Handlers}->{Char_Literal}
			if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
		$expat->{SiRPAC}->{sLiteral} .= &$char_literal($expat,$text)
			if(defined $char_literal);

        	return;
    	};

     	# Place all characters as Data instance to the containment
     	# hierarchy with the help of the stack.
    	my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];

	# Determine whether the previous event was for
	# characters. If so, update the Data node contents.
	# A&amp;B would otherwise result in three
	# separate Data nodes in the parse tree
	my $bHasData = 0;
        my $dN;
        my $dataNode;
        foreach $dN (@{$e->{children}}) {
                if($dN->isa('RDFStore::Parser::SiRPAC::DataElement')) {
                        $bHasData = 1;
                        $dataNode=$dN;
                        last;
                };
        };

        if(!$bHasData) {
                push @{$e->{children}},RDFStore::Parser::SiRPAC::DataElement->new($text, 0, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'},$expat->{SiRPAC}->{'rdfstore:context'});
        } else {
                $dataNode->{sContent} .= $text;
                #not nice to see it here.....I know ;-)
                $dataNode->{tag} = "[DATA: " . $dataNode->{sContent} . "]";
        	};
	};

sub processXML {
	my ($expat,$ele) = @_;

	if($ele->name() eq $RDFStore::Parser::SiRPAC::RDFMS_RDF) {
		my $c;
		foreach $c (@{$ele->{children}}) {
			if($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
				processDescription($expat,$c,0,
					$expat->{SiRPAC}->{bCreateBags}, $expat->{SiRPAC}->{bCreateBags});
			} elsif( 	($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
					($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
					($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag)	)  {
				processContainer($expat,$c);
			#strange checking here....
			} elsif( 	(!($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
					(!($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_nodeID)) &&
					(length($c->name())>0) ) {
				processTypedNode($expat,$c);
			};
		};
	} elsif($ele->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
		processDescription($expat,$ele,0,
			$expat->{SiRPAC}->{bCreateBags}, $expat->{SiRPAC}->{bCreateBags});
	} else {
		processTypedNode($expat,$ele);
		};

	};

sub processDescription {
	my ($expat,$ele,$inPredicate,$reify,$createBag) = @_;

#print STDERR "processDescription($expat,".$ele->name.",$inPredicate,$reify,$createBag)",((caller)[2]),"\n";

	# Return immediately if the description has already been managed
	return $ele->{sID}
		if($ele->{bDone});

	my $iChildCount=1;
	my $bOnce=1;
	
	# Determine first all relevant values
	my ($sID,$sBagid,$sAbout,$sAboutEach) = (
									$ele->{sID},
									$ele->{sBagID},
									$ele->{sAbout},
									$ele->{sAboutEach} );
	my $target = (defined $ele->{vTargets}->[0]) ? $ele->{vTargets}->[0] : undef;

	my $targetIsContainer=0;
	my $sTargetAbout='';
	my $sTargetBagid='';
	my $sTargetID='';

	# Determine what the target of the Description reference is
	if (defined $target) {
      		my $sTargetAbout = $target->{sAbout};
      		my $sTargetID    = $target->{sID};
      		my $sTargetBagid = $target->{sBagID};

       		# Target is collection if
       		# 1. it is identified with bagID attribute
       		# 2. it is identified with ID attribute and is a collection
      		if ( ((defined $sTargetBagid) && ($sTargetBagid ne '')) && 
			((defined $sAbout) && ($sAbout ne '')) ) {
			# skip '#' sign??
        		$targetIsContainer = ($sAbout =~ /^.$sTargetBagid/);
      		} else {
        		if (	((defined $sTargetID) && ($sTargetID ne '')) &&
            			((defined $sAbout) && ($sAbout ne '')) &&
				($sAbout =~ /^.$sTargetID/) &&
				( 	($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) )	)  {
          			$targetIsContainer = 1;
        		};
      		};
    	};

	# Check if there are properties encoded using the abbreviated syntax
	expandAttributes($expat,$ele,$ele,0);

	# Manage the aboutEach attribute here
	if( ((defined $sAboutEach) && ($sAboutEach ne '')) && (defined $target) ) {
      		if( 	($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) ) {
			my $ele1;
			foreach $ele1 (@{$target->{children}}) {
          			if( 	($ele1->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
					( ($ele1->localName() =~ /li$/) || ($ele1->localName() =~ /_/) ) ) {
            				my $sResource = $ele1->{sResource};
             				# Manage <li resource="..." /> case
            				if((defined $sResource) && ($sResource ne '')) {
              					my $newDescription =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description, undef, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
						$newDescription->{sAbout} = $sResource;
					
						my $ele2;
						foreach $ele2 (@{$ele->{children}}) {
							if (defined $newDescription) {
                  						push @{$newDescription->{children}},$ele2;
                					};
              					};

                				processDescription($expat,$newDescription,0,0,0)
							if (defined $newDescription);
            				} else {
               					# Otherwise we have a structured value inside <li>
              					# loop through the children of <li>
              					# (can be only one)
						my $ele2;
						foreach $ele2 (@{$ele1->{children}}) {
                					# loop through the items in the
                					# description with aboutEach
                					# and add them to the target
              						my $newNode =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description, undef, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
							my $ele3;
							foreach $ele3 (@{$ele->{children}}) {
								if (defined $newNode) {
                  							push @{$newNode->{children}},$ele3;
								};
              						};
                					push @{$newNode->{vTargets}},$ele2;

               						processDescription($expat,$newNode,1,0,0);
       						};
       					};
				} elsif( 	(!($ele1->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) &&
						(!($ele1->name() eq $RDFStore::Parser::SiRPAC::RDFMS_nodeID)) &&
						(length($ele1->name())>0) ) {
              				my $newNode =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description, undef, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
					my $ele2;
					foreach $ele2 (@{$ele->{children}}) {
						if (defined $newNode) {
                  					push @{$newNode->{children}},$ele2;
						};
              				};
                			push @{$newNode->{vTargets}},$ele1;
                			processDescription($expat,$newNode,1,0,0);
          			};
        		};
		} elsif($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
                	processDescription($expat,$target,0,$reify,$createBag);
			my $ele1;
			foreach $ele1 (@{$target->{children}}) {
              			my $newNode =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description, undef, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
				my $ele2;
				foreach $ele2 (@{$ele->{children}}) {
					if (defined $newNode) {
                  				push @{$newNode->{children}},$ele2;
					};
              			};
                		push @{$newNode->{vTargets}},$ele1;
                		processDescription($expat,$newNode,1,0,0);
        		};
	 	};
      		return;
    	};

	# Enumerate through the children
	my $paCounter = 1;
	my $n;
	foreach $n (@{$ele->{children}}) {
		if(     (defined $n->name()) &&
                        ($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) ) {
                        die rdfcroak($expat,"Cannot nest a Description inside another Description");
                } elsif(        (defined $n->name()) &&
                                ($n->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
                                ( ($n->localName() =~ /li$/) || ($n->localName() =~ /_/) ) ) {
			my $id;
			if(	(defined $sID) &&
				($sID ne '') ) {
				$id = $sID;
			} elsif(	(defined $sAbout) &&
					($sAbout ne '') ) {
				$id = $sAbout;
			} else {
				my $nodeID = getAttributeValue($expat, $ele->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
                                if ( defined $nodeID ) {
                                	$ele->{sID} = 'rdf:nodeID:'.$nodeID;
                                } else {
                                        $ele->{sID} = newReificationID($expat)
                                        };
				$id = $ele->{sID};
				$sID = $id;
				};
			# added by AR 2003/10/05 accordingly to W3C RDF Core #rdf-containers-formalmodel issue
                        # (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jul/0039.html)
			my $isli = ($n->localName() =~ /li$/) ? 1 : 0;
                        if($n->localName() =~ m/_(\d+)$/) {
                                $n->{tag} = "_".$1;
                        } else {
                                $n->{tag} = "_".$paCounter;
                                };
                        processPredicate($expat,$n,$ele,$id,$reify);

                        $paCounter++
				if($isli);
                } elsif(        (defined $n->name()) &&
      				(!($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
      				(!($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_nodeID)) &&
				(length($n->name())>0) ) {
        		my $sChildID;
			if ( (defined $target) && ($targetIsContainer) ) {
          			$sChildID = processPredicate($expat,$n,$ele,
                                       ((defined $target->{sBagID}) ? $target->{sBagID} : $target->{sID}),0);
          			$ele->{sID} = normalizeResourceIdentifier($expat,$sChildID);
				$createBag=0;
        		} elsif(defined $target) {
          			$sChildID = processPredicate($expat,$n,$ele,
                                       ((defined $target->{sBagID}) ? $target->{sBagID} : $target->{sID}),$reify);
          			$ele->{sID} = normalizeResourceIdentifier($expat,$sChildID);
        		} elsif( (not(defined $target)) && (!($inPredicate)) ) {
				# added by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
				# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
				my $pl = getAttributeValue($expat, $n->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_parseType);
				die rdfcroak($expat,"Can not specify an rdf:parseType of 'Literal' and an rdf:resource attribute at the same time for predicate '".$n->name()."' - see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html")
					if(	(defined $pl) &&
						($pl eq 'Literal') &&
						( (getAttributeValue($expat, $n->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_resource)) ||
						  (getAttributeValue($expat, $n->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID)) ) );

				my $nodeID = getAttributeValue($expat, $ele->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
				if ( defined $nodeID ) {
          				if(not(((defined $ele->{sID}) && ($ele->{sID} ne '')))) {
          					$ele->{sID} = 'rdf:nodeID:'.$nodeID;	
						};
				} else {
					my $about = getAttributeValue($expat, $ele->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_about);
					if( $about =~ /^rdf:nodeID:/ ) {
						$ele->{sID} = $about;
					} else {
						$ele->{sID} = newReificationID($expat)
          						if(not(((defined $ele->{sID}) && ($ele->{sID} ne ''))));
						};
					};
          			if (not(((defined $sAbout) && ($sAbout ne '')))) {
            				if ((defined $sID) && ($sID ne '')) {
						$sAbout=$sID;
					} else {
						$sAbout=$ele->{sID};
					};
				};

          			$sChildID = processPredicate($expat,$n,$ele,
						$sAbout,
						( ((defined $sBagid) && ($sBagid ne '')) ? 1 : $reify));
        		} elsif( (not(defined $target)) && ($inPredicate) ) {
          			if (not(((defined $sAbout) && ($sAbout ne '')))) {
            				if ((defined $sID) && ($sID ne '')) {
          					$ele->{sID} = normalizeResourceIdentifier($expat,$sID);
						$sAbout=$sID;
					} else {
						my $nodeID = getAttributeValue($expat, $ele->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
                                		if ( defined $nodeID ) {
          						if(not(((defined $ele->{sID}) && ($ele->{sID} ne '')))) {
                                        			$ele->{sID} = 'rdf:nodeID:'.$nodeID;
								};
                                		} else {
          						$ele->{sID} = newReificationID($expat)
          							if(not(((defined $ele->{sID}) && ($ele->{sID} ne ''))));
							};
						$sAbout=$ele->{sID};
					};
				} else {
          				$ele->{sID} = $sAbout;
					};
					
          			$sChildID = processPredicate($expat,$n,$ele,$sAbout,0);
				};

                        # Each Description block creates also a Bag node which
                        # has links to all properties within the block IF
                        # the bCreateBags variable is true
        		if( ((defined $sBagid) && ($sBagid ne '')) || ($expat->{SiRPAC}->{bCreateBags} && $createBag) ) {
          			my $sNamespace = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS;
          			# do only once and only if there is a child
          			if( ($bOnce) && ((defined $sChildID) && ($sChildID ne '')) ) {
            				$bOnce = 0;
					my $nodeID = getAttributeValue($expat, $ele->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
                                	if ( defined $nodeID ) {
            					if(not(((defined $ele->{sBagID}) && ($ele->{sBagID} ne '')))) {
                                        		$ele->{sBagID} = 'rdf:nodeID:'.$nodeID;
							};
                                	} else {
              					$ele->{sBagID} = newReificationID($expat)
            						if(not(((defined $ele->{sBagID}) && ($ele->{sBagID} ne ''))));
						};
          				$ele->{sID} = normalizeResourceIdentifier($expat,$ele->{sBagID})
          					if(not(((defined $ele->{sID}) && ($ele->{sID} ne ''))));

			            	addTriple(	$expat,
							buildResource( $expat,$sNamespace,'type'),
                       					buildResource( $expat,$ele->{sBagID}),
							buildResource( $expat,$sNamespace,'Bag'),
							$ele->{'context'}
						);
          			};
				if ((defined $sChildID) && ($sChildID ne '')) {
			            	addTriple(	$expat,
							buildResource( $expat,$sNamespace,"_".$iChildCount),
                       					buildResource( $expat,$ele->{sBagID}),
							buildResource( $expat,$sChildID),
							$ele->{'context'}
						 );
            				$iChildCount++;
          			};
        		};
		};
    	};

	$ele->{bDone} = 1;

	return $ele->{sID};
	};

# we could use URI and XPath modules to validate and normalise the subject, predicate, object
# Use XPath/XPointer for literals could be cool to have one unique uri thing
sub addTriple {
	my ($expat,$predicate,$subject,$object, $context) = @_;

#print STDERR "addTriple('".
#                       (($predicate) ? $predicate->toString : '')."','".
#                       (($subject) ? $subject->toString : '')."','".
#                       (($object) ? $object->toString : '')."')",((caller)[2]),"\n";

        # If there is no subject (rdf:about="") or object (rdf:resource=""), then use the URI/filename where the RDF description came from
        carp "Predicate null when subject=".$subject->toString." and object=".$object->toString
                unless(defined $predicate);

        carp "Subject null when predicate=".$predicate->toString." and object=".$object->toString
                unless(defined $subject);

	carp "Object null when predicate=".$predicate->toString." and subject=".$subject->toString
        	unless(defined $object);

	$subject = buildResource( $expat,$expat->{'sSource'})
		unless(	(defined $subject) && 
			($subject->toString()) && 
			(length($subject->toString())>0) );

	if(	(defined $object) &&
		(ref($object)) && 
		($object->isa("RDFStore::Resource")) ) {
		$object = buildResource( $expat,$expat->{'sSource'})
			unless( (defined $object) &&
				($object->toString()) && 
				(length($object->toString())>0) );
		};

	# ignore rdfstore:context triples due they are used simply to set context/provenance info
	return
		if(	($predicate->toString eq $RDFStore::Parser::SiRPAC::RDFSTORE_context) ||
			($predicate->toString eq $RDFStore::Parser::SiRPAC::RDFSTORE_contextnodeID) );

	#Trigger 'Assert' event
        my $assert = $expat->{SiRPAC}->{parser}->{Handlers}->{Assert}
		if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
        if (defined($assert)) {
        	return &$assert($expat, 
				$expat->{SiRPAC}->{nodeFactory}->createStatement($subject,$predicate,$object, $context) ); #context too nowdays...
	} else {
		return;
		};
	};

sub newReificationID {
	my ($expat) = @_;

#print STDERR "newReificationID($expat): ",((caller)[2]),"\n";

	# try to generate system/run wide unique ID i.e. 'S' + unpack("H*", rand()) + 'P' + $$ + 'T' + time() + 'N' + GenidNumber
	return  'rdf:nodeID:genidrdfstore' .
		'S'.$expat->{SiRPAC}->{'rand_seed'} .
		'P'. $$. 
		'T'. $expat->{SiRPAC}->{'timestamp'} .
		'N'. $expat->{SiRPAC}->{iReificationCounter}++;
	};

sub processTypedNode {
	my ($expat,$typedNode) = @_;

#print STDERR "processTypedNode(".$typedNode->{tag}."): ",((caller)[2]),"\n";

	my $sID = $typedNode->{sID};
	my $sBagID = $typedNode->{sBagID};
	my $sAbout = $typedNode->{sAbout};

	my $target = (defined $typedNode->{vTargets}->[0]) ? $typedNode->{vTargets}->[0] : undef;

    	my $sAboutEach = $typedNode->{sAboutEach};

	if ( (defined $typedNode->{sResource}) && ($typedNode->{sResource} ne '') && ($typedNode->{sResource} !~ /^rdf:nodeID:/) ) {
      		die rdfcroak($expat,"'resource' attribute not allowed for a typedNode '".$typedNode->name()."' - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#typedNode\">[6.13]</a>");
		};

	# We are going to manage this typedNode using the processDescription
	# routine later on. Before that, place all properties encoded as
	# attributes to separate child nodes.
	my $n;
	for($n=0; $n<=$#{$typedNode->{attlist}}; $n+=2) {
    		my $sAttribute = $typedNode->{attlist}->[$n]->[0].$typedNode->{attlist}->[$n]->[1];
    		my $sValue = getAttributeValue($expat, $typedNode->{attlist},$sAttribute);
		if ( defined $sValue ) {
			$sValue =~ s/^([ ])+//g;
			$sValue =~ s/([ ])+$//g;
			};

		if ( 	(!($sAttribute =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/)) &&
			(!($sAttribute =~ m|^$RDFStore::Parser::SiRPAC::XMLSCHEMA|)) ) {
        		if(	(defined $sValue) &&
				(length($sValue) > 0) ) {
              			my $newPredicate =  RDFStore::Parser::SiRPAC::Element->new(
							$typedNode->{attlist}->[$n]->[0],
							$typedNode->{attlist}->[$n]->[1],[
							[undef,$RDFStore::Parser::SiRPAC::RDFMS_ID], 
							(	((defined $sAbout) && ($sAbout ne '')) ?  $sAbout : 
								(defined $sID) ?  ( $sID =~ /^#/ ) ? $sID : '#'.$sID :
								'' ),
							[undef,$RDFStore::Parser::SiRPAC::RDFMS_bagID],
							(defined $sBagID) ? ( $sBagID =~ /^#/ ) ? $sBagID : '#'.$sBagID : ''
								],
								$expat->{SiRPAC}->{'xml:lang'}, 
								$expat->{SiRPAC}->{'rdf:datatype'},
								$expat->{SiRPAC}->{'rdfstore:context'});
				
				my $newData =  RDFStore::Parser::SiRPAC::DataElement->new($sValue, 0, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
				push @{$newPredicate->{children}},$newData;
				push @{$typedNode->{children}},$newPredicate;

				# removeAttribute
				my @rr;
				my $i;
				for($i=0; $i<=$#{$typedNode->{attlist}}; $i+=2) {
					my $a = $typedNode->{attlist}->[$i]->[0].$typedNode->{attlist}->[$i]->[1];
					if($a eq $sAttribute) {
						next;
					} else {
						push @rr,($typedNode->{attlist}->[$i],$typedNode->{attlist}->[$i+1]);
						};
					};
				$typedNode->{attlist} = \@rr;
        			};
      			};
    	};

	my $sObject;
	my $nodeID;
    	if(defined $target) {
		$sObject = ( (((defined $target->{sBagID}) && ($target->{sBagID} ne ''))) ? $target->{sBagID} : $target->{sID});
	} elsif((defined $sAbout) && ($sAbout ne '')){ #this makes failing t/rdfcore-tests/xmlbase/test008.rdf and t/rdfcore-tests/xmlbase/test013.rdf
      		$sObject = $sAbout;
    	} elsif((defined $sID) && ($sID ne '')) {
      		$sObject = $sID;
    	} else {
		$nodeID = getAttributeValue($expat, $typedNode->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
                if ( defined $nodeID ) {
                	$sObject = 'rdf:nodeID:'.$nodeID;
		} else {
      			$sObject = newReificationID($expat);
			};
	};

	$typedNode->{sID} = normalizeResourceIdentifier($expat,$sObject);

	# special case: should the typedNode have aboutEach attribute,
	# the type predicate should distribute to pointed
	# collection also -> create a child node to the typedNode
	if ( 	((defined $sAboutEach) && ($sAboutEach ne '')) &&
        	(scalar(@{$typedNode->{vTargets}})>0) ) {
              		my $newPredicate =  RDFStore::Parser::SiRPAC::Element->new($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type', undef, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
			my $newData = RDFStore::Parser::SiRPAC::DataElement->new($typedNode->name(), 0, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
			push @{$newPredicate->{children}},$newData;
			push @{$typedNode->{children}},$newPredicate;
    	} else {
      		addTriple(	$expat,
				buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
				buildResource( $expat,$typedNode->{sID}),
				buildResource( $expat,$typedNode->namespace,$typedNode->localName),
				$typedNode->{'context'}
			);
    	};

    	my $sDesc = processDescription($expat,$typedNode, 0, $expat->{SiRPAC}->{bCreateBags}, 0);

    	return $sObject;
};

sub processContainer {
	my ($expat,$n) = @_;

#print STDERR "processContainer($n)",((caller)[2]),"\n";

	my $sID = $n->{sID};
      	$sID = $n->{sAbout}
    		unless((defined $sID) && ($sID ne ''));
	my $nodeID = getAttributeValue($expat, $n->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
	if( defined $nodeID ) {
        	$sID = 'rdf:nodeID:'.$nodeID
    			unless((defined $sID) && ($sID ne ''));
        } else {
      		$sID = newReificationID($expat)
    			unless((defined $sID) && ($sID ne ''));
		};

     	# Do the instantiation only once
	if(!($n->{bDone})) {
      		if($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) {
			addTriple(	$expat,
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
					buildResource( $expat,$sID),
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Seq'),
					$n->{'context'}
				);
      		} elsif($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) {
			addTriple(	$expat,
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
					buildResource( $expat,$sID),
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Alt'),
					$n->{'context'}
				);
      		} elsif($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) {
			addTriple(	$expat,
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
					buildResource( $expat,$sID),
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Bag'),
					$n->{'context'}
				);
      		};
		$n->{bDone} = 1;
    	};

	expandAttributes($expat,$n,$n,0);

	if( 	(scalar(@{$n->{children}})<=0) &&
      		($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ) {
      		die rdfcroak($expat,"An RDF:Alt container must have at least one nested listitem");
    	};

	my $iCounter = 1;
	my $n2;
	my $object_elements=1;
	foreach $n2 (@{$n->{children}}) {
		if (	(defined $n2) &&
			(defined $n2->name()) &&
			(defined $n2->localName()) &&
			($n2->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
			( ($n2->localName() =~ /li$/) || ($n2->localName() =~ /_/) ) ) {
			# added by AR 2003/10/05 accordingly to W3C RDF Core #rdf-containers-formalmodel issue
			# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jul/0039.html)
			my $isli = ($n2->localName() =~ /li$/) ? 1 : 0;
			if($n2->localName() =~ m/_(\d+)$/) {
				$n2->{tag} = "_".$1;
			} else {
				$n2->{tag} = "_".$iCounter;
				};
			processPredicate($expat,$n2,$n,$sID,0); #reify flag is not passed here

        		$iCounter++
				if($isli);

			$object_elements++;
		} elsif ($n2->isa('RDFStore::Parser::SiRPAC::DataElement')) {
                        # We've got some data; if whitespace is ok otherwise die rdfcroak()
                        my $sValue = $n2->{sContent};

                        # i.e.
                        #       <rdf:RDF>
                        #               <items>
                        #                       <rdf:Seq>
                        #               not valid
                        #                          literal<rdf:li rdf:resource="http://ddddd..s,ss."/>
                        #                       .....
                        #                       ...
                        #       </rdf:RDF>
                        #
                        # is rdfcroaking() while
                        #
                        #       <rdf:RDF>
                        #               <items>
                        #                       <rdf:Seq>  
                        #                  <rdf:li rdf:resource="http://ddddd..s,ss."/>
                        #                       .....
                        #                       ...
                        #       </rdf:RDF>
                        #
                        # is just normal XML/RDF Container :) bug fix by AR 2002/06/27
                        #
                        my $trimstring = $sValue;
                        $trimstring =~ s/^\s+//mg;
                        $trimstring =~ s/\s+$//mg;
                        if(     ($object_elements > 1) &&
                                (defined $trimstring) && 
                                (length($trimstring)>0) ) {
                                die rdfcroak($expat,"Expected whitespace found: ". $sValue);
                                return;   
                                };
      		} else {
			processPredicate($expat,$n2,$n,$sID,0); #reify flag is not passed here

			$object_elements++;
      			};
    		};
	return $sID;
};

sub buildResource {
	my ($expat, $ns, $ln) = @_;

	my $factory = $expat->{SiRPAC}->{nodeFactory};

	if ( !$ln and ( $ns =~ s/^rdf:nodeID:// ) ) {
		#Trigger 'manage_bNodes' event
        	my $manage_bnodes = $expat->{SiRPAC}->{parser}->{Handlers}->{manage_bNodes}
			if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
        	if (defined($manage_bnodes)) {
        		return &$manage_bnodes($expat, $factory, $ns);
		} else {
			return $factory->createAnonymousResource( $ns );
			};
	} else {
		return $factory->createResource( $ns, $ln );
		};
	};

sub buildLiteral {
	my ($factory) = shift;

	return $factory->createLiteral( @_ );
	};

sub rdfwarn {
	my ($expat, $message) = @_;

	my $source = $expat->{'sSource'};
	my $line = $expat->current_line;
	my $column = $expat->current_column;
	my $byte = $expat->current_byte;
	$message .= " in $source at line $line, column $column, byte $byte";

	return $message;
	};

sub rdfcroak {
	my ($expat, $message) = @_;

	my $source = $expat->{'sSource'};
	my $eclines = $expat->{ErrorContext};
	my $line = $expat->current_line;
	my $column = $expat->current_column;
	my $byte = $expat->current_byte;
	#$message .= " in $source at line $line, column $column, byte $byte";
	$message .= " at line $line, column $column, byte $byte"; # it seems the source file is already magically included by caller die() sub...
	$message .= ":\n" . $expat->position_in_context($eclines)
		if defined($eclines);

	return $message;
	};

# processPredicate handles all elements not defined as special
# RDF elements. <tt>predicate</tt> has either <tt>resource()</tt> or a single child
sub processPredicate {
	my ($expat,$predicate,$description,$sTarget,$reify) = @_;

#print STDERR "processPredicate($predicate->{tag},$description->{tag},$sTarget,$reify)",((caller)[2]),"\n";

	my $sStatementID = $predicate->{sID};
	my $sBagID       = $predicate->{sBagID};
    	my $sResource    = $predicate->{sResource};

     	# If a predicate has other attributes than rdf:ID, rdf:bagID,
     	# or xmlns... -> generate new triples according to the spec.
     	# (See end of Section 6)

	# this new element may not be needed
        my $d = RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description, undef, $expat->{SiRPAC}->{'xml:lang'}, $expat->{SiRPAC}->{'rdf:datatype'}, $expat->{SiRPAC}->{'rdfstore:context'});
    	if(expandAttributes($expat,$d,$predicate,1,$sResource)) {
      		# error checking
      		if(scalar(@{$predicate->{children}})>0) {
        		die rdfcroak($expat,$predicate->name()." must be an empty element since it uses propAttr grammar production - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#propertyElt\">[6.12]</a>");
        		return;
      		};

      		# determine the 'about' part for the new statements
      		if ((defined $sStatementID) && ($sStatementID ne '')) {
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_about];
        		push @{$d->{attlist}},$sStatementID;
      		} elsif ((defined $sResource) && ($sResource ne '')) {
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_about];
        		push @{$d->{attlist}},$sResource;
      		} else {
			my $nodeID = getAttributeValue($expat, $predicate->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID); # XXXXXXX to be checked
			if( defined $nodeID ) {
                        	$sStatementID = 'rdf:nodeID:'.$nodeID;
                        } else {
				$sStatementID = newReificationID($expat);
				};
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_nodeID]; # XXXXXXXX to be checked
        		push @{$d->{attlist}},$sStatementID;
      		};

		if ((defined $sBagID) && ($sBagID ne '')) {
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_bagID];
        		push @{$d->{attlist}},$sBagID;
        		$d->{sBagID} = $sBagID;
      		};

          	processDescription($expat,$d, 0,0,$expat->{SiRPAC}->{bCreateBags});
    	};
	# Tricky part: if the resource attribute is present for a predicate
	# AND there are no children, the value of the predicate is either
	# 1. the URI in the resource attribute OR
	# 2. the node ID of the resolved #resource attribute
	my $predicate_target = (defined $predicate->{vTargets}->[0]) ? $predicate->{vTargets}->[0] : undef;
    	if( ((defined $sResource) && ($sResource ne '')) && (scalar(@{$predicate->{children}})<=0) ) {
      		if (not(defined $predicate_target)) {
        		if (	($reify) ||
				(       (defined $predicate->{sID}) &&
                                	($predicate->{sID} ne '') ) ) {
          			$sStatementID = reify(	$expat,
							buildResource( $expat,$predicate->namespace,$predicate->localName),
							buildResource( $expat,$sTarget),
							buildResource( $expat,$sResource),
							$predicate->{sID},
							$predicate);
				$predicate->{sID} = normalizeResourceIdentifier($expat,$sStatementID);
        		} else {
				addTriple(	$expat,
                     				buildResource( $expat,$predicate->namespace,$predicate->localName),
                     				buildResource( $expat,$sTarget),
                     				buildResource( $expat,$sResource),
						$predicate->{'context'}
					 );
        		};
      		} else {
			if (    ($reify) ||
                                (       (defined $predicate->{sID}) &&
                                        ($predicate->{sID} ne '') ) ) {
          			$sStatementID = reify(	$expat, 
							buildResource( $expat,$predicate->namespace,$predicate->localName),
							buildResource( $expat,$sTarget),
							buildResource( $expat,$predicate_target->{sID}),
							$predicate->{sID},
							$predicate);
				$predicate->{sID} = normalizeResourceIdentifier($expat,$sStatementID);
        		} else {
          			addTriple( 	$expat,
                     				buildResource( $expat,$predicate->namespace,$predicate->localName),
                     				buildResource( $expat,$sTarget),
                     				buildResource( $expat,$predicate_target->{sID}),
						$predicate->{'context'}
					);
        		};
      		};
      		return $predicate->{sID};
    	};
                                    
	# Does this predicate make a reference somewhere using the <i>sResource</i> attribute
    	if ( ((defined $sResource) && ($sResource ne '')) && (defined $predicate_target) ) {
      		$sStatementID = processDescription ($expat,$predicate_target,1,0,0);
		if (    ($reify) ||
                        (       (defined $predicate->{sID}) &&
                        	($predicate->{sID} ne '') ) ) {
          		$sStatementID = reify(	$expat, 
						buildResource( $expat,$predicate->namespace,$predicate->localName),
						buildResource( $expat,$sTarget),
						buildResource( $expat,$sStatementID),
						$predicate->{sID},
						$predicate);
			$predicate->{sID} = normalizeResourceIdentifier($expat,$sStatementID);
        	} else {
          		addTriple( 	$expat,
                     			buildResource( $expat,$predicate->namespace,$predicate->localName),
                     			buildResource( $expat,$sTarget),
                     			buildResource( $expat,$sStatementID),
					$predicate->{'context'}
				 );
        	};
		return $sStatementID;
    	};

	# Before looping through the children, let's check
	# if there are any. If not, the value of the predicate is an anonymous node
	if (scalar(@{$predicate->{children}})<=0) {
		# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
		# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
		my $sObject;
		if($predicate->{isCollection}) {
			$sObject = buildResource( $expat, $RDFStore::Parser::SiRPAC::RDFMS_nil );
		} else {
			$sObject = (	(exists $d->{sID}) && 
					(defined $d->{sID}) &&
					($d->{sID} ne '') ) ? 
					buildResource( $expat, $d->{sID} ) :
					buildLiteral( $expat->{SiRPAC}->{nodeFactory},'', $d->{'parse_type'}, $d->{'lang'}, $d->{'rdf:datatype'} );
			};
        	if(	($reify) || 
			(	(defined $predicate->{sID}) &&
				($predicate->{sID} ne '') ) ) {
          		$sStatementID = reify(	$expat, 
						buildResource( $expat,$predicate->namespace,$predicate->localName),
						buildResource( $expat,$sTarget),
						# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
						# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
						$sObject,
						$predicate->{sID},
						$predicate);
        	} else {
          		addTriple( 	$expat,
                     			buildResource( $expat,$predicate->namespace,$predicate->localName),
                     			buildResource( $expat,$sTarget),
					# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
					# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
					$sObject,
					$predicate->{'context'}
				 );
			};
		};
	my $n2;
	my $j=0;
        my $currentID;
	my $collectionID;
	my $object_elements=1;
	foreach $n2 (@{$predicate->{children}}) {
		if(	(defined $n2->name()) &&
			($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) ) {

			die rdfcroak($expat,"Only one object node allowed inside predicate '".$predicate->{tag}."'")
				if(	($object_elements > 1) &&
					(! $predicate->{isCollection}) );

			if(	($j>0) &&
				(! $predicate->{isCollection}) ) {
                                die rdfcroak($expat," Syntax error when processing start element rdf:Description which is not a RDF Collection. rdf:Description elements generally may only occur to describe an object.");
                                return;
				};

			# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
			# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
			$sStatementID = processDescription ($expat,$n2, 1,0,0);
			$collectionID = newReificationID($expat)
				if($predicate->{isCollection});
			unless(	(defined $sStatementID) &&
				($sStatementID ne '') ) {
      				$sStatementID = $n2->{sAbout};
				unless(	(defined $sStatementID) &&
					($sStatementID ne '') ) {
					my $nodeID = getAttributeValue($expat, $n2->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID);
                                	if ( defined $nodeID ) {
                                        	$sStatementID = 'rdf:nodeID:'.$nodeID;
                                	} else {
						if($predicate->{isCollection}) {
							$sStatementID = $collectionID;
						} else {
							$sStatementID = newReificationID($expat);
							};
						};
					};
				};

        		$n2->{sID} = normalizeResourceIdentifier($expat,$sStatementID);

                        if($j==0) { #process once the predicate if collection
        			if(	($reify) || 
					(	(defined $predicate->{sID}) &&
						($predicate->{sID} ne '') ) ) {
          				$sStatementID = reify(	$expat, 
						buildResource( $expat,$predicate->namespace,$predicate->localName),
						buildResource( $expat,$sTarget),
						buildResource( $expat,($predicate->{isCollection}) ? $collectionID : $sStatementID),
						$predicate->{sID},
						$predicate);
        			} else {
          				addTriple( 	$expat,
                     				buildResource( $expat,$predicate->namespace,$predicate->localName),
                     				buildResource( $expat,$sTarget),
						buildResource( $expat,($predicate->{isCollection}) ? $collectionID : $sStatementID),
						$predicate->{'context'} );
        				};
                                };

			if($predicate->{isCollection}) {
                        	if($currentID) {
                                	addTriple(      $expat,
                                                buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'rest'),
                                                buildResource( $expat,$currentID),
						buildResource( $expat,$collectionID),
						$predicate->{'context'} #take the one of the predicate in this case
                                                );
                                	};
                        	$currentID=$collectionID;
				addTriple(	$expat,
					buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'first'),
					buildResource( $expat,$collectionID),
					buildResource( $expat,$sStatementID),
					$predicate->{'context'} #take the one of the predicate in this case
					);
				};
			$j++;

			$object_elements++;
      		} elsif ($n2->isa('RDFStore::Parser::SiRPAC::DataElement')) {
			# We've got real data
        		my $sValue = $n2->{sContent};
			# i.e.
                        #       <rdf:RDF>
                        #               <dc:title>not valid
                        #                          literal<rdf:value>valid literal<rdf:value> still n
                        #             ot valid lit</dc:title>
                        #       </rdf:RDF>
                        # 
                        # is rdfcroaking() while
                        #
                        #       <rdf:RDF>
                        #               <dc:title>          
                        #                          
                        #            <rdf:value>valid literal<rdf:value>
                        #                                </dc:title>
                        #       </rdf:RDF>
                        #
                        # is just normal valid XML/RDF :) bug fix by AR 2002/06/26 23:30 CET
                        #
			my $trimstring = $sValue;
                        $trimstring =~ s/^\s+//mg;
                        $trimstring =~ s/\s+$//mg;
                        if(     ( $object_elements > 1 ) &&
				(! $predicate->{isCollection} ) &&
                                (defined $trimstring) &&
                                (length($trimstring)>0) ) {
                                die rdfcroak($expat,"Expected whitespace found: ". $sValue);
                                return;
                                };

                        # If this predicate has an rdf:resource propAttr defined,
                        # it should be the target [subject] of the triple
                        $sTarget = $predicate->{sResource}
                                if (    (exists $predicate->{sResource}) &&
                                        (defined $predicate->{sResource}) &&
                                        ($predicate->{sResource} ne '') );

                        # Only if the content is not empty PCDATA (whitespace that is), print the triple
                        # NOTE: If predicate has an ID, the spec says it should be reified.
			if(	(     (defined $trimstring) &&
                                	(length($trimstring)>0) ) ||
				($#{$predicate->{children}} == 0 ) ) {
                        	if(     ($reify) ||
                        		(       (defined $predicate->{sID}) &&
                                        	($predicate->{sID} ne '') ) ) {
                        		$sStatementID = reify(  $expat,
                                				buildResource( $expat,$predicate->namespace,$predicate->localName),
                                                        	buildResource( $expat,$sTarget),
								($predicate->{isCollection}) ? 
									buildResource( $expat,$RDFStore::Parser::SiRPAC::RDFMS_nil) :
									($predicate->name() eq $RDFStore::Parser::SiRPAC::RDFMS_type) ?
										buildResource( $expat,$sValue) :
                                                        			buildLiteral( $expat->{SiRPAC}->{nodeFactory}, $sValue, $n2->{'parse_type'}, $n2->{'lang'}, $n2->{'rdf:datatype'} ),
                                                        	$predicate->{sID},
								$predicate); #ignore isXML
                                	$predicate->{sID} = normalizeResourceIdentifier($expat,$sStatementID);
                         	} else {
#print "PREDICATE '".$predicate->{'tag'}."' lang='".$predicate->{'lang'}."'\n";
                         		addTriple (     $expat,
                                			buildResource( $expat,$predicate->namespace,$predicate->localName),
                                                	buildResource( $expat,$sTarget),
							($predicate->{isCollection}) ? 
								buildResource( $expat,$RDFStore::Parser::SiRPAC::RDFMS_nil) :
								($predicate->name() eq $RDFStore::Parser::SiRPAC::RDFMS_type) ?
									buildResource( $expat,$sValue) :
                                                        		buildLiteral( $expat->{SiRPAC}->{nodeFactory}, $sValue, $n2->{'parse_type'}, $n2->{'lang'}, $n2->{'rdf:datatype'} ),
							$predicate->{'context'}
                                                	); #ignore isXML
                			};

				$object_elements++;
				};
      		} elsif( 	($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                            	($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                                ($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) ) {

			die rdfcroak($expat,"Only one object node allowed inside predicate '".$predicate->{tag}."'")
				if(	($object_elements > 1) &&
					(! $predicate->{isCollection}) );

			my $sContainerID = processContainer($expat,$n2);
        		$sStatementID = $sContainerID;

			# Attach the collection to the current predicate
			my $description_target = (defined $description->{vTargets}->[0]) ? $description->{vTargets}->[0] : undef;
        		if (defined $description_target) {
				if (    ($reify) ||
					(       (defined $predicate->{sID}) &&
                                        	($predicate->{sID} ne '') ) ) {
          				$sStatementID = reify(	$expat, 
						buildResource( $expat,$predicate->namespace,$predicate->localName),
						buildResource( $expat,$description_target->{sAbout}),
						buildResource( $expat,$sContainerID),
						$predicate->{sID},
						$predicate);
					$predicate->{sID} = normalizeResourceIdentifier($expat,$sStatementID);
        			} else {
					addTriple(	$expat,
							buildResource( $expat,$predicate->namespace,$predicate->localName),
							buildResource( $expat,$description_target->{sAbout}),
							buildResource( $expat,$sContainerID),
							$predicate->{'context'}
						 );
        			};
        		} else {
				if (    ($reify) ||
					(       (defined $predicate->{sID}) &&
                                        	($predicate->{sID} ne '') ) ) {
          				$sStatementID = reify(	$expat, 
						buildResource( $expat,$predicate->namespace,$predicate->localName),
						buildResource( $expat,$sTarget),
						buildResource( $expat,$sContainerID),
						$predicate->{sID},
						$predicate);
					$predicate->{sID} = normalizeResourceIdentifier($expat,$sStatementID);
        			} else {
					addTriple(	$expat,
							buildResource( $expat,$predicate->namespace,$predicate->localName),
							buildResource( $expat,$sTarget),
							buildResource( $expat,$sContainerID),
							$predicate->{'context'}
						 );
        			};
        		};
		
			$object_elements++;
      		} elsif( 	(!($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
				(!($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_nodeID)) &&
				(length($n2->name())>0) ) {

			die rdfcroak($expat,"Only one object node allowed inside predicate '".$predicate->{tag}."'")
				if(	($object_elements > 1) &&
					(! $predicate->{isCollection}) );

        		$sStatementID = processTypedNode($expat,$n2);
                        if($predicate->{isCollection}) {
				$collectionID = newReificationID($expat);

                                if($currentID) {
                                        addTriple(      $expat,
                                                buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'rest'),
                                                buildResource( $expat,$currentID),
                                                buildResource( $expat,$collectionID),
						$predicate->{'context'} #take the one of the predicate in this case
                                                );
				} else { #process once the predicate if collection
          				addTriple ( 	$expat,
                     				buildResource( $expat,$predicate->namespace,$predicate->localName),
                     				buildResource( $expat,$sTarget),
						buildResource( $expat,$collectionID),
						$predicate->{'context'} #take the one of the predicate in this case
					 	);
                                        };

                                $currentID=$collectionID;
                                addTriple(      $expat,
                                        buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'first'),
                                        buildResource( $expat,$collectionID),
                                        buildResource( $expat,$sStatementID),
					$predicate->{'context'} #take the one of the predicate in this case
                                        );
			} else {
          			addTriple ( 	$expat,
                     			buildResource( $expat,$predicate->namespace,$predicate->localName),
                     			buildResource( $expat,$sTarget),
					buildResource( $expat,$sStatementID),
					$predicate->{'context'}
					 );
                                };
			$j++;

			$object_elements++;
      			};
    		};

	if(	($j>0) && 
		($predicate->{isCollection}) ) {
        	addTriple(      $expat,
                		buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'rest'),
                                buildResource( $expat,$currentID),
               			buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'nil'),
				$predicate->{'context'} #take the one of the predicate in this case
                                );
		};

	return $sStatementID;
	};

sub reify {
	my ($expat,$predicate,$subject,$object,$sNodeID,$ele) = @_;

	my $nodeID = getAttributeValue($expat, $ele->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_nodeID); # XXXXXXX to be checked
	if ( defined $nodeID ) {
        	$sNodeID = 'rdf:nodeID:'.$nodeID
    			if(not(((defined $sNodeID) && ($sNodeID ne ''))));
        } else {
		$sNodeID = newReificationID($expat)
    			if(not(((defined $sNodeID) && ($sNodeID ne ''))));
		};

#print STDERR "reify('".$predicate->toString."','".$subject->toString."','".$object->toString."','$sNodeID','$ele')",((caller)[2]),"\n";

     	# The original statement must remain in the data model
    	addTriple($expat,$predicate, $subject, $object, $ele->{'context'});

	# Do not reify reifyd properties
    	if (	($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_subject) ||
    		($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_predicate) ||
    		($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_object) ||
    		($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_type) ) {
      		return;
    	};

	# Reify by creating 4 new triples
    	addTriple(	$expat,
			buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'predicate'),
			buildResource( $expat,$sNodeID),	
			$predicate,
			$ele->{'context'} );

    	addTriple(	$expat,
			buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'subject'),
			buildResource( $expat,$sNodeID),	
			#bug fix by AR 2001/06/10
			(length($subject->toString()) == 0) ?
				buildResource( $expat,$expat->{'sSource'}.'#' ) :
				$subject,
			$ele->{'context'}
			);

    	addTriple(	$expat,
			buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'object'),
			buildResource( $expat,$sNodeID),	
			$object,
			$ele->{'context'});

    	addTriple(	$expat,
			buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
			buildResource( $expat,$sNodeID),	
			buildResource( $expat,$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Statement'),
			$ele->{'context'}
			);

	return $sNodeID;
};

# Take an element <i>ele</i> with its parent element <i>parent</i>
# and evaluate all its attributes to see if they are non-RDF specific
# and non-XML specific in which case they must become children of
# the <i>ele</i> node.
sub expandAttributes {
	my ($expat,$parent,$ele,$predicateNode,$resourceValue) = @_;

#print "expandAttributes(".$parent->name().",".$ele->name().",$predicateNode)",((caller)[2]),"\n";
#use Data::Dumper;
#print Dumper($parent);

	my $foundAbbreviation = 0;
	my $resourceFound = 0;
	
  	my $count=0;
	while ($count<=$#{$ele->{attlist}}) {
    		my $sAttribute = ( (defined $ele->{attlist}->[$count++]->[0]) ? $ele->{attlist}->[$count-1]->[0] : '').( (defined $ele->{attlist}->[$count-1]->[1]) ? $ele->{attlist}->[$count-1]->[1] : '');
    		my $sValue = getAttributeValue($expat, $ele->{attlist},$sAttribute);

		#perhaps should next if not defined $sValue.....

		$count++;
      		if ($sAttribute =~ m|^$RDFStore::Parser::SiRPAC::XMLSCHEMA|) {
        		# expands after parsing, that's why it is useless here... :(
           		# because of concatenation without : inbetween
			# ...there was something more here to do....
        		next;
      			};

      		# exception: expand rdf:value and rdf:type and rdf:li elements - the last two must be resources and not literal values anyway
		# test http://www.w3.org/2000/10/rdf-tests/rdfcore/rdf-ns-prefix-confusion/test0006.rdf was failing and others - we fixed
		# processPredicate() method after attributes have been expanded to force resource object nodes for rdf:type on predicate with rdf:resource
      		if (	($sAttribute =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
          		(!($ele->{attlist}->[$count-2]->[1]=~ /^_/)) && #this might be buggy by AR 2001/05/28
          		(!($ele->{attlist}->[$count-2]->[1] =~ /^value$/)) &&
          		(!($ele->{attlist}->[$count-2]->[1] =~ /^type$/)) ) {

			# If an attribute (e.g. a property that follows the
			# propAttr production) is not qualified but its enclosing
			# (parent) element is from the RDFMS namespace, then the
			# attribute was prefaced with RDFMS in RDFXML_StartElementHandler().
			# This must be handled here so that the propAttr is added to the Model.
        		if(	($ele->{attlist}->[$count-2]->[1] =~ /resource$/) && 
				($predicateNode) ) {
          			$resourceFound = 1;
          			next;
        			};
 
			next
				if(	($ele->{attlist}->[$count-2]->[1] =~ /ID$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /bagID$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /about$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /aboutEach$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /datatype$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /parseType$/) );
		};
		
      		# expanding predicate element
      		#if( 	($predicateNode) &&
		#	(!($sAttribute eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) &&
		#       (!($sAttribute eq $RDFStore::Parser::SiRPAC::RDFMS_nodeID)) ) {
		#	die rdfcroak($expat,"Property element ". $ele->name()." has invalid attribute ".$sAttribute.". Only rdf:resource is allowed.");
		#};

      		$foundAbbreviation = 1;

		#xml:lang, rdf:datatypae and rdfstore:context settings are taken from the current $ele being expanded
		my $newElement =  RDFStore::Parser::SiRPAC::Element->new($ele->{attlist}->[$count-2]->[0],$ele->{attlist}->[$count-2]->[1], undef, $ele->{'lang'}, $ele->{'rdf:datatype'}, $ele->{'context'});

		my $newData = RDFStore::Parser::SiRPAC::DataElement->new($sValue, 0, $ele->{'lang'}, $ele->{'rdf:datatype'}, $ele->{'context'});
        	push @{$newElement->{children}},$newData;
        	push @{$parent->{children}},$newElement;
		};

	# If an rdf:resource propAttr was found in this predicate then
	# cache its value in each of the predicate's elements.  The value
	# of the this propAttr will be the subject of all of the propAttr's triples
    	if(	($resourceFound) && (defined $resourceValue) ) {
		my $i=0;
        	foreach $i (0..$#{$parent->{children}}) {
        		$parent->{children}->[$i]->{sResource}= $resourceValue;
        	}; 
	};

#print STDERR "----".$ele->{tag}."\n";
#map {
#if(ref($_)) {
#	print STDERR $_->[0],$_->[1],"=";
#} else {
#	print STDERR $_,"\n";
#};
#} @{$ele->{attlist}};

	return $foundAbbreviation;
};

sub parseLiteral {
	my ($expat) = @_;

#print STDERR "parseLiteral(): ".(caller)[2]."\n";

	foreach(reverse @{$expat->{SiRPAC}->{elementStack}}) {	
		my $sParseType = getAttributeValue(	$expat,
							$_->{attlist},
							$RDFStore::Parser::SiRPAC::RDFMS_parseType );
		return 1
			if(	(defined $sParseType) && 
				($sParseType ne "Resource") &&
				($sParseType ne "Collection") );
		};
    	return 0;       
	};

sub parseResource {
	my ($expat) = @_;

#print STDERR "parseResource($expat)",((caller)[2]),"\n";

	foreach(reverse @{$expat->{SiRPAC}->{elementStack}}) {	
		my $sParseType = getAttributeValue(	$expat,
							$_->{attlist},
							$RDFStore::Parser::SiRPAC::RDFMS_parseType );
		return 1
			if(	(defined $sParseType) &&
				($sParseType eq "Resource") );
		};
    	return 0;       
	};

sub normalizeResourceIdentifier {
	my ($expat,$sURI) = @_;

	return $sURI
		if ( $sURI =~ /^rdf:nodeID:/ ); #do not touch bNodes

#print STDERR "normalizeResourceIdentifier(['",$expat->base,"'],'$sURI')".(caller)[2]."\n";

	my $xml_base = $expat->base; #which is also set if a SourceBase is passed to the parser

	my $URL = URI->new($sURI);
        if(	(defined $URL->scheme) &&
		( $URL->scheme ne 'file') ) {
                # If sURI is an absolute URI, don't bother
                # with it
		return $sURI;
	} elsif(	(defined $sURI) && 
			(	(defined $xml_base) &&
				($xml_base ne '') ) ) {
		$xml_base =~ s/#.*$//;

		# see why at http://www.w3.org/TR/2003/PR-rdf-testcases-20031215/#sec-uri-encoding
		# NOTE: the URI module does correctly escape UTF-8-ish chars using '%' notation but RDF/XML "should" not (see above link)
		my $vURI = ($sURI !~ m/^#/) ? $sURI : '';

		my $absoluteURL;
		if( $xml_base =~ m/^(http|file):/ ) {
			my $path = new URI( $xml_base );
                        $path = $path->path
				if($path);
                        $vURI = $1 . $vURI # keep the file part otherwise the URI relative methods/flags below would drop it
				if(	($vURI ne $sURI) &&
					($path =~ m/([^\/]+\.[^\/]+)$/) );

			local $URI::ABS_REMOTE_LEADING_DOTS = 1;

			$absoluteURL = URI->new( $vURI )->abs( $xml_base ); #let URI module to sort out relative paths and make it absolute to xml_base
		} else {
			$absoluteURL = $xml_base . $vURI;
			};
		if(defined $absoluteURL) {
			return $absoluteURL.( ($sURI !~ m/^#/) ? '' : $sURI );
		} else {
			carp "Cannot combine $xml_base with $sURI";
	    		};
        } else {
		$sURI = '#'.$sURI
			unless($sURI =~ /^#/);
		return $sURI;
		};
	};

package RDFStore::Parser::SiRPAC::Element;
{
	sub new {
		my ($pkg, $namespace, $tag, $attlist, $lang, $datatype, $context) = @_;

		$attlist = []
			unless(defined $attlist);

#print STDERR "RDFStore::Parser::SiRPAC::Element::new( @_ ): ".(caller)[2]."\n";

		my $self =  {
				tag		=>	$tag,
				sNamespace	=>	$namespace,
				attlist		=>	$attlist,
				children	=>	[],
				vTargets	=>	[],
				bDone		=>	0,
				isCollection	=>	0,
				#at this level is just because SiRPAC parsing struct is broken (wrong to propagate XML attribute on elements)
				'lang'		=>      $lang, #xml:lang
				'rdf:datatype'  =>	$datatype, #rdf:datatype
				'context'	=> 	$context #rdfstore:context
			};
		bless $self,$pkg;
	};

	sub name {
		return (defined $_[0]->{sNamespace}) ?
				$_[0]->{sNamespace}.$_[0]->{tag} :
				$_[0]->{tag};
	};

	sub localName {
		return $_[0]->{tag};
	};

	sub namespace {
		return $_[0]->{sNamespace};
	};
};

package RDFStore::Parser::SiRPAC::DataElement;
{
	@RDFStore::Parser::SiRPAC::DataElement::ISA = qw( RDFStore::Parser::SiRPAC::Element );
	sub new {
		my ($pkg, $text, $parsetype, $lang, $datatype, $context) = @_;

#print STDERR "RDFStore::Parser::SiRPAC::DataElement::new( @_ ): ".(caller)[2]."\n";

		my $self = $pkg->SUPER::new(undef,$text,undef,$lang, $datatype, $context);

		delete $self->{sNamespace}; # we do not need it
		delete $self->{attlist}; # we do not need it

		$self->{'parse_type'} = (	$parsetype or 
						$datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral' ) ? 1 : 0; #Literal or Resource
		$self->{tag} = "[DATA: " . $text . "]";
		$self->{sContent} = $text; #instanceOf Data :-)
		bless $self,$pkg;
	};

	sub name { };
	sub localName { };
	sub namespace { };
};

1;
};

__END__

=head1 NAME

RDFStore::Parser::SiRPAC - This module implements a streaming RDF Parser as a direct implementation of XML::Parser::Expat(3)

=head1 SYNOPSIS

	use RDFStore::Parser::SiRPAC;
        use RDFStore::NodeFactory;
        my $p=new RDFStore::Parser::SiRPAC(
		ErrorContext => 2,
                Handlers        => {
                        Init    => sub { print "INIT\n"; },
                        Final   => sub { print "FINAL\n"; },
                        Assert  => sub { print "STATEMENT - @_\n"; }
                },
                NodeFactory     => new RDFStore::NodeFactory() );

	$p->parsefile('http://www.gils.net/bsr-gils.rdfs');
        $p->parsefile('http://www.gils.net/rdf/bsr-gils.rdfs');
        $p->parsefile('/some/where/my.rdf');
        $p->parsefile('file:/some/where/my.rdf');
	$p->parse(*STDIN); #parse stream but with *blocking* Expat (see below example for n-blocking parsing using XML::Parse::ExpatNB)

	use RDFStore::Parser::SiRPAC;
        use RDFStore::NodeFactory;
	my $pstore=new RDFStore::Parser::SiRPAC(
                ErrorContext 	=> 2,
		Style           => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory     => new RDFStore::NodeFactory(),
                style_options   =>      {
                                        persistent      =>      1,
                                        seevalues       =>      1,
                                        store_options         =>      { Name => '/tmp/test' }
                                }
        );
	my $rdfstore_model = $pstore->parsefile('http://www.gils.net/bsr-gils.rdfs');

	#using the expat no-blocking feature (generally for large XML streams) - see XML::Parse::Expat(3)
	my $rdfstore_stream_model = $pstore->parsestream(*STDIN);
	

=head1 DESCRIPTION

This module implements a Resource Description Framework (RDF) I<streaming> parser completely in 
Perl using the XML::Parser::Expat(3) module. The actual RDF parsing happens using an instance of XML::Parser::Expat with Namespaces option enabled and start/stop and char handlers set.
The RDF specific code is based on the modified version of SiRPAC of Sergey Melnik in Java; a lot of
changes and adaptations have been done to actually run it under Perl.
Expat options may be provided when the RDFStore::Parser::SiRPAC object is created. These options are then passed on to the Expat object on each parse call.

Exactly like XML::Parser(3) the behavior of the parser is controlled either by the Style entry elsewhere in this document and/or the Handlers entry elsewhere in this document options, or by the setHandlers entry elsewhere in this document method. These all provide mechanisms for RDFStore::Parser::SiRPAC to set the handlers needed by Expat.  If neither Style nor Handlers are specified, then parsing just checks the RDF document syntax against the W3C RDF Raccomandation . When underlying handlers get called, they receive as their first parameter the Expat object, not the Parser object.

To see some examples about how to use it look at the sections below and in the samples and utils directory coming with this software distribution.

E.g.
	With RDFStore::Parser::SiRPAC you can easily write an rdfingest.pl script to do something like this:

	fetch -o - -q http://dmoz.org/rdf/content.rdf.u8.gz | \
		gunzip - | \
		sed -f dmoz.content.sed | rdfingest.pl - 

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::Parser::SiRPAC. B<Options> are passed as keyword value
pairs. Recognized options are:

=over 4

=item * NodeFactory

This option is B<mandatory> to run the RDFStore::Parser::SiRPAC parser correctly and must contain a reference to an object of type RDFStore::NodeFactory(3). Such a reference is used during the RDF parsing to create resources, literal and statements to be passed to the registered handlers. A sample implementation is RDFStore::NodeFactory that is provided
with the RDFStore package.

=item * Source

This option can be specified by the user to set a base URI to use for the generation of resource URIs during parsing. If this option is omitted the parser will try to generate a prefix for generated resources using the input filename or URL actually containing the input RDF. In a near future such an option could be obsoleted by use of XMLBase W3C raccomandation.

=item * GenidNumber

Seed the counter for bNodes with the given value

=item * bCreateBags

Flag to generate a Bag for each Description element

=item * Style

This option provides an easy way to set a given style of parser. There is one sample Sylte module provided with the RDFStore::Parser::SiRPAC distribution called RDFStore::Parser::Styles::RDFStore::Model. Such a module uses the RDFStore::Model(3) to implement a simple RDF storage.
Custom styles can be provided by giving a full package name containing
at least one '::'. This package should then have subs defined for each
handler it wishes to have installed. See L<"WRITE YOUR OWN PARSER"> below
for a discussion on how to build one.

=item * Handlers

When provided, this option should be an anonymous hash containing as
keys the type of handler and as values a sub reference to handle that
type of event. All the handlers get passed as their 1st parameter the
instance of Expat that is parsing the document. Further details on
handlers can be found in L<"HANDLERS">. Any handler set here
overrides the corresponding handler set with the Style option.

=item * ErrorContext

This is an XML::Parser option. When this option is defined, errors are reported
in context. The value should be the number of lines to show on either side
of the line in which the error occurred.

=back

All the other XML::Parser and XML::Parser::Expat options should work freely with RDFStore::Parser::SiRPAC see XML::Parser(3) and XML::Parser::Expat(3).

=item  setHandlers(TYPE, HANDLER [, TYPE, HANDLER [...]])

This method registers handlers for various parser events. It overrides any
previous handlers registered through the Style or Handler options or through
earlier calls to setHandlers. By providing a false or undefined value as
the handler, the existing handler can be unset.

This method returns a list of type, handler pairs corresponding to the
input. The handlers returned are the ones that were in effect prior to
the call.

See a description of the handler types in L<"HANDLERS">.

=item parse(SOURCE, URIBASE [, OPT => OPT_VALUE [...]])

The SOURCE parameter should either be a string containing the whole RDF
document, or it should be an open IO::Handle.
The URIBASE can be specified by the user to set a base URI to use for the generation of resource URIs during parsing. If this option is omitted the parser will try to generate a prefix for generated resources using either the L<Source> option of the constructor, the input filename or URL actually containing the input RDF. In a near future such an option could be obsoleted by use of XMLBase W3C raccomandation.
Constructor options to XML::Parser::Expat given as keyword-value pairs may follow the URIBASE
parameter. These override, for this call, any options or attributes passed
through from the RDFStore::Parser::SiRPAC instance.

A die call is thrown if a parse error occurs. Otherwise it will return 1
or whatever is returned from the B<Final> handler, if one is installed.
In other words, what parse may return depends on the style.

e.g. the RDFStore::Parser::SiRPAC::RDFStore Style module returns an instance of RDFStore::Model

=item parsestring(STRING, URIBASE [, OPT => OPT_VALUE [...]])

This is just an alias for parse for backwards compatibility.

=item parsefile(URL_OR_FILE [, OPT => OPT_VALUE [...]])

Open URL_OR_FILE for reading, then call parse with the open handle. If URL_OR_FILE
is a full qualified URL this module uses Socket(3) to actually fetch the content.
The URIBASE L<parse()> parameter is set to URL_OR_FILE.

=item getReificationCounter()

Return the current (latest) bNodes counter generated/managed by the parser

=back

=head1 HANDLERS

As Expat, SiRPAC is an event based parser. As the parser recognizes parts of the
RDF document then any handlers registered for that type of an event are called 
with suitable parameters.
All handlers receive an instance of XML::Parser::Expat as their first
argument. See L<XML::Parser::Expat/"METHODS"> for a discussion of the
methods that can be called on this object.

=head2 Init             (Expat)

This is called just before the parsing of the document starts.

=head2 Final            (Expat)

This is called just after parsing has finished, but only if no errors
occurred during the parse. Parse returns what this returns.

=head2 Assert            (Expat, Statement)

This event is generated when a new RDF statement has been generated by the parseer.start tag is recognized. Statement is of type RDFStore::Statement(3) as generated
by the RDFStore::NodeFactory(3) passed as argument to the RDFStore::Parser::SiRPAC 
constructor.

=head2 Start_XML_Literal            (Expat, Element [, Attr, Val [,...]])

This event is generated when an XML start tag is recognized within an RDF
property with parseType="Literal". Element is the
name of the XML element type that is opened with the start tag. The Attr &
Val pairs are generated for each attribute in the start tag.

This handler should return a string containing either the original XML chunck or one f its transformations, perhaps using XSLT.

=head2 Stop_XML_Literal              (Expat, Element)

This event is generated when an XML end tag is recognized within an RDF
property with parseType="Literal". Note that an XML empty tag (<foo/>) generates both a Start_XML_Literal and an Stop_XML_Literal event.

=head2 Char_XML_Literal             (Expat, String)

This event is generated when non-markup is recognized within an RDF
property with parseType="Literal". The non-markup sequence of characters is in 
String. A single non-markup sequence of encoding of the string in the original 
document, this is given to the handler in UTF-8.

This handler should return the processed text as a string.

=head2 manage_bNodes           (Expat, Factory, SystembNode)

This event is triggered when a new anonymous resource (bNode) needs to be
generated by the system e.g. 'genidrdfstoreS302e313439323736363337373935353039P22533T106968250320N21' 
or a rdf:nodeID attribute is found into the input RDF/XML. When is not rdf:nodeID, by default the system is
trying ot use 'GenidNumber' base as passed to the parser constructor to count
sequentially the bNode identifiers and internally create an anonymous RDF resource node. 
Otherwise the counter will start from zero (0). The system will then concatenate such a sequential 
counter/number to a another unique string built by a hex-encoded random number between 0-1 (i.e. unpack("H*", rand()) ),
the current system Process ID (PID) and system timestamp. For example, if the 'GenidNumber' is set 
to '45', rand()=0.149276637795509 and PID=2233 and system timestamp=1069672550, the parser will 
generate 'genidrdfstoreS302e313439323736363337373935353039P2233T1069672550N45' as identifier.
The user should note that such a unique ID (a part the 'genidrdfstore' prefix) will allow
to post-process such an identifier to get out the PID, the timestamp and the counter
parts by using the 'S', 'P', 'T' and 'N' chars separators. In addition, the prefix of such an identifier 
should be unique across different parser runs even on the same file/source i.e. random seed, PID and timestamp 
uniquely identify the parse run (process). If a rdf:nodeID is encountered the system is 
simply copying the bNode identifier through e.g. rdf:nodeID="blue" will remain unchanged 
as 'blue' and so on.

NOTE: The 'manage_bNodes' could be called several times for the same 'SystembNode'

If this handler is undefined the system behaves by default as outline above - otherwise
the end-application can interect with this process.

By using this handler the end-application can control how to generate identfiers 
for anonymous resources OR how to re-write specific bNodes as normal URI qualified 
resources. The end-application will get triggered 'manage_bNodes' events for each 
new (system generated) bNode or when a given rdf:nodeID attribute is found into the 
input RDF/XML source. The system wide generated 'SystembNode' identifier is also passed 
to the handler code. As already pointed out, multiple events could result for the
same 'SystembNode'.

The 'SystembNode' parameter will either contain the bare bone system generated identifier
like 'genidrdfstoreS302e313439323736363337373935353039P2233T1069672550N45' or the rdf:nodeID 
like 'blue' - it is recommended to the end-application to keep the 'genidrdfstore' prefix for 
sequential generated identifiers. This will allow in the future to immediately distinguish bNodes 
generated by the RDF/XML parser from rdf:nodeID or application specific ones.

By using the 'manage_bNodes' event, for example, the application could keep track of 
system unique (and/or sequential) identifiers for bNodes internally or re-write a given bNode.

The end-application must use the 'Factory' parameter (which should correspond to the
'NodeFactory' parameter passed to the parser constructor) to return to the parser (caller)
the corresponding RDFStore::RDFNode(3) to use in place of the specific generated event.

For example, the handler could keep a kind of look-up table of system generated bNodes or
input source rdf:nodeID to application specific URIs. In which case the end-application would
rewrite input anonymous resource to valid world-wide unique resources.

Here are three examples - the first is simply passing/delegating to the parser
the generation of an anonymous resource:

 sub manage_bNodes {
	return $_[1]->createAnonymousResource( $_[2] ); #does really nothing...pass through
	};

The second example rewrite system wide generated bNodes to application specific bNodes:

 sub manage_bNodes {
	my ($expatm, $factory, $systemid) = @_;

	$systemid =~ s/^genidrdfstore/genidmyapplication/;

	return $factory->createAnonymousResource( $systemid );
	};

The last example re-write parser generated and rdf:nodeID bNodes to an application
specific URI list:

 my %app_uri_map = (
	'genidrdfstoreS302e313439323736363337373935353039P2233T1069672550N45' => 'http://www.asemantics.com/index.html',
	'alberto' => 'http://foaf.asemantics.com/alberto',
	'zac' => 'http://foaf.asemantics.com/zac',
	'dirkx' => 'http://foaf.asemantics.com/dirkx'
	);

 sub manage_bNodes {
	my ($expatm, $factory, $systemid) = @_;

	return $factory->createResource( $app_uri_map{$systemid} );
	};

This handler must return a valid RDFStore::Resource(3) node.

=head1 WRITE YOUR OWN PARSER

Write an extension module for you needs it is as easy as write one for XML::Parser :)
Have a look at http://www.xml.com/xml/pub/98/09/xml-perl.html and http://wwwx.netheaven.com/~coopercc/xmlparser/intro.html.

You can either make you Perl script a parser self by embedding the needed function hooks or write a
custom Style module for RDFStore::Parser::SiRPAC.

=head2 *.pl scripts

	use RDFStore::Parser::SiRPAC;
	use RDFStore::NodeFactory;
	my $p=new RDFStore::Parser::SiRPAC(
		Handlers        => {
			Init    => sub { print "INIT\n"; },
			Final   => sub { print "FINAL\n"; },
			Assert  => sub { print "STATEMENT - @_\n"; }
		},
		NodeFactory     => new RDFStore::NodeFactory() );


or something like:

	use RDFStore::Parser::SiRPAC;
        use RDFStore::NodeFactory;
	my $p=new RDFStore::Parser::SiRPAC( NodeFactory     => new RDFStore::NodeFactory() );
	$p->setHandlers(        Init    => sub { print "INIT\n"; },
                        	Final   => sub { print "FINAL\n"; },
                        	Assert  => sub { print join(",",@_),"\n"; }     );

=head2 Style modules

A more sophisticated solution is to write a complete Perl5 Sytle module for RDFStore::Parser::SiRPAC that
can be easily reused in your code. E.g. a perl script could use this piece of code:

	use RDFStore::Parser::SiRPAC;
	use RDFStore::Parser::SiRPAC::MyStyle;
	use RDFStore::NodeFactory;

	my $p=new RDFStore::Parser::SiRPAC(	Style => 'RDFStore::Parser::SiRPAC::MyStyle',
                			NodeFactory     => new RDFStore::NodeFactory() );
	$p->parsefile('http://www.gils.net/bsr-gils.rdfs');

The Style module self could stored into a file like MyStyle.pm like this:

	package RDFStore::Parser::SiRPAC::MyStyle;

	sub Init { print "INIT\n"; };
	sub Final { print "FINAL\n"; };
	sub Assert {
                print "ASSERT: ",
                                $_[1]->subject()->toString(),
                                $_[1]->predicate()->toString(),
                                $_[1]->object()->toString(), "\n";
	};
	sub Start_XML_Literal { print "STARTAG: ",$_[1],"\n"; };
	sub Stop_XML_Literal { print "ENDTAG: ",$_[1],"\n"; };
	sub Char_XML_Literal { print "UTF8 chrs: ",$_[1],"\n"; };

	1;

For a more complete and useful example see RDFStore::Parser::SiRPAC::RDFStore(3).


=head1 BUGS

This module implements most of the W3C RDF Raccomandation as its Java counterpart SiRPAC from the Stanford University Database Group by Sergey Melnik (see http://www-db.stanford.edu/~melnik/rdf/api.html)
This version is conformant to the latest RDF API Draft on 2000-11-13. It does not support yet:

	* aboutEach

=head1 SEE ALSO

 RDFStore::Parser::SiRPAC(3), DBMS(3) and XML::Parser(3) XML::Parser::Expat(3)

 RDFStore::Model(3) RDFStore::NodeFactory(3)

 RDF Model and Syntax Specification - http://www.w3.org/TR/rdf-syntax-grammar/

 RDF Schema Specification 1.0 - http://www.w3.org/TR/rdf-schema/

 Benchmarking XML Parsers by Clark Cooper - http://www.xml.com/pub/Benchmark/article.html

 See also http://www.w3.org/RDF/Implementations/SiRPAC/SiRPAC-defects.html

 RDF::Parser(3) from http://www.pro-solutions.com

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

	Sergey Melnik <melnik@db.stanford.edu> is the original author of the streaming version of SiRPAC in Java
	Clark Cooper is the author of the XML::Parser(3) module together with Larry Wall
