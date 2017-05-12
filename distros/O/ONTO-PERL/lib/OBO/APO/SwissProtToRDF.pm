package OBO::APO::SwissProtToRDF; 

=head1 NAME

OBO::APO::SwissProtToRDF - A SwissProt to RDF converter.

=head1 DESCRIPTION

Converts SwissProt files to a RDF graph. 

NCBI taxonomy dump files files can be obtained from:

ftp://ftp.expasy.org/databases/uniprot/current_release/knowledgebase/taxonomic_divisions

e.g. uniprot_sprot_human.dat.gz

and/or

ftp://ftp.expasy.org/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;
use warnings;
use Carp;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

use SWISS::Entry;
use Data::Dumper;

sub new {
	my $class                   = shift;
	my $self                    = {}; 
	
	bless ($self, $class);
	return $self;
}

=head2 work

  Usage    - $SwissProtToRDF->work($uniprot_file)
  Returns  - RDF file handler
  Args     - The paths to the SwissProt file and a file handler for the new RDF file
  Function - Converts SwissProt entries from a file to an RDF graph.
  
=cut
#vlmir
# Argumenents
# 1. Full path to the UniProt file
# 2. File handle for writing RDF
# 3. base URI (e.g. 'http://www.semantic-systems-biology.org/')
# 4. name space (e.g. 'SSB')
#vlmir

sub work() {
	
	my $self         = shift;
	# my $uniprot_file = shift;
	# my $file_handle  = shift;
	my ( $uniprot_file, $file_handle, $base, $namespace ) = @_; #vlmir
	# my $default_URL = "http://www.semantic-systems-biology.org/";
	my $default_URL = $base; #vlmir
	my $NS = $namespace; #vlmir
	my $ns = lc ($NS);
	
	
	# Preamble of RDF file
	print $file_handle "<?xml version=\"1.0\"?>\n";
	print $file_handle "<rdf:RDF\n";
	print $file_handle "\txmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n";
	print $file_handle "\txmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n";
	print $file_handle "\txmlns:".$ns."=\"".$default_URL.$NS."#\">\n";

	open (SPFH, $uniprot_file) || croak "Cannot open the file: ", $!;
	local $/ = "\n//\n";
	while (<SPFH>) {
		my $entry = SWISS::Entry->fromText($_);
	
		# AC
		my ( $accession, @accs ) = @{ $entry->ACs->{list} };

		my $prot_space = "protein";
		print $file_handle "\t<".$ns.":".$prot_space." rdf:about=\"#".$accession."\">\n";

		# mnemonic
		print $file_handle "\t\t<".$ns.":mnemonic>".$entry->ID."</".$ns.":mnemonic>\n";
		
		# GN
		my @genes = @{ $entry->GNs->{list} };
		my $gene_name;
		foreach my $gene_group (@genes){
			($gene_name = ${ $gene_group->{Names}->{list} }[0]->{text} ) || ( $gene_name = ${ $gene_group->{OLN}->{list} }[0]->{text} ) || ( $gene_name = ${ $gene_group->{ORFNames}->{list} }[0]->{text} );
			print $file_handle "\t\t<".$ns.":encoded_by>".&char_hex_http($gene_name)."</".$ns.":encoded_by>\n";
		}
		
		# DE
		my ( $def,       @syns ) = @{ $entry->DEs->{list} };
		my $definition = $def->{text};
		print $file_handle "\t\t<".$ns.":name>".&char_hex_http($definition)."</".$ns.":name>\n";
		foreach my $syn (@syns){
			print $file_handle "\t\t<".$ns.":name>".&char_hex_http($syn->{text})."</".$ns.":name>\n";
		}
		
		# OS
		my $organism = $entry -> OSs -> head -> text;
		print $file_handle "\t\t<".$ns.":organism>".$organism."</".$ns.":organism>\n";
		
		# OX
		my $taxon = $entry -> OXs -> NCBI_TaxID() -> head -> text;
		print $file_handle "\t\t<".$ns.":taxon>".$taxon."</".$ns.":taxon>\n";
		
		# CC (1st version)
		my @CCs = $entry -> CCs -> elements();
		if ((map {$_->topic eq 'FUNCTION' || $_->topic eq 'DISEASE'} @CCs)[0]) {
			print $file_handle "\t\t<ssb:annotation>\n";
			my $function  = "function";
			my $disease   = "disease";
			my $mim_id    = "mim";
			my $cc_topic  = "comment";
			print $file_handle "\t\t\t<rdf:Description>\n";
			for my $CC (@CCs) {
				if ($CC -> topic eq 'FUNCTION') {
					my $comment = $CC->comment;
					
					print $file_handle "\t\t\t\t<".$ns.":".$function.">\n";
					print $file_handle "\t\t\t\t<rdf:Description>\n";
						
						print $file_handle "\t\t\t\t\t<".$ns.":".$cc_topic.">";
						print $file_handle &char_hex_http($comment);
						print $file_handle "</".$ns.":".$cc_topic.">\n";
						
					print $file_handle "\t\t\t\t</rdf:Description>\n";
					print $file_handle "\t\t\t\t</".$ns.":".$function.">\n";				
				} elsif ($CC -> topic eq 'DISEASE') {
					my $comment = $CC->comment;
					$comment =~ m/MIM:(\d*)/;
					my $mim = $1;
					
					print $file_handle "\t\t\t\t<".$ns.":".$disease.">\n";
					print $file_handle "\t\t\t\t<rdf:Description>\n";
						
						print $file_handle "\t\t\t\t\t<".$ns.":".$cc_topic.">";
						print $file_handle &char_hex_http($CC->comment);
						print $file_handle "</".$ns.":".$cc_topic.">\n";
						
						print $file_handle "\t\t\t\t\t<".$ns.":".$mim_id.">";
						print $file_handle &char_hex_http($mim);
						print $file_handle "</".$ns.":".$mim_id.">\n";
						
					print $file_handle "\t\t\t\t</rdf:Description>\n";
					print $file_handle "\t\t\t\t</".$ns.":".$disease.">\n";
				}
			}
			print $file_handle "\t\t\t</rdf:Description>\n";
			print $file_handle "\t\t</ssb:annotation>\n";
		}
		
		# CC (2nd version)
		@CCs = $entry -> CCs -> elements();
		if ((map {$_->topic eq 'FUNCTION' || $_->topic eq 'DISEASE'} @CCs)[0]) {
			my $function  = "function";
			my $disease   = "disease";
			my $ppi       = "interacts_with";
			for my $CC (@CCs) {
				if ($CC -> topic eq 'FUNCTION') {
					print $file_handle "\t\t<".$ns.":function>";
					print $file_handle &char_hex_http($CC->comment);
					print $file_handle "</".$ns.":function>\n";
				} elsif ($CC -> topic eq 'DISEASE') {
					print $file_handle "\t\t<".$ns.":disease>";
					print $file_handle &char_hex_http($CC->comment);
					print $file_handle "</".$ns.":disease>\n";
				} elsif ($CC -> topic eq 'INTERACTION') {
					if ($CC) {
						for my $el ($CC->elements) {
							my $acc = $el->{accession};
							$acc = $accession if ($acc eq 'Self'); # if the same prot, then use its acc
							print $file_handle "\t\t<".$ns.":interacts_with rdf:resource=\"#".$acc."\"/>\n";
#							print $file_handle "\t\t<".$ns.":interacts_with>";
#							print $file_handle $el->{accession};
#							print $file_handle ";" . $el->{identifier} if defined $el->{identifier};
#							print $file_handle $el->{xeno} if defined $el->{xeno};
#							print $file_handle ";";
#							print $file_handle " NbExp=" . $el->{NbExp} . ";" if defined $el->{NbExp};
#							print $file_handle " IntAct=" . join (", ", @{$el->{IntAct}}) . ";" if defined $el->{IntAct};
#							print $file_handle "</".$ns.":interacts_with>\n";
						}
					}
				}
			}
		}
		
		# end (entry)
		print $file_handle "\t</".$ns.":".$prot_space.">\n";
	}
	close SPFH;
	
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
	if ($_[0]) {
		$_[0] =~ s/:/%3A/g;
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
	} else {
		return "";
	}
}
1;
