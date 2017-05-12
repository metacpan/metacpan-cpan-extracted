# $Id: UniProtParser.pm 2015-02-12 Erick Antezana $
#
# Module : UniProtParser.pm
# Purpose : Parse UniProt files and add data to an ontology
# License : Copyright (c) 2006-2015 by ONTO-perl. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package OBO::Parser::UniProtParser;

use strict;
use warnings;
use Carp;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

use OBO::Core::Term;
use OBO::Core::Dbxref;
use SWISS::Entry;

$Carp::Verbose = 0;
my $verbose = 0;

sub new {
 my $class = $_[0];
 my $self = {};
 bless ( $self, $class );
 return $self;
}

=head2 parse

 Usage - $UniProtParser->parse ( $uniprot_file_path, $uniprot_map ) 
 Returns - ref to a hash { UniProtAC => SWISS::Entry object }
 Args - 
 	1. UniProt data file path, 
 	2. ref to a hash { UniProtAC => UniProtID } to filter by, optional
 Function - parses UniProt data file 
 
=cut

sub parse {
	my ( 
	$self,
	$uniprot_file_path,
	$up_map # optional
	 ) = @_;
	my %entries;
	my $count_accepted = 0;
	my $count_rejected =0;
	open my $FH, '<', $uniprot_file_path or croak "Cannot open file '$uniprot_file_path': $!";
	local $/ = "\n//\n";
	while ( <$FH> ) { 
		my $entry = SWISS::Entry->fromText ( $_ );
		my ( $accession ) = @{ $entry->ACs->{list} };
		if ( $up_map ) {
			if ( $up_map->{$accession} ) {
				$entries{$accession} = $entry;
				$count_accepted++;				
			}
			else {
				$count_rejected++;
			}
		}
		else {		
			$entries{$accession} = $entry;
			$count_accepted++;
		}
	}
	close $FH;
	print "Accepted proteins: $count_accepted, rejected proteins: $count_rejected\n" if $verbose;
	%entries ? return \%entries : croak "No data produced!";
}

=head2 work

 Usage - $UniProtParser->work ( $onto, $data, $parent_protein_name, $parent_gene_name )
 Returns - a hash with terms for added genes { NCBI GeneID => OBO::Core::Term object } 
 Args - 
 	1. OBO::Core::Ontology object, 
 	2. ref to a hash { UniProtAC => SWISS::Entry object }
	3. parent term name for proteins ( string ), # to link added modified proteins to, e.g. 'modified gene regulation protein'
	4. parent term name for genes ( string ), # to link added genes to, e.g. 'gene regulation gene'
 Function - adds gene and modified protein terms to the input ontology along with appropriate relations
 
=cut

sub work {
	# TODO Note: the relations to 'protein_modificaton' is now hard coded, an additional arg?
	my ( $self, 
		$onto, 
		$data, 
		$parent_protein_name, 
		$parent_gene_name 
	) = @_;
	
	my $no_gene_id =0;
	my $multiple_genes = 0;
	my $multiple_proteins = 0;
	my $no_GN = 0;
	my $multiple_GNs = 0;
	

	
	my @rel_types = ( 'is_a', 'has_source', 'encoded_by', 'codes_for', 'transformation_of', 'transforms_into', 'bearer_of' );
	foreach ( @rel_types ) {
		croak "Not a valid relationship type WITHIN the ontology: '$_'" unless ( $onto->{RELATIONSHIP_TYPES}{$_} );
	}
	my $parent_protein = $onto->get_term_by_name ( $parent_protein_name ) || croak "No term for '$parent_protein_name' in the ontology: $!";
	my $parent_gene = $onto->get_term_by_name ( $parent_gene_name ) || croak "No term for $parent_gene_name in the ontology: $!";
	my $protein_modification_id = 'MOD:00000';
	my $protein_modification = $onto->get_term_by_id ( $protein_modification_id )  || croak "No term for $protein_modification_id in the ontology: $!";
	
	my %genes; # gene_id=>gene_term
	my%new_genes; # gene_id=>gene_name
	
	foreach my $accession ( keys %{$data} ) {
		my $entry =  $data->{$accession};
		#######################################################################
		#
		# protein
		#
		#######################################################################
		my $protein_name = $entry->ID;
		my $oxs = $entry->OXs; # all NCBI ids
		my $taxon_id = $oxs->{'NCBI_TaxID'}{'list'}[0]{'text'}; # the primary ID
		my $taxon = $onto->get_term_by_id ( "NCBI:$taxon_id" );
		if ( ! $taxon ) {
			print "No taxon term for $taxon_id in ontology ($protein_name)\n" if $verbose;
			next;
		}
		my @acs  = @{ $entry->ACs->{list} };
		shift @acs; # shifting the primary AC from the array, the same as $accession
		# TODO synonyms for protein names
		my $prot_id = "UniProtKB:$accession";
		my $protein = $onto->get_term_by_id ( $prot_id );
		if ( ! $protein ) { # the proteins in the UP file and in the ontology are expected to be identical
			carp "No protein term in the ontology for '$protein_name'\n";
			next;
		}
		$protein->name ( $protein_name );
		$protein->alt_id ( map { "UniProtKB:$_" } @acs );
		
#		only the primary DE should be used 
		my $def_term = ${ $entry->DEs->{list} }[0]; # an object
		my $definition = $def_term->{text};
		$protein->def_as_string ( $definition.'.', "UniProtKB:$accession" );

		# add DB cross references to the protein, currently only EMBL
		# TODO consider other xrefs
		my $dbxrefs = $entry->DRs; # an object containing all DB cross-references
		my @pids = $dbxrefs->pids; # an array containing EMBL ids: ( gene_id, @protein_ids )
		# Note: a small fraction of EMBL entries has no protein ids !!!
		# TODO check how many protein ids could be present in @pids ( hopefully only relevant ones are there )
		foreach ( @pids ) {
			$protein->xref_set_as_string ( "[EMBL:$_]" );
		}
		
		####################################################################
		#
		# post-translationally modified derivatives of the protein
		#
		####################################################################
		if ( my @fts = @{$entry->FTs->{list}} ){ # an array of references to arrays corresponding to individual FT lines 
			foreach my $ft ( @fts ){
				# select only lines for modified residues
				$ft->[0] eq 'MOD_RES' ? 
				my ( $feature_key, $from_position, $to_position, $description, $qualifier, $FTId, $evidence_tag ) = @{$ft} :
				next; # go to the next FT line
				my ( $mod_residue, $tail, $mod_prot_id, $mod_prot_name, $mod_prot_comment, $mod_prot_def );

				if ( $description =~ /(\S+);\s(.*)/xms ) {
					# description contains the name of the modified residue separated by a semicolon from the rest
					 ( $mod_residue, $tail ) = ( $1, $2 );
					$mod_prot_comment = "$tail; $qualifier";
				}
				else {
					# $description contains only the name of the modified residue
					$mod_residue = $description;
					$mod_prot_comment = $qualifier;
 		}
 		$mod_prot_name = $protein_name.'-'.$mod_residue.'-'.$from_position;
 		$mod_prot_def = "Protein $protein_name with the residue $from_position substituted with $mod_residue.";
# 		$mod_prot_id = "$prot_id-$mod_residue-$from_position";
 		$mod_residue =~ s/\W/_/xmsg;
 		$mod_residue =~ tr/_//s; # replacing multiple '_' with a single one
 		$mod_prot_id = $prot_id . '_' . $mod_residue . '_' . $from_position;
# 		$mod_prot_id =~ s/\s+/_/xmsg;
# 		$mod_prot_id =~ s/-/_/xmsg;
# 		$mod_prot_id =~ s/\s|-|,|\(|\)/_/xmsg;
# 		$mod_prot_id =~ s/\W/_/xmsg;

				# create protein terms for modified proteins and add to ontology
				my $mod_prot = OBO::Core::Term->new ( );
				$mod_prot->name ( $mod_prot_name );
				$mod_prot->id ( $mod_prot_id );
				$mod_prot->def_as_string ( $mod_prot_def, "[UniProtKB:$accession]" );
				$mod_prot->xref_set_as_string ( "[UniProtKB:$accession]" );
				$mod_prot->comment ( $mod_prot_comment ); 
				$onto->add_term ( $mod_prot );
				$onto->create_rel ( $mod_prot, 'is_a', $parent_protein );
				$onto->create_rel ( $mod_prot, 'has_source', $taxon );
#				$onto->create_rel ( $mod_prot, 'transformation_of', $protein );
				$onto->create_rel ( $protein, 'transforms_into', $mod_prot );
				$onto->create_rel ( $mod_prot, 'bearer_of', $protein_modification );
			}
		}
 
 ######################################################################
 #
# genes
#
######################################################################
		# only GeneID and relations are added, the rest is taken from NCBI
		# gene ids
		my @gene_ids; # strings 'GeneID:\d+' - NCBI GeneID database
		# the number of proteins with multiple GeneIDs is ~0.2%
		# building a list of GeneIDs:
		foreach my $xref ( @{ $dbxrefs->{list} } ) {
#			${$xref}[0] eq 'GeneID' ? push @gene_ids, "${$xref}[0]:${$xref}[1]" : next;
			${$xref}[0] eq 'GeneID' ? push @gene_ids, "${$xref}[1]" : next;
		}
		my $geneid_count = @gene_ids;
		# if no GeneID no gene term created
		if ( $geneid_count == 0 ) {
			print "$protein_name has no GeneIDs\n" if $verbose;
			$no_gene_id++;
			next;
		}
		elsif ( $geneid_count > 1 ) {
			print "$protein_name has $geneid_count GeneIDs\n" if $verbose;
			$multiple_genes++;
		}
		
		foreach my  $gene_id ( @gene_ids ) { # $gene_id does not include a namespace
			my $gene = $genes{$taxon_id}{$gene_id};
#			$gene = $onto->get_term_by_id ( $gene_id ) if ! $gene; # is it necessary ?
			if ( $gene ) { # $gene has already been created for another protein
				print "Gene 'GeneID:$gene_id' codes for multiple proteins\n" if $verbose;
				$multiple_proteins++;
			}
			else {
				#creating new gene term
				$gene = OBO::Core::Term->new ( );
				$gene->id ( "GeneID:$gene_id" );
				$onto->add_term ( $gene );	
				$onto->create_rel ( $gene, 'is_a', $parent_gene );			
				$onto->create_rel ( $gene, 'has_source', $taxon );				

			} # end of new gene
			$onto->create_rel ( $protein, 'encoded_by', $gene );
			$onto->create_rel ( $gene, 'codes_for', $protein ); # inverse of 'encoded_by'			
			# gene xref to UniProt
			$gene->xref_set_as_string ( "UniProtKB:$accession" );
			$genes{$taxon_id}{$gene_id} = $gene

		} # end of foreach gene_id
		
		
		# gene names
		# the number of gene groups often is higher the the number of GeneIDs
		# currently is used only for counting, gene names are taken from NCBI
		my @gene_groups = @{ $entry->GNs->{list} };
		my $gene_group_count = @gene_groups;
		if ( $gene_group_count != 1 ) {
			print "$protein_name has  $gene_group_count GNs\n" if $verbose;
			$gene_group_count == 0 ? $no_GN++ : $multiple_GNs++;
		}
		

	} # foreach $entry
	print "$no_gene_id proteins without GeneIDs, $multiple_genes proteins with multiple GeneIDs;\n$no_GN proteins without GN, $multiple_GNs proteins with multiple GNs;\n $multiple_proteins genes with multiple proteins\n" if $verbose;
	return \%genes;
}

1;

__END__


=head1 NAME

OBO::Parser::UniProtParser - A UniProt to OBO translator.

=head1 DESCRIPTION

Includes methods for adding information from UniProt files to ontologies

UniProt files can be obtained from:
	ftp://ftp.expasy.org/databases/uniprot/knowledgebase/

The method 'parse' parses imput UniProt file and filters the data by map (optioanally) 
The method 'work' transfers selected data from the ouput parse() into the input ontology. 
This method assumes: 
- the input ontology contains the NCBI taxonomy. 
- the input ontology contains the relationship types 'is_a', 'encoded_by', 
 'codes_for', 'has_source', 'tranformation_of', 'source_of'

=head1 AUTHOR

Vladimir Mironov E<lt>vladimir.n.mironov@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright ( C ) 2006 by Vladimir Mironov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut