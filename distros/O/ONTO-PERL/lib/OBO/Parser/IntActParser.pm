# $Id: IntActParser.pm 2015-02-12 Erick Antezana $
#
# Module : IntActParser.pm
# Purpose : Parse IntAct files and transfer the data to an ontology
# License : Copyright (c) 2006-2015 by ONTO-perl. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package OBO::Parser::IntActParser;

use strict;
use warnings;
use Carp;

use OBO::Core::Term;
use XML::XPath;

$Carp::Verbose = 0;
my $verbose = 0;

sub new {
	my $class = shift;
	my $self = {};
	bless (  $self, $class  );
	return $self;
}

=head2 parse

 Usage - $intact_parser->parse  (  $intact_files, $map  )
 Returns - data structure  ( hash reference )
 Args - 
	 1. [ IntAct data file paths  ( fully qualified )]  (  array reference )
	 2. { UniProtKB accession => UniProtKB id  ( strings )}  ( hash reference )
	 3. { UniProtKB accession => UniProtKB id  ( strings )}  ( hash reference ), optional
 Function - parses IntAct data file and optionally filters it by the map
 
=cut

sub parse {
	my  ( 
		$self, 
		$intact_files, # ref to a list of fully qualified paths
		$long_map, # complete UniProt map, to get rid of secondary UniPriot ACs
		$short_map # { UP AC => UP ID }  ( optional ), map to filter by
	 ) = @_;
	croak "No IntAct files to parse!\n" if  (  ! $intact_files  );
	my %data;
	my $count_accepted = 0;
	my $count_rejected =0;
	foreach my $file_path  (  @{$intact_files} ) {
		# xpath is very sensitive to extra spaces in double quoted strings in find() !!!!
		my $xpath = XML::XPath->new (  filename => $file_path  ) or croak "Failed to parse file $file_path";
		my $int_set = $xpath->find ( "/entrySet/entry/interactionList/interaction" );
		foreach my $interaction  (  $int_set->get_nodelist (  )  ) {
			# Note: internal IntAct IDs for participants and interactors are different !!!
			my $interaction_id = $interaction->find (  "\@id", $interaction  )->string_value (  ); # IntAct internal id
			my $participants = $xpath->find ( "/entrySet/entry/interactionList/interaction[\@id = $interaction_id]/participantList/participant" );
			my @participants = $participants->get_nodelist (  );
			
			# tagging interections for including in $data
			my $map_hit = 0;
			# if a map is provided
			if  (  $short_map  ) {
				foreach my $participant  (  @participants  ) {
					my $interactor_id = $participant->find (  "interactorRef/text()", $participant  )->string_value (  ); # IntAct internal ID
					# UniProt AC		
					my $protein_id = $xpath->find ( "/entrySet/entry/interactorList/interactor[\@id = $interactor_id]/xref/primaryRef/\@id" )->string_value (  );
					# searching for the first occurence of a core protein
					if  (  $short_map->{$protein_id}  ) {
						$map_hit++;
						last;
					}
				}
			}
			# if there is no map take all interactions
			else { 
				$map_hit = 1;
			}		
			$map_hit ? $count_accepted++ : $count_rejected++;
			
			# filling up $data
			if  (  $map_hit  ) {
				my $interaction_xref = $interaction->find (  "xref/primaryRef/\@id", $interaction  )->string_value (  ); # EBI ID
				$interaction_xref =~s/-/:/; # format change			
				$data{$interaction_xref}{'interactionName'} = $interaction->find (  "names/shortLabel/text()", $interaction  )->string_value (  ); # interaction name
				$data{$interaction_xref}{'interactionFullName'} = $interaction->find (  "names/fullName/text()", $interaction  )->string_value (  ); # interaction full name
				$data{$interaction_xref}{'interactionTypeId'} = $interaction->find (  "interactionType/xref/primaryRef/\@id", $interaction  )->string_value (  ); # MI id
				foreach my $participant  (  @participants  ) {	
					# internal IntAct interactor ID used for getting taxon ID and protein ID:
					my $interactor_id = $participant->find (  "interactorRef/text()", $participant  )->string_value (  );			
					my $ncbi_id = $xpath->find ( "/entrySet/entry/interactorList/interactor[\@id = $interactor_id]/organism/\@ncbiTaxId" )->string_value (  );
					# protein xref, tyically UniProt accession, any others??? TODO
					# for now ingnores any other sources, as well as secondary UniProt ACs
					my $protein_id = $xpath->find ( "/entrySet/entry/interactorList/interactor[\@id = $interactor_id]/xref/primaryRef/\@id" )->string_value (  );				
					my $role = $participant->find ( "experimentalRoleList/experimentalRole/names/shortLabel/text()", $participant )->string_value ( ); # experimental role			
					$long_map->{$protein_id} ?
					$data{$interaction_xref}{'participants'}{$ncbi_id}{$protein_id} = $role :
					next;
				} # end of foreach participant			
			}
		} # end of foreach interaction
	} # end of foreach file 
	print "Accepted interactions: $count_accepted, rejected interactions: $count_rejected\n" if $verbose;
	%data ? return \%data : croak "No data produced!";
}

=head2 work

 Usage - $intact_parser->work ( $ontology, $data, $parent_protein_name )
 Returns - { NCBI ID => { UP AC => OBO::Core::Term object }} ( data structure with all the proteins in the interactions )
 Args - 
	1. OBO::Core::Ontology object, 
	2. data structure from parse ( )
	3. parent term name for proteins ( string ) # to link new proteins to, e.g. 'cell cycle protein'
 Function - adds to the input ontology OBO::Core::Term objects along with appropriate relations for interactions and proteins from IntAct data
 
=cut

sub work {
	my ( 
		$self, 
		$onto, 
		$data, 
		$parent_protein_name 
	 ) = @_;
	my @rel_types = ( 'is_a', 'participates_in', 'has_participant', 'has_source' );
	foreach my $rel_type ( @rel_types ) {
		croak "Not a valid relationship type '$rel_type' !" unless ( $onto->{RELATIONSHIP_TYPES}->{$rel_type} );
	}
	# hashes to collect terms
	my %taxa; # { NCBI ID => OBO::Core::Term object }
	my %interaction_types; # { MI ID => OBO::Core::Term object }
	my %proteins; # { NCBI ID => { UP AC => OBO::Core::Term object }}
	my %role_rel_types; # not used yet
	
	my $parent_protein = $onto->get_term_by_name  ( $parent_protein_name ) || croak "No term for $parent_protein_name in ontology: $!";
	foreach my $interaction_id ( keys %{$data} ) { # EBI id
		my $interaction_type_id = $data->{$interaction_id}{'interactionTypeId'}; # MI id 
		my $interaction_type_term = $interaction_types{$interaction_type_id};
		if ( ! $interaction_type_term ) {
			$interaction_type_term = $onto->get_term_by_id ( $interaction_type_id ) or next;
		}
		my $interaction_name = $data->{$interaction_id}{'interactionName'};
		my $interaction_type_name = $interaction_type_term->name ( );
		my $interaction_full_name = $data->{$interaction_id}{'interactionFullName'};
		# interaction terms
		my $new_interaction = OBO::Core::Term->new ( );
		$new_interaction->id ( "$interaction_id" );
		$new_interaction->name ( "$interaction_name $interaction_type_name" );
		$new_interaction->def_as_string ( "$interaction_full_name", "[$interaction_id]" );
		$onto->add_term ( $new_interaction );
		$onto->create_rel ( $new_interaction, 'is_a', $interaction_type_term );
		# protein terms
		foreach my $ncbi_id ( keys %{$data->{$interaction_id}{'participants'}} ) {
			my $taxon = $taxa{$ncbi_id};
			if ( ! $taxon ) {
				my $taxon_id = "NCBI:$ncbi_id";
				# external proteins are not accepted
				$taxon = $onto->get_term_by_id ( $taxon_id ) or next;
			}
			foreach my $up_ac ( keys %{$data->{$interaction_id}{'participants'}{$ncbi_id}} ) {
				my $protein = $proteins{$ncbi_id}{$up_ac};
				if ( ! $protein ) {
					my $protein_id = "UniProtKB:$up_ac";
					$protein = $onto->get_term_by_id ( $protein_id );
					if ( ! $protein ) {
						$protein = OBO::Core::Term->new ( );
						$protein->id ( $protein_id );
						$onto->add_term ( $protein );
						$onto->create_rel ( $protein, 'is_a', $parent_protein );
						$onto->create_rel ( $protein, 'has_source', $taxon ) if $taxon;						
					}
					$proteins{$ncbi_id}{$up_ac} = $protein; # the protein was not yet in the hash
				}
				# TODO incorporate the roles
#				my $role = $data->{$interaction_id}{'participants'}{$ncbi_id}{$up_ac};
#				$role =~s/\s/_/g; # removing spaces
#				my $role_rel_name = "participates_in_as_$role";
				
#				$onto->create_rel ( $protein, 'participates_in', $new_interaction );
				$onto->create_rel ( $new_interaction, 'has_participant', $protein );					
			} # end of foreach protein
		} # end of foreach taxon
	} # end of foreach interaction
	return \%proteins;
}	

1;

__END__

=head1 NAME

OBO::Parser::IntActParser - An IntAct to OBO parser/filter.

=head1 DESCRIPTION

A parser for IntAct-to-OBO conversion. The conversion is filtered 
according to the proteins already existing in the input ontology. 

=head1 AUTHOR

Vladimir Mironov E<lt>vladimir.n.mironov@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright  ( C ) 2006 by Vladimir Mironov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut