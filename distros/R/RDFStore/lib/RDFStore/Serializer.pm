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
# *     version 0.1 - Tue Jan 28 15:30:00 CET 2003
# *

package RDFStore::Serializer;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use Carp;

# common vocabularies
use RDFStore::Vocabulary::RDF;
use RDFStore::Vocabulary::RDFS;
use RDFStore::Vocabulary::DC;
use RDFStore::Vocabulary::DCQ;
use RDFStore::Vocabulary::DCT;
use RDFStore::Vocabulary::DAML;
use RDFStore::Vocabulary::RDFStoreContext;

# it could return a kind of tied filehandle/stream :) i.e. TIEHANLDE see perltie(8)
sub new {
        my ($pkg) = @_;

        my $self = {};

	#load default ones
        $self->{Namespaces} = {};
	$self->{Namespaces}->{ $RDFStore::Vocabulary::RDF::_Namespace } = 'rdf';
	$self->{Namespaces}->{ $RDFStore::Vocabulary::RDFS::_Namespace } = 'rdfs';
	$self->{Namespaces}->{ $RDFStore::Vocabulary::DC::_Namespace } = 'dc';
	$self->{Namespaces}->{ $RDFStore::Vocabulary::DCQ::_Namespace } = 'dcq';
	$self->{Namespaces}->{ $RDFStore::Vocabulary::DCT::_Namespace } = 'dct';
	$self->{Namespaces}->{ $RDFStore::Vocabulary::DAML::_Namespace } = 'daml';
	$self->{Namespaces}->{ $RDFStore::Vocabulary::RDFStoreContext::_Namespace } = 'rdfstore';

	$self->{string} = '';

	$self->{'options'} = {};

	bless $self,$pkg;

	return $self;
	};

sub setProperty {
	my ($class, $name, $value) = @_;
	
	$class->{'options'}->{ $name } = $value;
	};

sub getProperty {
	my ($class, $name) = @_;
	
	return $class->{'options'}->{ $name };
	};

sub setNamespacePrefix {
	my ($class, $ns_uri, $ns_prefix ) = @_;
	
	$class->{Namespaces}->{ $ns_uri } = $ns_prefix;
	};

sub getNamespacePrefix {
	my ($class, $ns_uri ) = @_;
	
	return $class->{Namespaces}->{ $ns_uri };
	};

sub serialize {
	my ($class) = shift;

	return $class->write( @_ );
	};

sub write {
	my ($class, $model, $fh, $namespaces, $base ) = @_;

	croak "Model is not defined"
                unless( (defined $model) && (ref($model)) &&
                        ($model->isa('RDFStore::Model')) );

	$class->{'ioref'} = \$fh
		if( defined $fh );

	if (	( defined $namespaces ) &&
		(ref($namespaces) =~ /HASH/) ) {
		foreach my $ns_uri ( keys %{$namespaces} ) {
			$class->setNamespacePrefix( $ns_uri, $namespaces->{ $ns_uri } );
			};
		};

	# init string
	$class->{string} = '';
	};

sub printContent {
	my ($class) = shift;

	if(exists $class->{'ioref'}) {
		print ${ $class->{'ioref'} } (@_);
	} else {
		$class->{string} .= join('',@_);
		};
	};

sub returnContent {
	return (exists $_[0]->{'ioref'}) ? 1 : $_[0]->{string};
	};

sub xml_escape {      
	my $class = shift;
	my $text  = shift;

	$text =~ s/\&/\&amp;/g;
	$text =~ s/</\&lt;/g;
	foreach (@_) {
		croak "xml_escape: '$_' isn't a single character" if length($_) > 1;

		if ($_ eq '>') {
			$text =~ s/>/\&gt;/g;
		} elsif ($_ eq '"') {
			$text =~ s/\"/\&quot;/g;
		} elsif ($_ eq "'") {
			$text =~ s/\'/\&apos;/g;
		} else {
			my $rep = '&#' . sprintf('x%X', ord($_)) . ';';
			if (/\W/) {
				my $ptrn = "\\$_";
				$text =~ s/$ptrn/$rep/g;
			} else {
				$text =~ s/$_/$rep/g;
				};
			};
		};
	return $text;
	};

1;
};

__END__

=head1 NAME

RDFStore::Serializer - Interface to an RDF model/graph serializer

=head1 SYNOPSIS

	use RDFStore::Serializer;

	my $model= new RDFStore::Model();
	$model->add($statement);
	$model->add($statement1);
	$model->add($statement2);

	my $serializer = new RDFStore::Serializer;

	my $rdf = $serializer->serialize( $model ); # serialise model to a string in-memory
	my $rdf = $serializer->serialize( $model, undef, {}, $base ); # using xml:base
	my $rdf = $serializer->serialize( $model, undef, { 'http://mynamespace.org/blaaa/' => blaa } ); # using my blaa namespace

	$serializer->serialize( $model, *STREAM ); # serialise model to a given file descriptor (stream)

=head1 DESCRIPTION

An RDFStore::Model serializer.

=head1 CONSTRUCTORS
 
The following methods construct RDFStore::Serializer:

=item new ()
 
 Create an new RDFStore::Serializer object to serialize and RDFStore::Model.

=head1 METHODS
 
=item write ( MODEL [ , FILEHANDLE_REF, NAMESPACES, BASE ] )
 
 Write out the given MODEL to FILEHANDLE_REF (or in-memory string if not passed) using a given list of NAMESPACES and xml:base BASE if passed. The NAMESPACES hash ref contains a list of namespace values (URI refs) and prefix names - see RDFStore::Vocabulary::Generator(3). By default the output is returned from the method into a string otheriwse a valid (and opened) FILEHANLDE_REF can be passed, which will be being printed to.

=item serialize ( MODEL [ , FILEHANDLE_REF, NAMESPACES, BASE ] )
 
 Same as write method above.

=head1 SEE ALSO

RDFStore::Model(3) RDFStore::Serializer::Strawman(3) RDFStore::Serializer::RDFXML(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
