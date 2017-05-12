#!/usr/bin/env perl
# $Id: obo2apo.pl 2013-09-29 erick.antezana $
#
# Script  : obo2apo.pl
# Purpose : Generates an OBO ontology that can be integrated in the Cell
#           Cycle Ontology (APO). The terms from the input ontology will
#           be given a APO-like ID. The original IDs will be added as
#           cross references. The subnamespace by default is 'Z'. It is 
#           possible to specify the root term from the subontology we are
#           interested in (from input_file.obo).
# Usage:    obo2apo.pl input_file.obo apo_z.ids Z MI:0190 > output_file.obo
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
##############################################################################

use strict;
use Carp;

use OBO::Parser::OBOParser;
use OBO::APO::APO_ID_Term_Map;

##############################################################################

my $my_parser = OBO::Parser::OBOParser->new();

my $onto = $my_parser->work(shift @ARGV);                      # input file
my $apo_id_map = OBO::APO::APO_ID_Term_Map->new(shift @ARGV);  # IDs file
my $sns = shift @ARGV || 'Z';                                  # subnamespace
my $sub_ontology_root_id = shift @ARGV;                        # root term e.g. MI:0190

if ($sub_ontology_root_id) {
	my $term = $onto->get_term_by_id($sub_ontology_root_id);
	$onto = $onto->get_subontology_from($term);
}

my $ns = $onto->idspace_as_string("APO", "http://www.cellcycle.org/ontology/APO");
$onto->default_relationship_id_prefix("OBO_REL");
$onto->default_namespace("cellcycle_ontology");
$onto->remarks("A Cell-Cycle Sub-Ontology");

foreach my $entry (sort {$a->id() cmp $b->id()} @{$onto->get_terms()}){
	my $current_id = $entry->id();
	my $entry_name = $entry->name();

	my $apo_id = $apo_id_map->get_id_by_term($entry_name);
	# Has an ID been already associated to this term (repeated entry)?
	$apo_id = $apo_id_map->get_new_id($ns->local_idspace(), $sns, $entry_name) if (!defined $apo_id);

	$onto->set_term_id($entry, $apo_id);
	# xref's
	my $xref = OBO::Core::Dbxref->new();
	$xref->name($current_id);
	my $xref_set = $onto->get_term_by_id($entry->id())->xref_set();
	$xref_set->add($xref);
	# add the alt_id's as xref's
	foreach my $alt_id ($entry->alt_id()->get_set()){
		my $xref_alt_id = OBO::Core::Dbxref->new();
		$xref_alt_id->name($alt_id);
		$xref_set->add($xref_alt_id);
	}
	$entry->alt_id()->clear() if (defined $entry->alt_id()); # erase the alt_id(s) from this 'entry'
}
$apo_id_map->write_map();
$onto->export('obo', \*STDOUT);

exit 0;

__END__

=head1 NAME

obo2apo.pl - Converts an ontology into another one which could be integrated into APO.

=head1 DESCRIPTION

Generates an OBO ontology that can be integrated in the Cell
Cycle Ontology (APO). The terms from the input ontology will
be given a APO-like ID. The original IDs will be added as
cross references. The subnamespace by default is 'Z'. It is 
possible to specify the root term from the subontology we are
interested in (from input_file.obo).

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut