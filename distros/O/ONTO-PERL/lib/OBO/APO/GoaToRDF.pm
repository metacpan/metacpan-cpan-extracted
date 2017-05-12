# $Id: GoaToRDF.pm 2194 2008-08-07 12:46:25Z Erick Antezana $
#
# Module  : GoaToRDF.pm
# Purpose : A GOA associations to RDF converter
# License : Copyright (c) 2006-2015 by ONTO-perl. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : CCO <ccofriends@psb.ugent.be>
#
package OBO::APO::GoaToRDF; 

=head1 NAME

OBO::APO::GoaToRDF - A GOA associations to RDF converter.

=head1 DESCRIPTION

Converts a GOA association file to a RDF graph. The RDF graph is very simple, 
containing a node for each line from the association file (called GOA_ASSOC_n), 
and several triples for the fields (e.g. obj_symb).

GOA associations files can be obtained from http://www.ebi.ac.uk/GOA/proteomes.html

The method 'work' gets an assoc file path and a file handler for the RDF graph. 

=head1 AUTHOR

Mikel Egana Aranguren
mikel.egana.aranguren@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 by Mikel Egana Aranguren

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

use OBO::Parser::GoaParser;
use strict;
use warnings;
use Carp;

sub new {
	my $class                   = shift;
	my $self                    = {}; 
	
	bless ($self, $class);
	return $self;
}

=head2 work

  Usage    - $GoaToRDF->workwork($input_file, $file_handle, $base, $ns);
  Returns  - RDF file handler
  Args     - 1. Full path to the GOA file
  			 2. File handle for writing RDF
  			 3. base URI (e.g. 'http://www.semantic-systems-biology.org/')
  			 4. name space (e.g. 'SSB')
  Function - converts an assoc. file to an RDF graph
  
=cut

sub work {
	my $self = shift;

	# Get the arguments
	# my ($file_handle, $path_to_assoc_file) = @_;
	my ( $path_to_assoc_file, $file_handle, $base, $namespace ) = @_; #vlmir	
	#
	# Hard-coded evidence codes
	#
	#TODO the list is not complete anymore #vlmir
	my %evidence_code_by_id = (
		'IEA'	 => 'ECO_0000203',
		'ND'	 => 'ECO_0000035',
		'IDA'	 => 'ECO_0000002',
		'IPI'	 => 'ECO_0000021',
		'TAS'	 => 'ECO_0000033',
		'NAS'	 => 'ECO_0000034',
		'ISS'	 => 'ECO_0000041',
		'IMP'	 => 'ECO_0000015',
		'IC'	 => 'ECO_0000001',
		'IGI'	 => 'ECO_0000011',
		'IEP'	 => 'ECO_0000008',
		'RCA'	 => 'ECO_0000053',
		'IGC'	 => 'ECO_0000177',
		'EXP'	 => 'ECO_0000006',
		'IBA'	 => 'ECO_0000318',
		'IRD'	 => 'ECO_0000321',
		'IKR'	 => 'ECO_0000320',
		'ISO'	 => 'ECO_0000201'
	);
	
	#
	# Aspects
	#
	my %aspect = (
		'P'	 => 'participates_in',
		'C'	 => 'located_in',
		'F'	 => 'has_function'
	);
	
	# For the ID
	$path_to_assoc_file =~ /.*\/(.*)/; # get what is after the slash in the path...
	my $f_name = $1;
	(my $prefix_id = $f_name) =~ s/\.goa//;
	$prefix_id =~ s/\./_/g;

	# TODO: set all the NS and URI via arguments
	# my $default_URL = "http://www.semantic-systems-biology.org/"; 
	my $default_URL = $base; #vlmir
	my $NS = $namespace;#vlmir
	my $ns = lc ($NS);
	my $rdf_subnamespace = "assoc";

	# Preamble of RDF file
	print $file_handle "<?xml version=\"1.0\"?>\n";
	print $file_handle "<rdf:RDF\n";
	print $file_handle "\txmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n";
	print $file_handle "\txmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n";
	print $file_handle "\txmlns:".$ns."=\"".$default_URL.$NS."#\">\n";
	
	my $GoaParser = OBO::Parser::GoaParser->new();
	my $goaAssocSet = $GoaParser->parse($path_to_assoc_file);
	
	my %prot_duplicated; # to add only one copy of the protein
	my $buffer;
	
	my $prot_space = "protein";
	my $previous_protein = "";
	# Chunk of RDF file	
	foreach ($goaAssocSet->get_set()) {
		my %assoc           = %{$_};
		my $current_protein = $assoc{OBJ_ID};
		
		if ($previous_protein && $current_protein ne $previous_protein) { # flush the buffer
			$buffer .=  "\t</".$ns.":".$prot_space.">\n";
			print $file_handle $buffer;
			$buffer = ""; # init
		}
		
		#
		# the protein: (this should come from uniprot.rdf)
		#
		my $triple_prefix_id_assoc_id = "triple_".$prefix_id."_".$assoc{ASSC_ID};
		if (!$prot_duplicated{$current_protein}) {
			$buffer .= "\t<".$ns.":".$prot_space." rdf:about=\"#".$current_protein."\">\n";
			$buffer .=  "\t\t<rdfs:label xml:lang=\"en\">".&char_hex_http($assoc{OBJ_SYMB})."</rdfs:label>\n";
			$buffer .=  "\t\t<".$ns.":name xml:lang=\"en\">".&char_hex_http($assoc{OBJ_SYMB})."</".$ns.":name>\n";
			$buffer .=  "\t\t<".$ns.":annot_src>".&char_hex_http($assoc{ANNOT_SRC})."</".$ns.":annot_src>\n";
			my $t = $assoc{TAXON};
			$t =~ s/taxon:/NCBI_/; # clean it
			$buffer .=  "\t\t<".$ns.":taxon>".$t."</".$ns.":taxon>\n";
			$buffer .=  "\t\t<".$ns.":has_source rdf:resource=\"#".$t."\"/>\n";
			$buffer .=  "\t\t<".$ns.":type>".&char_hex_http($assoc{TYPE})."</".$ns.":type>\n";
			$buffer .=  "\t\t<".$ns.":description>".&char_hex_http($assoc{DESCRIPTION})."</".$ns.":description>\n";
			$buffer .=  "\t\t<".$ns.":obj_src>".&char_hex_http($assoc{OBJ_SRC})."</".$ns.":obj_src>\n\n";
			
			$prot_duplicated{$current_protein} = 1;
			$previous_protein = $current_protein; 
		}
		
		my $goa_ns_prefix_id_assoc_id = "#GOA_".$prefix_id."_".$assoc{ASSC_ID};
		#
		# ASSOC:
		#
		print $file_handle "\t<".$ns.":".$rdf_subnamespace." rdf:about=\"".$goa_ns_prefix_id_assoc_id."\">\n";
		print $file_handle "\t\t<".$ns.":date>".$assoc{DATE}."</".$ns.":date>\n";
		print $file_handle "\t\t<".$ns.":refer>".&char_hex_http($assoc{REFER})."</".$ns.":refer>\n";
		print $file_handle "\t\t<".$ns.":sup_ref>".&char_hex_http($assoc{SUP_REF})."</".$ns.":sup_ref>\n";
		print $file_handle "\t\t<".$ns.":has_evidence rdf:resource=\"#".$evidence_code_by_id{$assoc{EVID_CODE}}."\"/>\n";
		print $file_handle "\t</".$ns.":".$rdf_subnamespace.">\n";
		
		#
		# TRIPLE (version 1):
		#
#		print $file_handle "\t<rdf:Statement rdf:about=\"".$triple_prefix_id_assoc_id."\">\n";
#		print $file_handle "\t\t<rdf:subject rdf:resource=\"#".$assoc{OBJ_ID}."\"/>\n";
#		print $file_handle "\t\t<rdf:predicate rdf:resource=\"#".$aspect{$assoc{ASPECT}}."\"/>\n";
#		print $file_handle "\t\t<rdf:object rdf:resource=\"#".&char_hex_http($assoc{"GO_ID"})."\"/>\n\n";
#
#		print $file_handle "\t\t<".$ns.":supported_by rdf:resource=\"".$goa_ns_prefix_id_assoc_id."\"/>\n";
#		print $file_handle "\t</rdf:Statement>\n";
		
		#
		# TRIPLE (version 2):
		#
		print $file_handle "\t<rdf:Description rdf:about=\"#".$triple_prefix_id_assoc_id."\">\n";
		print $file_handle "\t\t<".$ns.":supported_by rdf:resource=\"".$goa_ns_prefix_id_assoc_id."\"/>\n";
		print $file_handle "\t</rdf:Description>\n";
		
		#
		# flushing?
		#
		if ($current_protein eq $previous_protein) {
			$buffer .=  "\t\t<".$ns.":".$aspect{$assoc{ASPECT}}." rdf:ID=\"".$triple_prefix_id_assoc_id."\" rdf:resource=\"#".&char_hex_http($assoc{"GO_ID"})."\"/>\n";
		}
		$previous_protein = $current_protein;
	}
	
	#
	# LAST FLUSH
	#
	if ($previous_protein) {
		$buffer .=  "\t</".$ns.":".$prot_space.">\n";
		print $file_handle $buffer;
	}

	print $file_handle "</rdf:RDF>\n\n";
	print $file_handle "<!--\nGenerated with ONTO-PERL: ".$0.", ".__date()."\n-->";

	return $file_handle;
}

sub __date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $result = sprintf "%02d:%02d:%4d %02d:%02d", $mday,$mon+1,$year+1900,$hour,$min; # e.g. 11:05:2008 12:52
}

=head2 char_hex_http

  Usage    - $ontology->char_hex_http($seq)
  Returns  - the sequence with the hexadecimal representation for the http special characters
  Args     - the sequence of characters
  Function - Transforms a http character to its equivalent one in hexadecimal. E.g. : -> %3A
  
=cut


sub char_hex_http { 
	$_[0] =~ s/:/_/g; # originally:  $_[0] =~ s/:/%3A/g; but changed to get eh GO IDs properly: GO_0000001
	$_[0] =~ s/;/%3B/g;
	$_[0] =~ s/</%3C/g;
	$_[0] =~ s/=/%3D/g;
	$_[0] =~ s/>/%3E/g;
	$_[0] =~ s/\?/%3F/g;
	
#number sign                    #     23   &#035; --> #   &num;      --> &num;
#dollar sign                    $     24   &#036; --> $   &dollar;   --> &dollar;
#percent sign                   %     25   &#037; --> %   &percnt;   --> &percnt;

	$_[0] =~ s/\//%2F/g;
	$_[0] =~ s/&/%26/g;

	return $_[0];
}
1;
