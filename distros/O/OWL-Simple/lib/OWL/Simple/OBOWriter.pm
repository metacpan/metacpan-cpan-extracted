#!/usr/bin/perl

=head1 NAME

OWL::Simple::OBOWriter - a simple OWL to OBO converter

=head1 SYNOPSIS

	use OWL::Simple::Parser;
	use OWL::Simple::OBOWriter;
	
	# load Experimental Factor Ontology
	my $parser = OWL::Simple::Parser->new( owlfile => 'efo.owl' );
	my $writer = OWL::Simple::OBOWriter->new( owlparser => $parser );
	
	# convert the ontology to OBO and save in current directory
	$writer->write();

=head1 DESCRIPTION

A simple OWL to OBO converter.

In the constructor you only need to pass an OWL::Simple::Parser object.
All other arguments are optional:

=over

=item  outputfile

Defaults to simple-owl-obowriter-output.obo.

=item version

Version of the ontology to record in the OBO file.

=item namespace

Specifies the default namespace

=back

=head2 METHODS

=over

=item write()

Converts and writes the file in current directory

=back

=head1 AUTHOR

Tomasz Adamusiak <tomasz@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 European Bioinformatics Institute. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it 
under GPLv3.

This software is provided "as is" without warranty of any kind.

=cut

package OWL::Simple::OBOWriter;

use Moose 0.89;
use OWL::Simple::Parser 0.10;
use Log::Log4perl qw(:easy);
use XML::Parser 2.34;
Log::Log4perl->easy_init( { level => $INFO, layout => '%-5p - %m%n' } );

our $VERSION = 0.06;

has 'owlparser' => ( is => 'rw', isa => 'OWL::Simple::Parser', required => 1 );
has 'outputfile' =>
  ( is => 'rw', isa => 'Str', default => 'simple-owl-obowriter-output.obo' );
has 'version'   => ( is => 'rw', isa => 'Str', required => 0 );
has 'namespace' => ( is => 'rw', isa => 'Str', required => 0 );

sub BUILD() {
	my $self = shift;
	$self->parse_owl();
}

sub write() {
	my $self = shift;

	$self->write_header();

	$self->write_terms();
	
	$self->write_typedefs();

	INFO 'Converted ' . $self->owlparser->owlfile . ' to ' . $self->outputfile;

	1;
}

# Writes OBO header

sub write_header() {
	my $self = shift;
	my $parser = $self->owlparser;
	
	open my $fh, '>:utf8', $self->outputfile or LOGCROAK $!;
	{
		local $\ = "\n";    # do the magic of println
		print $fh 'format-version: 1.2';
		if (defined $self->version){
			print $fh "data-version: " . $self->version;	
		} else {
			print $fh "data-version: " . $parser->version;
		}
		print $fh "date: " . datetime();
		print $fh "auto-generated-by: OWL::Simple::OBOWriter $VERSION";
		print $fh "default-namespace: " . $self->namespace
		  if defined $self->namespace;

		#print $fh "idspace: efo http://www.ebi.ac.uk/efo";
	}
	close $fh;
	DEBUG "WROTE HEADER";
}

# Writes OBO footer containing Typedef stanzas

sub write_typedefs() {
	my $self = shift;
	open my $fh, '>>:utf8', $self->outputfile or LOGCROAK $!;
	{
		local $\ = "\n";    # do the magic of println
		print $fh q{};
		print $fh '[Typedef]';    # term stanza
		print $fh 'id: part_of';
		print $fh 'name: part_of';
	}
	close $fh;
	DEBUG "WROTE TYPEDEFS";
}

# Initiates the OWL parser.

sub parse_owl() {
	my $self   = shift;
	my $parser = $self->owlparser;
	$parser->parse();
}

sub cleanup_id_for_OLS($) {
	my $s = shift;
	$s =~ s!http://www.ebi.ac.uk/efo/!!;
	$s =~ s!http://purl.org/obo/owl/.*#!!;
	$s =~ s!http://purl.obolibrary.org/obo/!!;
	$s =~ s!\Qhttp://www.ebi.ac.uk/chebi/searchId.do;?chebiId=\E!!;
	$s =~ s!\Qhttp://www.ebi.ac.uk/chebi/searchId.do?chebiId=\E!!;
	$s =~ s!http://www.ifomis.org/bfo/.*/snap#!snap:!;
	$s =~ s!http://www.ifomis.org/bfo/.*/span#!span:!;
	$s =~ s!\Qhttp://www.geneontology.org/formats/oboInOwl#\E!oboInOwl:!;
	# required for ensembl consumption
	$s =~ s!_!:!g;
	return $s;
}

# Writes out owl classes.
sub write_terms($) {
	my $self   = shift;
	my $parser = $self->owlparser;
	open my $fh, '>>:utf8', $self->outputfile or LOGCROAK $!;

	for my $key ( sort ( keys %{ $parser->class } ) ) {
		my $term = $parser->class->{$key};
		$key = cleanup_id_for_OLS($key);

		# there's no obsolete parent in OBO
		next if $key eq 'oboInOwl:ObsoleteClass';
		
		# skip unlaballed artefacts
		unless (defined $term->label){
			WARN "SKIPPING $key DUE TO UNDEFINED LABEL";
			next;
		}
		# process stanza
		local $\ = "\n";    # do the magic of println
		print $fh q{};
		print $fh '[Term]';    
		print $fh 'id: ' . $key . ' ! ' . $term->label;
		print $fh 'name: ' . $term->label;

		# write definition (there can be only 0 or 1)
		print $fh 'def: "' . escape_chars( $term->definitions->[0] ) . '" []'
		  if defined $term->definitions->[0];

		# write synonyms
		for my $synonym ( @{ $term->synonyms } ) {
			print $fh 'synonym: "' . escape_chars($synonym) . '" EXACT []';
		}

		# write xrefs
		for my $xref ( @{ $term->xrefs } ) {
			$xref = cleanup_id_for_OLS( escape_chars($xref) );
			print $fh 'xref: ' . $xref;
		}

		# write isa_s
		for my $isa ( @{ $term->subClassOf } ) {
			$isa = cleanup_id_for_OLS($isa);
			if ( $isa eq 'http://www.w3.org/2002/07/owl#Thing' ) {
				INFO 'Skipping owl#Thing on ' . $key . ' ! ' . $term->label;;
			}
			elsif ( $isa eq 'oboInOwl:ObsoleteClass' ) {
				# should not have any other relations
				WARN 'obsolete term ' . $key . ' with multiple is_a relations'
				  if scalar @{ $term->subClassOf } > 1;
				print $fh 'is_obsolete: true';
				last;
			}
			else {
				print $fh 'is_a: ' . $isa;
			}

		}

		# write relationships
		for my $part_of ( @{ $term->part_of } ) {
			$part_of = cleanup_id_for_OLS($part_of);
			# FIXME need to fix circular references
			# FIXME warn if exists on an obsolete term
			# print $fh 'relationship: part_of ' . $part_of;
		}
	}

	close $fh;
	DEBUG "WROTE TERMS";
}

# Supplies a date in an OBO required format.

sub datetime() {
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
	  localtime(time);
	return sprintf "%02d:%02d:%4d %02d:%02d", $mday, $mon + 1, $year + 1900,
	  $hour, $min;
}

# Escape chars in synonyms and definitions.

sub escape_chars($) {
	my $s = shift;
	$s =~ s/\n//g;
	$s =~ s!\\!\\\\!g;
	$s =~ s/\[/\\\[/g;
	$s =~ s/\]/\\\]/g;

	# OBO edit seems to complain about these
	#$s =~ s/\)/\\\)/g;
	#$s =~ s/\(/\\\(/g;
	$s =~ s/\{/\\\{/g;
	$s =~ s/\}/\\\}/g;
	$s =~ s/\t/ /g;
	$s =~ s!,! !;
	$s =~ s/"//g;
	return $s;
}

1;
