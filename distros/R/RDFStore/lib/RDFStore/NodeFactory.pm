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
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified createResource() method accordingly to rdf-api-2000-10-30
# *     version 0.4
# *		- changed way to return undef in subroutines
# *		- implemented createOrdinal()
# *     version 0.41
# *		- added anonymous resource support via createAnonymousResource() and createbNode() - see also RDFStore::Resource(3)
# *		- added statements reification support via createReifiedStatement() - see also RDFStore::Statement(3)
# *		- updated accordingly to new RDFStore API
# *		- added createNTriple() method
# *     version 0.42
# *		- fixed bNodes identifers generation
# *

package RDFStore::NodeFactory;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.42';

use Carp;
use RDFStore::Literal;
use RDFStore::Resource;
use RDFStore::Statement;
use RDFStore::Util::Digest;

sub new {
	my ( $pkg, $nodesCounter, $bnodesCounter, $timestamp, $rand_seed ) = @_;

	$nodesCounter = 0
		unless($nodesCounter);
	$bnodesCounter = 0
		unless($bnodesCounter);
	$timestamp = time()
		unless($timestamp);
	$rand_seed = unpack("H*", rand())
		unless($rand_seed);

    	bless {
		'nodesCounter' => $nodesCounter,
		'bnodesCounter' => $bnodesCounter,
		'timestamp' => $timestamp,
		'rand_seed' => $rand_seed
		}, $pkg;
	};

# Creates a resource from a URI or from namespace and local name
sub createResource {
	if(defined $_[2]) {
		return new RDFStore::Resource($_[1],$_[2]) or
			return;
	} else {
		return ($_[1]) ? new RDFStore::Resource($_[1]) : undef;
		};
	};

sub createAnonymousResource {
	if(defined $_[1]) {
		return new RDFStore::Resource($_[1], undef, 1);
	} else {
		# try to generate system/run wide unique ID i.e. 'S' + unpack("H*", rand()) + 'P' + $$ + 'T' + time() + 'N' + GenidNumber
		return new RDFStore::Resource(
			'rdfnodeIDgenidrdfstore' .
			'S'.$_[0]->{'rand_seed'} .
			'P'. $$.
			'T'. $_[0]->{'timestamp'} .
			'N'. $_[0]->{bnodesCounter}++, undef, 1 );
		};
	};

sub createbNode {
	my ($class) = shift;

	return $class->createAnonymousResource(@_);
	};

sub createLiteral {
	my ($class) = shift;

	return new RDFStore::Literal(@_);
	};

sub createStatement {
	return ( 	(defined $_[1]) && 
			(defined $_[2]) && 
			(defined $_[3]) ) ? new RDFStore::Statement($_[1], $_[2], $_[3], (defined $_[4]) ? $_[4] : undef ) :
			undef;
	};

sub createReifiedStatement {
	return ( 	(defined $_[1]) && 
			(defined $_[2]) && 
			(defined $_[3]) ) ? 
				new RDFStore::Statement( $_[1], $_[2], $_[3], 
									( (defined $_[4]) ? $_[4] : undef ), 1, 
									( (defined $_[5]) ? $_[5] : undef ) ) : undef;
	};

# Creates a resource with a unique ID
sub createUniqueResource {
	# try to generate system/run wide unique ID i.e. 'S' + unpack("H*", rand()) + 'P' + $$ + 'T' + time() + 'N' + IdNumber
	return new RDFStore::Resource(
			'rdfresourcerdfstore' .
			'S'.$_[0]->{'rand_seed'} .
			'P'. $$.
			'T'. $_[0]->{'timestamp'} .
			'N'. $_[0]->{nodesCounter}++ );
	};

# Creates an ordinal property (rdf:li, rdf:_N)
sub createOrdinal {
	my ($class,$i) = @_;

	if($i < 1) {
		croak "Attempt to construct invalid ordinal resource";
	} else {
		return $class->createResource("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "_" . $i); 
		};
	};

# see http://www.w3.org/TR/rdf-testcases/#ntriples and http://robustai.net/sailor/grammar/Quads.html
sub createNTriple {
        my ($class, $ntriple) = @_;

        # some basic parsing - see http://aspn.activestate.com/ASPN/Mail/Message/787168
        chomp( $ntriple );
        $ntriple =~ s/^[\x20\x09]+//;   # remove leading white space
        $ntriple =~ s/[\x20\x09]+$//;   # remove trailing white space

        if ($ntriple =~ m/[^\x20-\x7e\x0d\x0a\x09]/) {
                warn 'Invalid character(s) found';
                return undef;
                };

	unless ($ntriple =~ s/\.$//) {
		warn 'Syntax error: missing trailing full stop';
		return undef;
		};

        my ($subject, $predicate, $object, $context );

        # parse subject
        if ($ntriple =~ s/^<([^>]*)>[\x20\x09]+//) {
                # uriref
		$subject = $class->createResource( $1 );
        } elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]+//) {
                # bNode
		$subject = $class->createbNode( $1 );
        } else {
                warn 'Syntax error in <subject> token';
		return undef;
                };

        # parse predicate
        if ($ntriple =~  s/^<([^>]*)>[\x20\x09]+//) {
                # uriref
		$predicate = $class->createResource( $1 );
        } else {
                warn 'Syntax error in <predicate> token';
		return undef;
                };

        # parse object
        if ($ntriple =~  s/^<([^>]*)>[\x20\x09]+//) {
                # uriref
		$object = $class->createResource( $1 );
        } elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]+//) {
                # bNode
		$object = $class->createbNode( $1 );
        } elsif ($ntriple =~  s/"([^"]*)"\@([a-z0-9]+(-[a-z0-9]+)?)\^\^<([^>]*)>[\x20\x09]+//) {
                # literal
		if ( $4 eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral' ) {
			#parseType='Literal'
			$object = $class->createLiteral( $1, 1, $2, $4 );
		} else {
			$object = $class->createLiteral( $1, undef, $2, $4 );
			};
        } elsif ($ntriple =~  s/"([^"]*)"\^\^<([^>]*)>[\x20\x09]+//) {
                # literal
		if ( $2 eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral' ) {
			#parseType='Literal'
			$object = $class->createLiteral( $1, 1, undef, $2 );
		} else {
			$object = $class->createLiteral( $1, undef, undef, $2 );
			};
        } elsif ($ntriple =~  s/"([^"]*)"\@([a-z0-9]+(-[a-z0-9]+)?)[\x20\x09]+//) {
                # literal
		$object = $class->createLiteral( $1, undef, $2 );
        } elsif ($ntriple =~  s/"([^"]*)"[\x20\x09]+//) {
                # literal
		$object = $class->createLiteral( $1 );
        } else {
                warn 'Syntax error in <object> token';
		return undef;
                };

	if ( length($ntriple) ) {
        	# parse context (Quads actually see http://robustai.net/sailor/grammar/Quads.html)
        	if ($ntriple =~ s/^<([^>]*)>[\x20\x09]+//) {
                	# uriref
			$context = $class->createResource( $1 );
        	} elsif ($ntriple =~  s/^_:([A-Za-z][A-Za-z0-9]*)[\x20\x09]+//) {
                	# bNode
			$context = $class->createbNode( $1 );
        	} else {
                	warn 'Trash found after <object> token'; # should really say 'Syntax error in <context> token' :-)
			return undef;
                	};
		};

        return $class->createStatement( $subject, $predicate, $object, $context );
};

1;
};

__END__

=head1 NAME

RDFStore::NodeFactory - An RDF node factory implementation

=head1 SYNOPSIS

	use RDFStore::NodeFactory;
	my $factory = new RDFStore::NodeFactory();
	my $statement = $factory->createStatement(
				$factory->createResource("http://pen.com"),
  				$factory->createResource("http://purl.org/schema/1.0#author"),
  				$factory->createLiteral("Peter Pan")
				);
	my $reified_statement = $factory->createReifiedStatement(
				$factory->createResource("http://pen.com"),
  				$factory->createResource("http://purl.org/schema/1.0#author"),
  				$factory->createLiteral("Lady Oscar")
				);


=head1 DESCRIPTION

An RDFStore::NodeFactory implementation using RDFStore::RDFNode, RDFStore::Resource and RDFStore::Literal

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::NodeFactory.

=item createResource( LOCALNAME_NAMESPACE [, LOCALNAME ] )

Create a new RDFStore::Resource. If the method is called with a single perl scalar as parameter a new RDF Resource is created with the string passed as indentifier (LOCALNAME); a fully qualified RDF resource can be constructed by invoching the constructor with B<two> paramter s where the former is the NAMESPACE and the latter is the LOCALNAME. By RDF definition we assume that B<LOCALNAME can not be undefined>. If LOCALNAME is a perl reference the new Resource is flagged as anonymous-resource or bNode.

bNodes can also be created using the B<createbNode> or B<createAnonymousResource> methods below

=item createAnonymousResource( LOCALNAME_NAMESPACE [, LOCALNAME ] )

Create a new anonymous RDFStore::Resource like in the B<createResource> method above but the method is setting the RDFStore::Resource(3) internal bNode flag.

=item createbNode( LOCALNAME_NAMESPACE [, LOCALNAME ] )

Create a new anonymous RDFStore::Resource like in the B<createResource> method above but the method is setting the RDFStore::Resource(3) internal bNode flag.

=item createLiteral( LITERAL )

Create a new RDFStore::Literal. The only parameter passed is either a plain perl scalar (LITERAL) - see RDFStore::Literal(3)

=item createStatement( SUBJECT, PREDICATE, OBJECT )

Create a new RDFStore::Statement. SUBJECT and PREDICATE must be two RDFStore::Resource while OBJECT is RDFStore::RDFNode

=item createUniqueResource

Creates a new RDFStore::Resource with a unique ID using a random seed.

=item createOrdinal( INTEGER )

Creates a new RDFStore::Resource ordinal property (rdf:li, rdf:_N). The only parameter INTEGER is the scalar number to set the property to.

=head1 ABOUT RDF

 http://www.w3.org/TR/rdf-primer/

 http://www.w3.org/TR/rdf-mt

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

 http://www.w3.org/TR/1999/REC-rdf-syntax-19990222 (obsolete)

=head1 SEE ALSO

RDFStore::RDFNode(3) RDFStore::Resource(3) RDFStore::Literal(3) RDFStore(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
