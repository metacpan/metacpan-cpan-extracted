#!/usr/bin/env perl
# $Id: bioportal_csv2obo.pl 2015-10-11 erick.antezana $
#
# Script  : bioportal_csv2obo.pl
# Purpose : Generates an OBO-formatted ontology from a given CSV file from BioPortal.
#			This script is typically used when there is no ontology in OBO format but it is available
#			in BioPortal [http://bioportal.bioontology.org/].
# Usage   : bioportal_csv2obo.pl /path/to/input_file.csv > output_file.obo
# Example : bioportal_csv2obo.pl /path/to/SIO.csv > SIO.obo
# Arguments:
#  			1. Full path to the CSV file
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
##############################################################################

use strict;
use warnings;

use Text::CSV;

use OBO::Core::Ontology;
use OBO::Core::Term;
use OBO::Core::Relationship;
use OBO::Core::RelationshipType;

use Getopt::Long;

my %opts = ();
GetOptions (\%opts,
	'f=s{1,1}',
	'help|h')
or die("Error in command line arguments, ask for help: -h\n");

my $file    = $opts{f};

unless ($file) {print_help()};

sub print_help {
	print "\n";
	print "\tdescription: Generates an OBO-formatted ontology from a given CSV file from BioPortal.\n";
	print "\tusage      : bioportal_csv2obo.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 CSV input file\n";
	print "\texample:\n";
	print "\t\tperl bioportal_csv2obo.pl -f go.csv\n";
	exit;
}

#
# CSV structure:
#
# Class ID,Preferred Label,Synonyms,Definitions,Obsolete,CUI,Semantic Types,Parents
#
my ($class_id, $referred_label, @synonyms, $definitions, $obsolete, $CUI, $semantic_types, $parents);

#sample line: 'http://purl.obolibrary.org/obo/GO_1902236,negative regulation of endoplasmic reticulum stress-induced intrinsic apoptotic signaling pathway,down regulation of apoptosis triggered by ER stress|down regulation of endoplasmic reticulum stress-induced apoptosis|down-regulation of apoptosis triggered by ER stress|negative regulation of apoptosis in response to ER stress|down-regulation of intrinsic apoptotic signaling pathway in response to endoplasmic reticulum stress|downregulation of intrinsic apoptotic signaling pathway induced by endoplasmic reticulum stress|negative regulation of intrinsic apoptotic signaling pathway in response to endoplasmic reticulum stress|negative regulation of ER stress-induced apoptosis|downregulation of apoptosis triggered by ER stress|downregulation of endoplasmic reticulum stress-induced apoptosis|down-regulation of endoplasmic reticulum stress-induced apoptosis|down regulation of intrinsic apoptotic signaling pathway in response to endoplasmic reticulum stress|down regulation of apoptosis in response to ER stress|negative regulation of endoplasmic reticulum stress-induced apoptosis|negative regulation of apoptosis triggered by ER stress|down-regulation of ER stress-induced apoptosis|downregulation of apoptosis in response to ER stress|downregulation of ER stress-induced apoptosis|downregulation of intrinsic apoptotic signaling pathway in response to endoplasmic reticulum stress|down-regulation of apoptosis in response to ER stress|down regulation of ER stress-induced apoptosis|down regulation of intrinsic apoptotic signaling pathway induced by endoplasmic reticulum stress|negative regulation of intrinsic apoptotic signaling pathway induced by endoplasmic reticulum stress|down-regulation of intrinsic apoptotic signaling pathway induced by endoplasmic reticulum stress,"Any process that stops, prevents or reduces the frequency, rate or extent of an endoplasmic reticulum stress-induced intrinsic apoptotic signaling pathway.",false,,,http://purl.obolibrary.org/obo/GO_1903573|http://purl.obolibrary.org/obo/GO_2001243|http://purl.obolibrary.org/obo/GO_1902235';

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", $file or die 'The CSV file (', $file, ') cannot be opened: ', $!;

my $ontology   = OBO::Core::Ontology->new();
my $first_line = 1;
while ( my $row = $csv->getline( $fh ) ) {
	
	$first_line--, next if $first_line == 1; # skip the header
	
	#
	# class id
	#
	$row->[0] =~ m/^https?:\/\/.*\/(.*)$/; # get the OBO-like ID
	my $term_id = $1;
	$term_id =~ s/_/:/g;
	#print "id: ", $term_id, "\n";
	
	#
	# referred label
	#
	my $term_name = $row->[1];
	#print "name: ", $term_name, "\n";
	
	#
	# synonyms
	#
	my $synonyms = $row->[2];
	my $ssv      = Text::CSV->new ({ sep_char => '|'});
	my $status   = $ssv->parse($synonyms);    # parse synonyms
	my @synonyms = $ssv->fields();            # get the parsed fields
	#print "synonym: ", $_, "\n" for @synonyms;
		
	#
	# definition(s?)
	#
	my $definition = $row->[3];
	#print "definition: ", $definition, "\n";
	
	#
	# obsolete
	#
	my $obsolete = $row->[4];
	$obsolete = ($obsolete eq 'false')?0:1;
	#print "obsolete: ", $obsolete, "\n";
	
	#
	# cui: NOT USED YET
	#
	my $cui = $row->[5];
	#print "cui: ", $cui, "\n";
	
	#
	# semantic types: NOT USED YET
	#
	my $semantic_types = $row->[6];
	#print "semantic types: ", $semantic_types, "\n";
	
	#
	# parents
	#
	my $parents = $row->[7];
	my $psv     = Text::CSV->new ({ sep_char => '|'});
	$status     = $psv->parse($parents);     # parse synonyms
	my @parents = $psv->fields();            # get the parsed fields
	my @parents_ids = ();
	for my $p (@parents) {
		$p =~ m/^https?:\/\/.*\/(.*)$/; # get the OBO-like ID
		my $p_id = $1;
		$p_id =~ s/_/:/g;
		push @parents_ids, $p_id;
	}
	
	#print "parent: ", $_, "\n" for @parents;
	
	#
	# ontology population
	#
	my $new_term = $ontology->get_term_by_id($term_id);
	if (!defined $new_term) {
		$new_term = OBO::Core::Term->new();
		$new_term->id($term_id);
	}
	$new_term->name($term_name);
	$new_term->def()->text($definition);
	$new_term->is_obsolete($obsolete);
	$new_term->synonym_as_string($_, '[]', 'EXACT') for @synonyms;
	my $rel_type_id   = 'has_parent';
	my $rel_type_name = 'has_parent';
	my $r_type = $ontology->get_relationship_type_by_id($rel_type_name); # Is this relationship type already in the ontology?
	if (!defined $r_type){
		$r_type = OBO::Core::RelationshipType->new();                    # if not, create a new relationship type
		$r_type->id($rel_type_id);
		$ontology->add_relationship_type($r_type);                       # add it to the ontology
	}
	for my $pi (@parents_ids) {
		
		my $target = $ontology->get_term_by_id($pi); # Is this term already in the ontology?
		if (!defined $target) {
			$target = OBO::Core::Term->new(); # if not, create a new term
			$target->id($pi);
			$ontology->add_term($target);
		}
		$ontology->create_rel($new_term, $rel_type_id, $target);
	}
	
	$ontology->add_term($new_term);	
}
$csv->eof or $csv->error_diag();
close $fh;

$ontology->export('obo', \*STDOUT);

exit 0;

__END__

=head1 NAME

bioportal_csv2obo.pl - Generates an OBO-formatted ontology from a given CSV file from BioPortal.

=head1 DESCRIPTION

Generates an OBO-formatted ontology from a given CSV file from BioPortal. The OBO file provides 
a simple representation based on the information captured in the CSV file which might be sufficient 
for certain applications.

This script will be updated according to the evolution of the CSV file from BioPortal.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut