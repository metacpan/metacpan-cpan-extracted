# $Id: GoaParser.pm 2159 2013-02-20 Erick Antezana $
#
# Module  : GoaParser.pm
# Purpose : Parse GOA files
# License : Copyright (c) 2006-2015 by Vladimir Mironov. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# Contact : erick.antezana@gmail.com
#

package OBO::Parser::GoaParser;

use strict;
use warnings;
use Carp;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

use OBO::Core::Term;
use OBO::APO::GoaAssociation;
use OBO::APO::GoaAssociationSet;

# use Data::Dumper;

$Carp::Verbose = 0;
my $verbose = 0;

sub new {
	my $class = shift;
	my $self = {}; 
	
	bless ( $self, $class );
	return $self;
}

=head2 parse

 Usage - $GoaParser->parse ( $FH, $map )
 Returns - OBO::APO::GoaAssociationSet object
 Args - 
 	1. indirect filehandle to a GOA associations file
 	2. ref to a hash { UniProtAC => UniProtID } or { GO ID => GO term name } to filter by, optional
 Function - converts a GOA associations file into a OBO::APO::GoaAssociationSet object
 
=cut

sub parse {
	# TODO remove the option of filtering by GO map
	# TODO accomodate annotations including multiple taxa like: 'taxon:10090|taxon:10360', taxon:9606|taxon:44130
	my ( 
		$self, 
		$in_file_path, 
		$map # hash ref, either UP map or GO map, optional
	 ) = @_;
	
	open my $FH, '<', $in_file_path or croak "Can't open file '$in_file_path': $! ";
	my $goaAssocSet = OBO::APO::GoaAssociationSet->new ( );	
	# assumption: the map is not empty and no blank lines
	my $map_source;
	if ( $map ) {
		# identify the type of the map
		my @ids = keys %{ $map };
		if ( $ids[0] =~ /\AGO:\d{7}\z/xms ) {
			$map_source = 'GO';
		}
		elsif ( $ids[0] =~ /\A\w{6}\z/xms ){
			$map_source = 'UniProtKB';
		}
		else {
			carp "An illegal ID in the map! ";
		}
		print "Filtering by $map_source map\n" if $verbose;
	}
	# Populate the OBO::APO::GoaAssociationSet class with objects
	my $count_added =0;
	my $count_rejected =0;	
	while ( <$FH> ){		
		chomp;
		my @fields = split ( /\t/ );
		next if ( @fields != 15 );
		my $goaAssoc = load_data ( \@fields, $map, $map_source );
		$goaAssoc ? $count_added++ : $count_rejected++;
		$goaAssocSet->add_unique ( $goaAssoc ) if $goaAssoc;
	}# end of while $FH
	close $FH; 
	print "accepted associations: $count_added, rejected associations: $count_rejected\n" if $verbose;
	! $goaAssocSet->is_empty ( ) ? return $goaAssocSet : carp "The set is empty ! $! ";
}

=head2 work

 Usage - $GoaParser->work ( $ontology, $data, $up_map, $parent_protein_name ) # the last arg is optional
 Returns - a data structure with added proteins ( { NCBI_ID => {UP_AC => OBO::Core::Term object}} )
 Args - 
	 1. OBO::Core::Ontology object, 
	 2. OBO::APO::GoaAssociationSet object,
	 3. parent term name for proteins ( string ), # to link new proteins to, e.g. 'gene regulation protein'
 Function - adds GO associations ( and optionally protein terms ) to ontology
 
=cut

sub work {
	my ( 
		$self, 
		$onto, 
		$data, 
		$parent_protein_name,
	 ) = @_ ;
	croak "Not enough arguments! " if ! ( $onto and $data );
	
	my $parent_protein;
	my $taxon;
	if ( $parent_protein_name ) {
		$parent_protein = $onto->get_term_by_name ( $parent_protein_name ) || croak "No term for $parent_protein_name in ontology: $! ";
	}
		
	my $is_a = 'is_a';	
	my $participates_in = 'participates_in';
	my $located_in = 'located_in';
	my $has_function	= 'has_function';
	my $has_source = 'has_source';
	my @rel_types = ( $is_a, $participates_in, $located_in, $has_function, $has_source );
	foreach ( @rel_types ){
		croak "'$_' is not in ontology" unless ( $onto->{RELATIONSHIP_TYPES}->{$_} );
	}
	
	my %proteins; # { NCBI_ID => {UP_AC => OBO::Core::Term object}}
	my %go_terms; # { GO_id => OBO::Core::Term object }
	my %taxa;     # { NCBI_id => OBO::Core::Term object }
	
	foreach my $goaAssoc ( @{$data->{SET}} ){
		# get GO term
		my $go_id = $goaAssoc->go_id ( );
		next if ( $go_id eq 'GO:0008150' ); # remove associations with 'biological_process'
		my $go_term = $go_terms{$go_id};
		if ( ! $go_term ) { # $go_term is not yet in the hash
			$go_term = $onto->get_term_by_id ( $go_id );
			next if ( ! $go_term );
			$go_terms{$go_id} = $go_term;
		}
		
		# get taxon 
		# for multiple taxa in a single association: taxon:9606|taxon:44130
		$goaAssoc->taxon ( ) =~ /\Ataxon:(\d+)/xms;
		my $ncbi_id = $1 or carp "No NCBI id: $!";		
		my $taxon_id = "NCBI:$ncbi_id";
		my $taxon = $taxa{$ncbi_id};
		if ( ! $taxon ) {
			$taxon = $onto->get_term_by_id ( $taxon_id ) || carp "No taxon term for $taxon_id in ontology: $! ";
			next if ! $taxon;
			$taxa{$ncbi_id} = $taxon;
		}
		
		# get protein term
		my $obj_id = $goaAssoc->obj_id ( );
		my $db = $goaAssoc->obj_src ( );
		my $prot_id = "$db:$obj_id";
		my $protein = $proteins{$ncbi_id}{$obj_id};
		if ( ! $protein ) { # $protein is not yet in the hash
			$protein = $onto->get_term_by_id ( $prot_id );
			if ( ! $protein ) { # $protein is not yet in the ontolgy
				if ( $parent_protein_name ) { # testing whether new protein terms should be created
					$protein = OBO::Core::Term->new ( ); 
					$protein->id ( $prot_id );
					$onto->add_term ( $protein );				
					$onto->create_rel ( $protein, $has_source, $taxon );
					$onto->create_rel ( $protein, $is_a, $parent_protein );
				}
				else { 
					# the protein not in the ontology and no new terms should be created
					# normally should not happen
					carp "No protein term in the ontology for $prot_id"; 
					next;
				}
			}
			$proteins{$ncbi_id}{$obj_id} = $protein;
		}
			
			
		# create relations
		my $aspect = $goaAssoc->aspect ( );
		if ( $aspect eq 'F' ) {			
			$onto->create_rel ( $protein, $has_function, $go_term );
		}
		elsif ( $aspect eq 'C' ) {
			$onto->create_rel ( $protein, $located_in, $go_term );
#			$onto->create_rel ( $go_term, $location_of, $protein ); # inverse of 'located_in'
		} 
		elsif ( $aspect eq 'P' ) {
			$onto->create_rel ( $protein, $participates_in, $go_term );
#			$onto->create_rel ( $go_term, $has_participant, $protein ); # inverse of 'participates_in'			
		} 
		else {carp "An illegal GO aspect '$aspect'\n"}
	}
	return \%proteins;
}

sub load_data {
	my ( $fields, $map, $map_source ) = @_;
	my @fields = @{$fields}; 
	foreach ( @fields ) {
		$_ =~ s/^\s+//; 
		$_ =~ s/\s+$//;
	}
	if ( $map ) {
		if ( $map_source eq 'GO' ) {
			return 0 unless $map->{$fields[4]};
		}
		if ( $map_source eq 'UniProtKB' ) {
			return 0 unless $map->{$fields[1]};
		}
	}
	my $goaAssoc = OBO::APO::GoaAssociation->new ( );
	$goaAssoc->assc_id ( $. );
	$goaAssoc->obj_src ( $fields[0] );
	$goaAssoc->obj_id ( $fields[1] );
	$goaAssoc->obj_symb ( $fields[2] );
	$goaAssoc->qualifier ( $fields[3] );
	$goaAssoc->go_id ( $fields[4] ); 
	$goaAssoc->refer ( $fields[5] );
	$goaAssoc->evid_code ( $fields[6] );
	$goaAssoc->sup_ref ( $fields[7] );
	$goaAssoc->aspect ( $fields[8] );
	$goaAssoc->description ( $fields[9] );
	$goaAssoc->synonym ( $fields[10] );
	$goaAssoc->type ( $fields[11] );
	$goaAssoc->taxon ( $fields[12] );
	$goaAssoc->date ( $fields[13] );
	$goaAssoc->annot_src ( $fields[14] );
	return $goaAssoc;
}

1;

__END__

=head1 NAME

OBO::Parser::GoaParser - A GOA associations to OBO translator.

=head1 DESCRIPTION

Includes methods for adding information from GOA association files to ontologies
GOA associations files can be obtained from http://www.ebi.ac.uk/GOA/proteomes.html

The method 'parse' parses the GOA association file and optioanlly filters data by a map

The method 'work' incorporates OBJ_SRC, OBJ_ID, OBJ_SYMB, SYNONYM, DESCRIPTION into the input ontology, writes the ontology into an OBO file, writes map files.
This method assumes: 
- the ontology contains all and only the necessary GO terms. 
- the ontology contains the relationship types 'is_a', 'participates_in', 'has_participant'

=head1 AUTHOR

Vladimir Mironov E<lt>vladimir.n.mironov@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Vladimir Mironov. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut