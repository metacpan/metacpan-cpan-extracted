# $Id: NCBIParser.pm 2015-02-12 Erick Antezana $
#
# Module  : NCBIParser.pm
# Purpose : Parse NCBI files: names and nodes
# License : Copyright (c) 2006-2015 by ONTO-perl. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
###############################################################################
package OBO::Parser::NCBIParser;

use OBO::Core::Term;
use OBO::Parser::OBOParser;
use OBO::Core::Ontology;

use strict;
use warnings;
use Carp;

$Carp::Verbose = 0;

sub new {
	my $class = shift;
	my $self = {};	
	bless ( $self, $class );
	return $self;
}

=head2 parse

 Usage    : $ncbi_parser->parse ( $ncbi_nodes_path )
 Returns  : ref to a hash { child_id => parent_id }
 Args     : nodes.dmp path ( string )
 
 Usage    : $ncbi_parser->parse ( $ncbi_names_path, $name_type )
 Returns  : ref to a hash { ncbi_id => ncbi_name }
 Args     : 
            1. names.dmp path or nodes.dmp path, string 
            2. ncbi name type ( string, e.g. 'scientific name' ) if the first arg is names.dmp otherwise none				
 Function : parses the complete NCBI taxonomy
 
=cut

sub parse {
	my ( 
		$self, 
		$input_path, 
		$name_type # optional
	 ) = @_;
	 
	croak "Not enough arguments! " if ( @_ < 1 );
	
	open my $IN, '<', $input_path || croak "Can't open file '$input_path': $! ";
	my @in_lines = <$IN>;
	
	my %map;
	if ( $name_type ) { # parsing names.dmp
		# %map: ncbi_id => scientific_name
		foreach my $line ( @in_lines ) {
			my @fields = split /\t\|/, $line;
			if ( $fields[3] eq "\t$name_type" ) {
				my $key    = $fields[0];
				my $value  = substr $fields[1], 1;
				$map{$key} = $value;
			}
		}		
	} else { # parsing nodes.dmp
		# %map: child_id => parent_id
		foreach my $line ( @in_lines ) {
			my @fields = split (/\t\|/, $line);
			my $key    = $fields[0];
			my $value  = substr $fields[1], 1;
			$map{$key} = $value;
		}
	}
	close ( $IN );
	return \%map;
}

=head2 work

 Usage   : $NCBIParser->work ( $onto, $nodes, $names, $ncbi_ids )
 Returns : map of added terms { NCBI ID => OBO::Core::Term object }
 Args    :
           1. input ontology, OBO::Core::Ontology object
           2. ref to a hash { child_id => parent_id }
           3. ref to a hash { ncbi_id => scientific_name }
           4. parental ontology term for the root of the taxonomy, OBO::Core::Term object
           5. ref to a list of NCBI taxon ids ( \d+ )
 					
 Function : adds NCBI taxonomy to the input ontology for the specified taxa
 
=cut

sub work {
	my ( 
		$self,
		$ontology,
		$nodes,
		$names,
		$parent,
		$ncbi_ids,
	 ) = @_;
	
	my %selected_nodes = ( ); # taxon id => parent id
	my %selected_names = ( ); # taxon id => taxon name

	# the hashes %selected_nodes and %selected_names are being populated:
	foreach my $ncbi_id ( @{$ncbi_ids} ) {
		getParentsRecursively ( $ncbi_id, $nodes, $names, \%selected_nodes, \%selected_names );		
	}	
	my %map; # NCBI_ID=>taxon_term
	# the terms are created and added to the ontology and %map
	foreach my $ncbi_id ( keys %selected_nodes ){
		my $selected_name = $selected_names{$ncbi_id};
		my $taxon = OBO::Core::Term->new ( );
		$taxon->id ( "NCBI:$ncbi_id" );
		$taxon->name ( $selected_name );			
		$ontology->add_term ( $taxon );
		$map{$ncbi_id} = $taxon;
	} # the end of foreach	
	# Connect children to parents by 'is_a' relationships but not if the child is root ( cyclic is_a )
	foreach my $ncbi_id ( keys %selected_nodes ) {
		my $child = $map{$ncbi_id} or croak "No term for '$ncbi_id' in the map: $! ";
		my $parent = $map{$selected_nodes{$ncbi_id}} or croak "No term for '$selected_nodes{$ncbi_id}' in the map: $! ";
		$ontology->create_rel ( $child, 'is_a', $parent ) if ( $ncbi_id != 1 );		
	}
	my $root = $ontology->get_term_by_id ( 'NCBI:1' ) or croak "No term in the ontology for 'root': $!";
	$ontology->create_rel ( $root, 'is_a', $parent );
	return \%map;
}

########################################################################
#
# Subroutines
#
########################################################################

sub getParentsRecursively {
	
	caller eq __PACKAGE__ or croak;
	
	my ( $ncbi_id, $nodes, $names, $selected_nodes, $selected_names ) = @_;
	my $child_id    = $ncbi_id;
	my $parent_id   = ${$nodes}{$ncbi_id};
	my $child_name  = ${$names}{$ncbi_id};
	my $parent_name = ${$names}{$ncbi_id};
	
	$selected_nodes->{$child_id} = $parent_id;
	$selected_names->{$child_id} = $child_name;
	
	getParentsRecursively ( $parent_id, $nodes, $names, $selected_nodes, $selected_names ) if ( $child_id != 1 );
}

1;

__END__

=head1 NAME

OBO::Parser::NCBIParser - A NCBI taxonomy to OBO translator.

=head1 DESCRIPTION

This parser converts chosen parts of the NCBI taxonomy-tree into an OBO file. 
A taxon ID is given to the parser and the whole tree up to the root is 
reconstructed in the given OBO ontology, using scientific names.

The dump files ( nodes.dmp and names.dmp ) should be obtained from: 

	ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

TODO: include ranks and disjoints only in correlating ranks.

=head1 AUTHOR

Mikel Egana Aranguren and Vladimir Mironov

http://www.mikeleganaranguren.com, vladimir.n.mironov@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by Mikel Egana Aranguren

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut