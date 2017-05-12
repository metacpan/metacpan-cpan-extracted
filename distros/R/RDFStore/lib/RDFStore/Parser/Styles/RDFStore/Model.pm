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
# *             - Init() now setSourceURI() for the model
# *		- now the result set is a SetModel
# *     version 0.3
# *		- fixed bug in Assert() checking if $st is a ref and valid RDFStore::Statement
# *     version 0.31
# *		- updated documentation
# *     version 0.4
# *		- modified Assert() to print only new statements
# *		- fixed a few warnings
# *		- updated accordingly to new RDFStore::Model
# *     version 0.41
# *		- renamed
# *		- added Context option to the storage
# *		- fixed typing error when passing the nodeFactory to the model
# *		- allows to specify an existing RDFStore::Model as input
# *		- added owl:imports support
# *

package RDFStore::Parser::Styles::RDFStore::Model;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.41';

use RDFStore::Model;
use RDFStore::Vocabulary::OWL;
use Carp;

sub Init {
    my $expat = shift;

	my $context;
	if(	(exists $expat->{'style_options'}->{'store_options'}->{'Context'}) &&
		(ref($expat->{'style_options'}->{'store_options'}->{'Context'})) &&
		($expat->{'style_options'}->{'store_options'}->{'Context'}->isa("RDFStore::Resource")) ) {
		$context = $expat->{'style_options'}->{'store_options'}->{'Context'};
		delete($expat->{'style_options'}->{'store_options'}->{'Context'});
		};

	if(	(exists $expat->{'style_options'}->{'delete'}) &&
		(defined $expat->{'style_options'}->{'delete'}) ) {
		my $storename = $expat->{'style_options'}->{'store_options'}->{'Name'};
		my $in_context = ($context) ? " in context '".$context->toString."'" : '';
		my $yes = ( ($expat->{'style_options'}->{'confirm'}) && ($expat->{'style_options'}->{'confirm'} =~ m/1|yes|on/) ) ? 1 : 0;
		confirm("\n*WARNINIG* This operation can not be undone!!\n\nAre you sure you want to remove statements from '$storename' database$in_context? (^C to kill, any key to continue)\n\n")
			unless($yes);
		};


	# take an existing model if passed
	my $not_override = (exists $expat->{'RDFStore_model'}) ? 1 : 0 ;
	if(     (exists $expat->{'style_options'}->{'store_options'}->{'sourceModel'}) &&
                (ref($expat->{'style_options'}->{'store_options'}->{'sourceModel'})) &&
                ($expat->{'style_options'}->{'store_options'}->{'sourceModel'}->isa("RDFStore::Model")) ) {
		$expat->{'RDFStore_model'} = $expat->{'style_options'}->{'store_options'}->{'sourceModel'}
			unless($not_override);
	} else {
		$expat->{'RDFStore_model'} = new RDFStore::Model( 
					nodeFactory => $expat->{'NodeFactory'}, 
					%{$expat->{'style_options'}->{'store_options'}} )
			unless($not_override);
		};

	unless($not_override) {
		$expat->{'RDFStore_model'}->setContext($context)
			if(defined $context);
		$expat->{'RDFStore_model'}->setSourceURI($expat->{'sSource'})
			if(	(exists $expat->{'sSource'}) && 
				(defined $expat->{'sSource'}) );
		};
	$expat->{'imports'} = {}
		unless(exists $expat->{'imports'});
	};

sub Final {
    my $expat = shift;

	return $expat->{'RDFStore_model'};
};

# input: either Expat valid QNames or "assertions" (statements)
# output: "assertions" (statements)
# David Megginson saying that this is bad it is better Start/Stop Resource/Property
# anyway it should look like: Assert(subjectType,subject,predicate,objectType,object,lang)
# (see http://lists.w3.org/Archives/Public/www-rdf-interest/1999Dec/0045.html)
sub Assert {
	my ($expat,$st) = @_;

	if(	(exists $expat->{'style_options'}->{'delete'}) &&
		(defined $expat->{'style_options'}->{'delete'}) ) {
		# problem is wiht contexts now....when are we going to zap the context specific triples now?????
		if($expat->{'RDFStore_model'}->remove($st)) {
			# we should print just the new ones
			print "Removed statement ".$st->toString,"\n"
				if( (defined $st) && (ref($st)) && ($st->isa("RDFStore::Statement")) && (defined $expat->{'style_options'}->{'seevalues'}) );
			};
	} else {
		if($expat->{'RDFStore_model'}->add($st)) {
			# we should print just the new ones
			print "Added statement ".$st->toString,"\n"
				if( (defined $st) && (ref($st)) && ($st->isa("RDFStore::Statement")) && (defined $expat->{'style_options'}->{'seevalues'}) );
			};
		};

	if(	(defined $expat->{'style_options'}->{'owl:imports'}) &&
		($st->predicate->equals($RDFStore::Vocabulary::OWL::imports)) && #take any in it
		($st->object->toString ne $expat->{'Source'}) && #try to avoid recursion :)
		(! exists $expat->{'imports'}->{ $st->object->toString } ) ) {
		my $current_ctx = $expat->{'RDFStore_model'}->getContext;
		$expat->{'RDFStore_model'}->setContext( $st->object ); #owl:imports is the context of what is imported
		# parse the target as RDF/XML
		my $owl_p = new RDFStore::Parser::SiRPAC(
				Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                                NodeFactory => $expat->{'RDFStore_model'}->getNodeFactory,
                                Source  => $st->object->toString,
				store => {
					'seevalues' => $expat->{'style_options'}->{'seevalues'},
					'delete' => (     (exists $expat->{'style_options'}->{'delete'}) &&
							(defined $expat->{'style_options'}->{'delete'}) ) ? $expat->{'style_options'}->{'delete'} : undef,
					'confirm' => (    (exists $expat->{'style_options'}->{'confirm'}) &&
							(defined $expat->{'style_options'}->{'confirm'}) ) ? $expat->{'style_options'}->{'confirm'} : undef
					},
				RDFStore_model => $expat->{'RDFStore_model'}, #import into current one
				imports => $expat->{'imports'}
				);

		# avoid to fail the main parsing for the moment....
		eval {
			# add all those triples to current one
			$owl_p->parsefile( $st->object->toString );
			};

		$expat->{'RDFStore_model'}->setContext( $current_ctx )
			if($current_ctx); #restore old context if any

		$expat->{'imports'}->{ $st->object->toString } = ($@) ? 2 : 1; #not propagating to sub-parser above still - avoid multiples only on one level
		};
};

# we might use this callback for XSLT tansofrmations of xml-blobs :)
sub Start_XML_Literal {
	my $expat = shift;
	my $el = shift;

	$expat->{'XML_Literal_processed_namespaces'} = {}
		unless(exists $expat->{'XML_Literal_processed_namespaces'});

	my @current_ns_prefixes = $expat->current_ns_prefixes;

	my $ns_index = 1;

	my $xmlcn='';
	my $elns = $expat->namespace($el);
	if (defined $elns) {
		my $pfx;
		for my $p ( @current_ns_prefixes ) {
			if( $expat->expand_ns_prefix($p) eq $elns ) {
				$pfx = $p;	
				last;
				};
			};
		$pfx = 'n' . $ns_index++
			unless($pfx);

		if( exists $expat->{'XML_Literal_processed_namespaces'}->{ $pfx.$elns } ) {
			$xmlcn .= "<$el";
		} else {
			$xmlcn .= ( $pfx eq '#default' ) ? "<$el xmlns=\"$elns\"" : "<$pfx:$el xmlns:$pfx=\"$elns\"";
			$expat->{'XML_Literal_processed_namespaces'}->{ $pfx.$elns } = 1;
			};
	} else {
		$xmlcn .= "<$el";
		};

	if (@_) {
		for (my $i = 0; $i < @_; $i += 2) {
			my $nm = $_[$i];
			my $ns = $expat->namespace($nm);
			$_[$i] = defined($ns) ? "$ns\01$nm" : "\01$nm";
			};

    		my %atts = @_;
		my @ids = sort keys %atts;
		foreach my $id (@ids) {
			my ($ns, $nm) = split(/\01/, $id);
			my $val = $expat->xml_escape($atts{$id}, '"', "\x9", "\xA", "\xD");
			if (length($ns)) {
				my $pfx;
				for my $p ( @current_ns_prefixes ) {
					if( $expat->expand_ns_prefix($p) eq $ns ) {
						$pfx = $p;	
						last;
						};
					};
				$pfx = 'n' . $ns_index++
					unless($pfx);

				if( exists $expat->{'XML_Literal_processed_namespaces'}->{ $pfx.$ns } ) {
					$xmlcn .= " $nm=\"$val\"";
				} else {
					$xmlcn .= " $pfx:$nm=\"$val\" xmlns:$pfx=\"$ns\""; # '#default' namespace does not apply to attributes
					};
			} else {
				$xmlcn .= " $nm=\"$val\"";
				};
			};
		};

	$xmlcn .= '>';

	return $xmlcn;
	};

sub Stop_XML_Literal {
	my ($expat,$el) = @_;

	my @current_ns_prefixes = $expat->current_ns_prefixes;

	my $elns = $expat->namespace($el);
	if (defined $elns) {
		my $pfx;
		for my $p ( @current_ns_prefixes ) {
			if( $expat->expand_ns_prefix($p) eq $elns ) {
				$pfx = $p;	
				last;
				};
			};
		$pfx = 'n1' #wrong anyway
			unless($pfx);
		return ( $pfx eq '#default' ) ? "</$el>" : "</$pfx:$el>";
	} else {
		return "</$el>";
		};
	};

sub Char_Literal {
	my ($expat,$literal_text) = @_;

	return $expat->xml_escape($literal_text, '>', "\xD");	
	};

sub confirm {
        my ($msg) = @_;

        print $msg;

        return <STDIN>;
        };

1;
}

__END__

=head1 NAME

RDFStore::Parser::Styles::RDFStore::Model - This module is a RDFStore::Parser::SiRPAC(3) filter to ingest records into an RDFStore::Model(3).

=head1 SYNOPSIS

 
use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::Styles::RDFStore::Model;
use RDFStore::NodeFactory;
my $p=new RDFStore::Parser::SiRPAC(	
				ErrorContext => 2,
                                Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                                NodeFactory     => new RDFStore::NodeFactory()
                                );

if(defined $ENV{GATEWAY_INTERFACE}) {
        print "Content-type: text/html

";
        $p->parsefile($ENV{QUERY_STRING});
} else {
        my $input = shift;
        if($input =~ /^-/) {
                $p->parse(*STDIN);
        } else {
                $p->parsefile($input);
        };
};

=head1 DESCRIPTION

In the samples directory of the distribution you can find a set of a sample scripts to play with :)

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::Parser::SiRPAC. B<Options> are passed as key/value pairs. RDFStore::Parser::Styles::MagicTie supports B<all> the RDFStore::Parser::SiRPAC options plus the following:

=over 5

=item * store

This option if present must point to an HASH reference. Recognized options are:

=item * seevalues

This options is a SCALAR with possible values of 0/1 and flags whether the parsing is verbose or not (print triples)

=item * options

This option if present must point to an HASH reference and allows to the user specifying the RDFStore::Model(3) options about storage of the statements of the type generated by the corresponding RDFStore::NodeFactory(3)

=head1 NOTES

This module will probably be renamed to XML::SAX::RDF::RDFStore::Model when proper SAX2 support is added to the main RDFStore::Parser::SiRPAC parser

=head1 SEE ALSO

RDFStore::Parser::SiRPAC(3) and RDFStore::Model(3)

=head1 AUTHOR

Alberto Reggiori <areggiori@webweaving.org>
