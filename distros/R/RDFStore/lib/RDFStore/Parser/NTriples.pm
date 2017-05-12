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
# *	version 0.1 - Tue Apr  8 00:28:24 CEST 2003
# *	version 0.2
# *		- updated wget() method invocation
# *

package RDFStore::Parser::NTriples;
{
	use vars qw($VERSION %Built_In_Styles $RDF_SYNTAX_NS $RDFMS_parseType_Literal);
	use strict;
	use Carp qw(carp croak cluck confess);
	use URI;
	use URI::Escape;
	
	use RDFStore::Util::UTF8 qw( cp_to_utf8 );

	use RDFStore::Parser;
	@RDFStore::Parser::NTriples::ISA = qw( RDFStore::Parser );

BEGIN {
	require XML::Parser::Expat;
    	$VERSION = '0.1';
    	croak "XML::Parser::Expat.pm version 2 or higher is needed to process rdf:parseType='Literal' XML content"
		unless $XML::Parser::Expat::VERSION =~ /^2\./;
	};

$RDFStore::Parser::NTriples::RDF_SYNTAX_NS="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
$RDFStore::Parser::NTriples::RDFMS_parseType_Literal = $RDFStore::Parser::NTriples::RDF_SYNTAX_NS . "XMLLiteral";

sub new {
	my ($pkg) = shift;

        my $self = $pkg->SUPER::new(@_);

        bless $self,$pkg;
	};

sub parse {
	my $class = shift;

	$class->SUPER::parse( @_ );

	my $arg = shift;
	my $file_or_uri = shift;

  	$class->{iReificationCounter}= ( ($class->{GenidNumber}) && (int($class->{GenidNumber})) ) ? $class->{GenidNumber} : 0;

	if(	(exists $class->{Source}) && 
			(defined $class->{Source}) &&
			( (!(ref($class->{Source}))) || (!($class->{Source}->isa("URI"))) )	) {
		if(-e $class->{Source}) {
			$class->{Source}=URI->new('file:'.$class->{Source});
		} else {
			$class->{Source}=URI->new($class->{Source});
		};
	} elsif(defined $file_or_uri) {
		if( (ref($file_or_uri)) && ($file_or_uri->isa("URI")) ) {
			$class->{Source}=$file_or_uri;
		} elsif(-e $file_or_uri) {
			$class->{Source}=URI->new('file:'.$file_or_uri);
		} else {
			$class->{Source}=undef; #unknown
		};
	};
	if(     (exists $class->{Source}) &&
                (defined $class->{Source}) ) {
                $class->{sSource}= $class->setSource(
                        (       (ref($class->{Source})) &&
                                ($class->{Source}->isa("URI")) ) ? $class->{Source}->as_string :
                                $class->{Source} );
        	};

	croak "Missing NodeFactory"
		unless(	(defined $class->{NodeFactory}) && 
			($class->{NodeFactory}->isa("RDFStore::NodeFactory")) );
	$class->{nodeFactory} = $class->{NodeFactory};
	$class->{Warnings} = ( defined $class->{Warnings} && $class->{Warnings} =~ m/off|0|no|hide/ ) ? 0 : 1; #default is on

    	my %handlers = %{$class->{Handlers}}
		if( (defined $class->{Handlers}) && (ref($class->{Handlers}) =~ /HASH/) );

    	my $init = delete $handlers{Init};
	my $final = delete $handlers{Final};

	#Trigger 'Init' event
    	&$init($class) 
		if defined($init);

	my $result;
	my $ioref;
	if (defined $arg) {
    		if (ref($arg) and UNIVERSAL::isa($arg, 'IO::Handler')) {
      			$ioref = $arg;
    		} else {
      			eval {
        			$ioref = *{$arg}{IO};
      				};    
      			undef $@;
    			};
  		};

	eval {
		if (defined($ioref)) {
    			my $delim = $class->{Stream_Delimiter};
    			my $prev_rs;
   
    			$prev_rs = ref($ioref)->input_record_separator("\n$delim\n")
      				if defined($delim);
   
			while ( <$arg> ) {
        			$result = $class->_pp_NTriple($_); 
				};
   
    			ref($ioref)->input_record_separator($prev_rs)
      				if defined($delim);
  		} else {
			map {
				$result = $class->_pp_NTriple( $_ . ' . ' );
			} split(/\.[\n\r]+/, $arg );
  			};
		};

        my $err = $@;
        if($err) {
                croak $err;
        	};

        if (defined $final) {
                #Trigger 'Final' event
                $result = &$final($class);
        	};

        return $result;
	};

# see http://www.w3.org/TR/rdf-testcases/#ntriples and http://robustai.net/sailor/grammar/Quads.html
# some basic parsing - updated version of http://aspn.activestate.com/ASPN/Mail/Message/787168
sub _pp_NTriple {
        my ($class, $ntriple) = @_;

        chomp( $ntriple );
        $ntriple =~ s/^[\x20\x09]+//; # remove leading white space
        $ntriple =~ s/[\x20\x09]+$//; # remove trailing white space

	return if($ntriple =~ /^#/); # skip comments
	return unless ($ntriple =~/\S/); # skip empty lines

        if ($ntriple =~ m/[^\x20-\x7e\x0d\x0a\x09]/) {
                die 'Invalid character(s) found at "'.$&.'" in "'.$ntriple.'"';
                };

	unless ($ntriple =~ s/\.\s?$//) {
		die 'Syntax error: missing trailing full stop in "'.$ntriple.'"';
		};

	# NOTE: need to Unicode \Uxxxxxxxx \uxxxx un-escape
	$ntriple =~ s/\\[uU]([0-9a-fA-F]{4,8})/&cp_to_utf8(hex($1))/xeg;

        my ($subject, $predicate, $object, $context );

        # parse subject
        if ($ntriple =~ s/^<([^>]*)>[\x20\x09]+//) {
                # uriref
		$subject = $class->{nodeFactory}->createResource( $1 );
        } elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]+//) {
                # bNode
		$subject = $class->{nodeFactory}->createbNode( $1 );
        } else {
                die 'Syntax error in <subject> token in "'.$ntriple.'"';
                };

        # parse predicate
        if ($ntriple =~  s/^<([^>]*)>[\x20\x09]+//) {
                # uriref
		$predicate = $class->{nodeFactory}->createResource( $1 );
        } elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]+//) { # we allow bArcs (with warning)
		warn "found bArcs in ntriple" if($class->{Warnings});
                # bNode
		$predicate = $class->{nodeFactory}->createbNode( $1 );
        } else {
                die 'Syntax error in <predicate> token in "'.$ntriple.'"';
                };

        # parse object
        if ($ntriple =~  s/^<([^>]*)>[\x20\x09]*//) {
                # uriref
		$object = $class->{nodeFactory}->createResource( $1 );
        } elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]*//) {
                # bNode
		$object = $class->{nodeFactory}->createbNode( $1 );
        } elsif ($ntriple =~  s/^"(.*)"\@([a-z0-9]+(-[a-z0-9]+)?)\^\^<([^>]*)>[\x20\x09]*//s) { #we need to treat the string as single-line for XML
                # literal
		if ( $4 eq $RDFStore::Parser::NTriples::RDFMS_parseType_Literal ) {
			#parseType='Literal'
			$object = $class->{nodeFactory}->createLiteral( $1, 1, $2, $4 );
		} else {
			$object = $class->{nodeFactory}->createLiteral( $1, undef, $2, $4 );
			};
        } elsif ($ntriple =~  s/^"(.*)"\^\^<([^>]*)>[\x20\x09]*//s) {
                # literal
		if ( $2 eq $RDFStore::Parser::NTriples::RDFMS_parseType_Literal ) {
			#parseType='Literal'
			$object = $class->{nodeFactory}->createLiteral( $1, 1, undef, $2 );
		} else {
			$object = $class->{nodeFactory}->createLiteral( $1, undef, undef, $2 );
			};
        } elsif ($ntriple =~  s/^"(.*)"\@([a-z0-9]+(-[a-z0-9]+)?)[\x20\x09]*//s) {
                # literal
		$object = $class->{nodeFactory}->createLiteral( $1, undef, $2 );
        } elsif ($ntriple =~  s/^"(.*)"[\x20\x09]*//s) {
                # literal
		$object = $class->{nodeFactory}->createLiteral( $1 );
        } else {
                die 'Syntax error in <object> token in "'.$ntriple.'"';
                };

	if ( length($ntriple) ) {
        	# parse context (Quads actually see http://robustai.net/sailor/grammar/Quads.html)
        	if ($ntriple =~ s/^<([^>]*)>[\x20\x09]*//) {
                	# uriref
			$context = $class->{nodeFactory}->createResource( $1 );
        	} elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]*//) {
                	# bNode
			$context = $class->{nodeFactory}->createbNode( $1 );
        	} elsif ($ntriple !~  s/^\s*\.//) { # we could have more N-Triples in the same string
                	die 'Trash found after <object> token in "'.$ntriple.'"'; # should really say 'Syntax error in <context> token' :-)
                	};
		};

        return $class->addTriple( $subject, $predicate, $object, $context );
	};

sub getReificationCounter {
	return $_[0]->{iReificationCounter};
	};

sub parsestring {
	my $class = shift;

	$class->SUPER::parsestring( @_ );

	my $string = shift;

	return $class->parse($string,undef,@_);
	};

sub parsestream {
        my $class = shift;

	$class->SUPER::parsestream( @_ );

        my $arg = shift;
        my $namespace = shift;

	my $ret;
	eval {
		$ret = $class->parse($arg, $namespace,@_);
		};
	my $err = $@;

	croak $err
		if $err;

	return $ret;
        };

sub parsefile {
	my $class = shift;

	$class->SUPER::parsefile( @_ );

	my $file = shift;

	if( (defined $file) && ($file ne '') ) {
		my $ret;
		my $file_uri;
		my $scheme;
		$scheme='file:'
			if( (-e $file) || (!($file =~ /^\w+:/)) );
                $file_uri= URI->new(((defined $scheme) ? $scheme : '' ).$file);
		if (	(defined $file_uri) && (defined $file_uri->scheme)	&&
			($file_uri->scheme ne 'file') ) {
  			my $content = $class->wget($file_uri);
			if(defined $content) {
				eval {
					$ret = $class->parsestring($content, $file_uri,@_);
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
			eval {
				$ret = $class->parse(*FILE,$file_uri,@_);
    				};
    			my $err = $@;
    			close(FILE);
    			croak $err 	
				if $err;
			};
		return $ret;
  		};
	};

sub addTriple {
        my ($class,$subject,$predicate,$object,$context) = @_;

#print STDERR "addTriple('".$subject->toString."','".$predicate->toString."','".$object->toString."'".( ($context) ? ",'".$context->toString."'" : '' ).")",((caller)[2]),"\n";

        # If there is no subject (about=""), then use the URI/filename where the RDF description came from
	$subject = $class->{nodeFactory}->createResource($class->{sSource})
		unless( (defined $subject) && ($subject->toString()) && (length($subject->toString())>0) );

	#Trigger 'Assert' event
        my $assert = $class->{Handlers}->{Assert}
		if(ref($class->{Handlers}) =~ /HASH/);
        if (defined($assert)) {
        	return &$assert($class, $class->{nodeFactory}->createStatement($subject,$predicate,$object,$context) );
	} else {
		return;
		};
	};

sub newReificationID {
	my ($class) = @_;

#print STDERR "newReificationID($class): ",((caller)[2]),"\n";

	return 'genid' . $class->{iReificationCounter}++;
	};

1;
};

__END__

=head1 NAME

RDFStore::Parser::NTriples - This module implements a streaming N-Triples parser 

=head1 SYNOPSIS

	use RDFStore::Parser::NTriples;
        use RDFStore::NodeFactory;
        my $p=new RDFStore::Parser::NTriples(
		ErrorContext => 2,
                Handlers        => {
                        Init    => sub { print "INIT\n"; },
                        Final   => sub { print "FINAL\n"; },
                        Assert  => sub { print "STATEMENT - @_\n"; }
                },
                NodeFactory     => new RDFStore::NodeFactory() );

	$p->parsefile('http://www.gils.net/bsr-gils.nt');
        $p->parsefile('http://www.gils.net/rdf/bsr-gils.nt');
        $p->parsefile('/some/where/my.nt');
        $p->parsefile('file:/some/where/my.nt');
	$p->parse(*STDIN);

	use RDFStore::Parser::NTriples;
        use RDFStore::NodeFactory;
	my $pstore=new RDFStore::Parser::NTriples(
                ErrorContext 	=> 2,
		Style           => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory     => new RDFStore::NodeFactory(),
                style_options   =>      {
                                        persistent      =>      1,
                                        seevalues       =>      1,
                                        store_options         =>      { Name => '/tmp/test' }
                                }
        );
	$pstore->parsefile('http://www.gils.net/bsr-gils.nt');


=head1 DESCRIPTION

This module implements a N-Triples I<streaming> parser.

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::Parser::NTriples. B<Options> are passed as keyword value
pairs. Recognized options are:

=over 4

=item * NodeFactory

This option is B<mandatory> to run the RDFStore::Parser::NTriples parser correctly and must contain a reference to an object of type RDFStore::NodeFactory(3). Such a reference is used during the RDF parsing to create resources, literal and statements to be passed to the registered handlers. A sample implementation is RDFStore::NodeFactory that is provided
with the RDFStore package.

=item * Source

This option can be specified by the user to set a base URI to use for the generation of resource URIs during parsing. If this option is omitted the parser will try to generate a prefix for generated resources using the input filename or URL actually containing the input RDF. In a near future such an option could be obsoleted by use of XMLBase W3C raccomandation.

=item * GenidNumber

Seed the genid numbers with the given value

=item * Style

This option provides an easy way to set a given style of parser. There is one sample Sylte module provided with the RDFStore::Parser::NTriples distribution called RDFStore::Parser::Styles::RDFStore::Model. Such a module uses the RDFStore::Model(3) to implement a simple RDF storage.
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

All the other XML::Parser and XML::Parser::Expat options should work freely with RDFStore::Parser::NTriples see XML::Parser(3) and XML::Parser::Expat(3).

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
through from the RDFStore::Parser::NTriples instance.

A die call is thrown if a parse error occurs. Otherwise it will return 1
or whatever is returned from the B<Final> handler, if one is installed.
In other words, what parse may return depends on the style.

e.g. the RDFStore::Parser::NTriples::Style::RDFStore::Model Style module returns an instance of RDFStore::Model

=item parsestring(STRING, URIBASE [, OPT => OPT_VALUE [...]])

This is just an alias for parse for backwards compatibility.

=item parsefile(URL_OR_FILE [, OPT => OPT_VALUE [...]])

Open URL_OR_FILE for reading, then call parse with the open handle. If URL_OR_FILE
is a full qualified URL this module uses IO::Socket(3) to actually fetch the content.
The URIBASE L<parse()> parameter is set to URL_OR_FILE.

=item getReificationCounter()

Return the latest genid number generated by the parser

=back

=head1 HANDLERS

The parser is an event based parser. As the parser recognizes N-Triples
then any handlers registered for that type of an event are called 
with suitable parameters.

All handlers receive an instance of XML::Parser::Expat as their first
argument. See L<XML::Parser::Expat/"METHODS"> for a discussion of the
methods that can be called on this object. Expat is needed to further
process thing like rdf:parseType="Literal" as XML.

=head2 Init             (Expat)

This is called just before the parsing of the document starts.

=head2 Final            (Expat)

This is called just after parsing has finished, but only if no errors
occurred during the parse. Parse returns what this returns.

=head2 Assert            (Expat, Statement)

This event is generated when a new RDF statement has been generated by the parseer.start tag is recognized. Statement is of type RDFStore::Statement(3) as generated by the RDFStore::NodeFactory(3) passed as argument to the RDFStore::Parser::NTriples constructor.

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

=head1 WRITE YOUR OWN PARSER

You can either make you Perl script a parser self by embedding the needed function hooks or write a
custom Style module for RDFStore::Parser::NTriples.

=head2 *.pl scripts

	use RDFStore::Parser::NTriples;
	use RDFStore::NodeFactory;
	my $p=new RDFStore::Parser::NTriples(
		Handlers        => {
			Init    => sub { print "INIT\n"; },
			Final   => sub { print "FINAL\n"; },
			Assert  => sub { print "STATEMENT - @_\n"; }
		},
		NodeFactory     => new RDFStore::NodeFactory() );


or something like:

	use RDFStore::Parser::NTriples;
        use RDFStore::NodeFactory;
	my $p=new RDFStore::Parser::NTriples( NodeFactory     => new RDFStore::NodeFactory() );
	$p->setHandlers(        Init    => sub { print "INIT\n"; },
                        	Final   => sub { print "FINAL\n"; },
                        	Assert  => sub { print join(",",@_),"\n"; }     );

=head2 Style modules

A more sophisticated solution is to write a complete Perl5 Sytle module for RDFStore::Parser::NTriples that
can be easily reused in your code. E.g. a perl script could use this piece of code:

	use RDFStore::Parser::NTriples;
	use RDFStore::Parser::NTriples::MyStyle;
	use RDFStore::NodeFactory;

	my $p=new RDFStore::Parser::NTriples(	Style => 'RDFStore::Parser::NTriples::MyStyle',
                			NodeFactory     => new RDFStore::NodeFactory() );
	$p->parsefile('http://www.gils.net/bsr-gils.rdfs');

The Style module self could stored into a file like MyStyle.pm like this:

	package RDFStore::Parser::NTriples::MyStyle;

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

=head1 SEE ALSO

 RDFStore::Parser::SiRPAC(3), DBMS(3) and XML::Parser(3) XML::Parser::Expat(3)

 RDFStore::Model(3) RDFStore::NodeFactory(3)

 N-Triples - http://www.w3.org/TR/rdf-testcases/#ntriples

 RDF Model and Syntax Specification - http://www.w3.org/TR/rdf-syntax-grammar/

 RDF Schema Specification 1.0 - http://www.w3.org/TR/rdf-schema/

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
