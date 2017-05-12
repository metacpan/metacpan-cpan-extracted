#!/usr/bin/env perl

=head1 NAME

OWL::Simple::Parser

=head1 SYNOPSIS

	use OWL::Simple::Parser;
	
	# load Experimental Factor Ontology (http://www.ebi.ac.uk/efo/efo.owl)
	my $parser = OWL::Simple::Parser->new(  owlfile => 'efo.owl',
			synonym_tag => 'efo:alternative_term',
			definition_tag => 'efo:definition' );
	
	# parse file
	$parser->parse();
	
	# iterate through all the classes
	for my $id (keys %{ $parser->class }){
		my $OWLClass = $parser->class->{$id};
		print $id . ' ' . $OWLClass->label . "\n";
		
		# list synonyms
		for my $syn (@{ $OWLClass->synonyms }){
			print "\tsynonym - $syn\n";
		}
		
		# list definitions
		for my $def (@{ $OWLClass->definitions }){
			print "\tdef - $def\n";
		}
		
		# list parents
		for my $parent (@{ $OWLClass->subClassOf }){
			print "\tsubClassOf - $parent\n";
		}
	}

=head1 DESCRIPTION

A simple OWL parser loading accessions, labels and synonyms and exposes them
as a collection of OWL::Simple::Class objects. 

This module wraps XML::Parser, which is a sequential event-driven XML parser that
can  potentially handle very large XML documents. The whole XML structure
is never loaded into memory completely, only the bits of interest.

In the constructor specify the owlfile to be loaded and two optional tags -
synonym_tag or definition_tag that define custom annotations in the ontology for 
synonyms and definitions respectively. Note both tags have to be fully 
specified exactly as in the OWL XML to be loaded, e.g. FULL_SYN for NCI Thesaurus 
or efo:alternative_term for EFO. 

=head2 METHODS

=over

=item class_count()

Number of classes loaded by the parser.

=item synonyms_count()

Number of synonyms loaded by the parser.

=item version()

Version of the ontology extracted from the owl:versionInfo.

=item class

Hash collection of all the OWL::Simple::Class objects

=back

=head1 AUTHOR

Tomasz Adamusiak <tomasz@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2011 European Bioinformatics Institute. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it 
under lGPLv3.

This software is provided "as is" without warranty of any kind.

=cut

package OWL::Simple::Parser;

use Moose 0.89;
use OWL::Simple::Class;
use XML::Parser 2.34;
use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( { level => $INFO, layout => '%-5p - %m%n' } );

our $VERSION = 1.01;

has 'owlfile'     => ( is => 'rw', isa => 'Str',     required => 1 );
has 'class'       => ( is => 'ro', isa => 'HashRef', default  => sub { {} } );
has 'class_count' => ( is => 'rw', isa => 'Int',     default  => 0 );
has 'synonyms_count' => ( is => 'rw', isa => 'Int', default => 0 );
has 'version' => ( is => 'rw', isa => 'Str' , default => '');
has 'synonym_tag' =>
  ( is => 'rw', isa => 'Str', default => 'efo:alternative_term' );
has 'definition_tag' =>
  ( is => 'rw', isa => 'Str', default => 'efo:definition' );
  

my $parser;
my $path = '';
my $class = OWL::Simple::Class->new();
my %restriction;

# Default constructor. Initializes the XML::Parser and sets appropriate handlers.

sub BUILD() {
	my $self = shift;
	$parser = new XML::Parser;
	$parser->setHandlers(
		Start => sub { $self->startElement(@_) },
		End   => sub { $self->endElement(@_) },
		Char  => sub { $self->characterData(@_) },
	);
}

# Increments internal counter of classes and synonyms parser respectively.

sub incr_classes() {
	my $self = shift;
	$self->class_count( $self->class_count + 1 );
}

sub incr_synonyms() {
	my $self = shift;
	$self->synonyms_count( $self->synonyms_count + 1 );
}

# Main function. Parser the owlfile using XML::Parser

sub parse() {
	my $self = shift;
	$parser->parsefile( $self->owlfile );
	INFO "LOADED "
	  . $self->class_count
	  . ' CLASSES AND '
	  . $self->synonyms_count
	  . ' SYNONYMS from '
	  . $self->owlfile;

	1;
}

# Handler executed by XML::Parser. Adds current element to $path.
# $path is used characterData() to determine whtether node text should be
# added to class.
#
# Initializes a new OWLClass object and stores it in $class. This is later
# populated by other handlers.

sub startElement() {
	my ( $self, $parseinst, $element, %attr ) = @_;
	DEBUG "->startElement  $self, $parseinst, $element";
	$path = $path . '/' . $element;    # add element to path
	if ( $path eq '/rdf:RDF/owl:Class' ) {
		$self->incr_classes();
		INFO(
			"Loaded " . $self->class_count . " classes from " . $self->owlfile )
		  if $self->class_count % 1000 == 0;
		$class = OWL::Simple::Class->new();
		$class->id( $attr{'rdf:about'} ) if defined $attr{'rdf:about'};
		$class->id( $attr{'rdf:ID'} )    if defined $attr{'rdf:ID'};
		WARN 'DUPLICATE RDF:ID & RDF:ABOUT IN ' . $attr{'rdf:about'}
		  if ( defined $attr{'rdf:id'} && defined $attr{'rdf:about'} );
	}

	# Two ways to match parents, either as rdf:resource attribute
	# on rdfs:subClassOf or rdf:about on nested rdfs:subClassOf/owl:Class
	elsif ( $path eq '/rdf:RDF/owl:Class/rdfs:subClassOf' ) {
		push @{ $class->subClassOf }, $attr{'rdf:resource'}
		  if defined $attr{'rdf:resource'};
	}
	elsif ( $path eq '/rdf:RDF/owl:Class/rdfs:subClassOf/owl:Class' ) {
		push @{ $class->subClassOf }, $attr{'rdf:about'}
		  if defined $attr{'rdf:about'};
	}

	# Here we try to match relations, e.g. part_of, derives_from, etc.
	elsif ( $element eq 'owl:Restriction' ) {
		$restriction{type}  = undef;
		$restriction{class} = [];
	}
	elsif ( $element eq 'owl:someValuesFrom' ) {
		push @{ $restriction{class} }, $attr{'rdf:resource'}
		  if defined $attr{'rdf:resource'};
		push @{ $restriction{class} }, $attr{'rdf:about'}
		  if defined $attr{'rdf:about'};
	}

	# Regex as properties can be transitive, etc.
	elsif ( $element =~ /owl:\w+Property$/ ) {
		$restriction{type} = $attr{'rdf:about'} if defined $attr{'rdf:about'};
		$restriction{type} = $attr{'rdf:resource'}
		  if defined $attr{'rdf:resource'};
	}
}

# Handler executed by XML::Parser when node text is processed.
#
# For rdfs:label stores the value into $class->label otherwise
# class->annotation() this is then subsequently pushed into
# respective synonyms or definitions table when the 
# endElement() event is fired
# NOTE characterData can be called multiple times, before
# the end tag

sub characterData {
	my ( $self, $parseinst, $data ) = @_;
	DEBUG "->characterData  $self, $parseinst, $data";

	# Get rdfs:label
	if ( $path eq '/rdf:RDF/owl:Class/rdfs:label' ) {
		$class->label(
			( defined $class->label() ? $class->label() : '' ) . $data );
	}

	# Get definition_citation or defintion
	elsif (
		$path =~ m!^/rdf:RDF/owl:Class/\w*:?\w*(definition|definition_citation)\w*!
		|| $path eq '/rdf:RDF/owl:Class/' . $self->definition_tag
		)
	{
		$class->annotation(
			( defined $class->annotation() ? $class->annotation() : '' )
			. $data );
	}
	
	# Get synonyms, either matching to anything with synonym or
	# alternative_term inside or custom tag from parameters
	elsif (
		   $path =~ m!^/rdf:RDF/owl:Class/\w*:?\w*(synonym|alternative_term)\w*!
		|| $path eq '/rdf:RDF/owl:Class/' . $self->synonym_tag )
	{
		$class->annotation(
			( defined $class->annotation() ? $class->annotation() : '' )
			. $data );
		WARN( "Unparsable synonym detected for " . $class->id )
		  unless defined $data;	
		
		# detecting closing tag inside, NCIt fix
		# FIXME this is probably no longer necessary
		# once the synonym is concatenated, but have not checked
		#if ( $data =~ m!</! ) {
		#	($data) = $data =~ m!>(.*?)</!;    # match to first entry
		#}

	}
	
	# Extract version information
	elsif ( $path eq '/rdf:RDF/owl:Ontology/owl:versionInfo' ){
		$self->version($self->version() . $data);
	}
}

# Handler executed by XML::Parser when the closing tag
# is encountered. For owl:Class it pushes it into the class hash as it was
# processed by characterData() already and the parser is ready to
# process a new owl:Class.
#
# Also strips the closing tag from $path.

sub endElement() {
	my ( $self, $parseinst, $element ) = @_;
	DEBUG "->endElement  $self, $parseinst, $element";

	# Reached end of class, add the class to hash
	if (   $path eq '/rdf:RDF/owl:Class'
		&& $class->id ne "http://www.w3.org/2002/07/owl#Thing" )
	{
		WARN 'Class ' . $class->id . ' possibly duplicated'
		  if defined $self->class->{ $class->id };
		my $classhash = $self->class;
		$classhash->{ $class->id } = $class;
	}

	# Reached end of the relationship tag, add to appropriate array
	# Currently supports only part_of, and even that poorly.
	# FIXME circular references
	elsif ( $element eq 'owl:Restriction' ) {
		WARN "UNDEFINED RESTRICTION " . $class->id
		  if not defined $restriction{type};
		if ( $restriction{type} =~ m!/part_of$! ) {
			for my $cls ( @{ $restriction{class} } ) {
				push @{ $class->part_of }, $cls;
			}
		}
	}

	# character data can be called multiple times
	# for a single element, so it's concatanated there
	# and saved here
	elsif ( $path =~ m!^/rdf:RDF/owl:Class/\w*:?\w*definition_citation$! ){
		push @{ $class->xrefs }, $class->annotation if $class->annotation() ne '';
	}
	elsif ( $path =~ m!^/rdf:RDF/owl:Class/\w*:?\w*definition$!
		|| $path eq '/rdf:RDF/owl:Class/' . $self->definition_tag ){
		push @{ $class->definitions }, $class->annotation if $class->annotation() ne '';
	}
	elsif ( $path =~ m!^/rdf:RDF/owl:Class/\w*:?\w*(synonym|alternative_term)\w*!
		|| $path eq '/rdf:RDF/owl:Class/' . $self->synonym_tag ){
		$self->incr_synonyms();
		push @{ $class->synonyms }, $class->annotation if $class->annotation() ne '';
	}
	print Dumper($class) unless defined $class->annotation;
	# clear temp annotation
	$class->annotation('');

	#remove end element from path
	$path =~ s!/$element$!!;
}

1;
