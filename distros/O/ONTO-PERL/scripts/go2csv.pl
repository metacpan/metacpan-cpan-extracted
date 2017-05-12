#!/usr/bin/env perl
# $Id: go2csv.pl 2015-10-28 erick.antezana $
#
# Script  : go2csv.pl
# Purpose : Generates an CSV-formatted file from a Gene Ontology file (in OBO format).
#			This script is typically used when a flat version of GO is needed.
#           You can download GO from: http://geneontology.org/page/download-ontology
#
# Usage   : go2csv.pl /path/to/go_file_in_obo_format > output_file_in_csv_format
# Example : go2csv.pl /path/to/go-basic.obo > go-basic.csv
# Arguments:
#  			1. Full path to the Gene Ontology file (in OBO format)
#
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
##############################################################################

BEGIN {
	unshift @INC, qw(/home/bbean/BOLS/ONTO-PERL/lib);
}

use Carp;
use strict;
use warnings;
use OBO::Parser::OBOParser;

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
	print "\tdescription: Generates an CSV-formatted file from a Gene Ontology file (in OBO format).\n";
	print "\tusage      : go2csv.pl [options]\n";
	print "\toptions    :\n";
	print "\t\t-f  	 OBO input file\n";
	print "\texample:\n";
	print "\t\tperl go2csv.pl -f go.obo\n";
	exit;
}

my $my_parser     = OBO::Parser::OBOParser->new();
my $ontology      = $my_parser->work($file);

foreach my $term (@{$ontology->get_terms()}) {

	# id
	print $term->id(), "\t";
	
	# name
	print $term->name(), "\t";
	
	# ns
	print $term->namespace(), "\t"; # biological_process, molecular_function, cellular_component
	
	# alt id
	my $alt_id_str = '';
	foreach my $alt_id ($term->alt_id()->get_set()) {
		$alt_id_str .= $alt_id.'|';
	} print substr($alt_id_str,0,-1)."\t";
	
	# def
	if (defined $term->def()->text()) {
		print $term->def()->text();
	} print "\t";
	
	# comment
	if (defined $term->comment()) {
		print $term->comment();
	} print "\t";
	
	# synonyms
	my @sorted_defs = map { $_->[0] }        # restore original values
		sort { $a->[1] cmp $b->[1] }         # sort
		map  { [$_, lc($_->def()->text())] } # transform: value, sortkey
		$term->synonym_set();
	my $syn_str = '';
	foreach my $synonym (@sorted_defs) {
		$syn_str .= $synonym->def()->text().'('.$synonym->scope().')'.'|';
	} print substr($syn_str,0,-1)."\t";
	
	# xrefs
	my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $term->xref_set_as_string());
	my $xref_str = '';
	foreach my $xref (@sorted_xrefs) {
		$xref_str .= $xref->as_string().'|';
	} print substr($xref_str,0,-1)."\t";
	
	# is_a parents
	my $rt = $ontology->get_relationship_type_by_id('is_a');
	my $is_str = '';
	if (defined $rt)  {
		my %saw_is_a; # avoid duplicated arrows (RelationshipSet?)
		my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$ontology->get_head_by_relationship_type($term, $rt)}); 
		foreach my $head (grep (!$saw_is_a{$_}++, @sorted_heads)) {
			my $is_a_txt = $head->id();
			my $head_name = $head->name();
			$is_a_txt .= ' ('.$head_name.')' if (defined $head_name);
			$is_str .= $is_a_txt.'|';
		}
	} print substr($is_str,0,-1)."\t";
	
	# disjoint_from
	my $disjoint_from_str = '';
	foreach my $disjoint_term_id ($term->disjoint_from()) {
		my $disjoint_from_txt = $disjoint_term_id;
		my $dt                = $ontology->get_term_by_id($disjoint_term_id);
		my $dt_name           = $dt->name() if (defined $dt);
		$disjoint_from_txt   .= ' ('.$dt_name.')' if (defined $dt_name);
		$disjoint_from_str   .= $disjoint_from_txt.'|';
	} print substr($disjoint_from_str,0,-1)."\t";
	
	# relationship
	my %saw1;
	my @sorted_rel_types = @{$ontology->get_relationship_types_sorted_by_id()};
	my $rel_str = '';
	foreach my $rt (grep (!$saw1{$_}++, @sorted_rel_types)) { # use this foreach-line if there are duplicated rel's
		my $rt_id = $rt->id();
		if ($rt_id ne 'is_a') { # is_a is printed above
			my %saw2;
			my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$ontology->get_head_by_relationship_type($term, $rt)});
			foreach my $head (grep (!$saw2{$_}++, @sorted_heads)) { # use this foreach-line if there are duplicated rel's
				my $relationship_txt  = $head->id();
				my $relationship_name = $head->name();
				$relationship_txt    .= ' ('.$relationship_name.')' if (defined $relationship_name);
				$relationship_txt    .= '['.$rt_id.']';
				$rel_str             .= $relationship_txt.'|';
			}
		}
	} print substr($rel_str,0,-1);
		
	print "\n";
}

sub __sort_by {
	my ($subRef1, $subRef2, @input) = @_;
	my @result = map { $_->[0] }                           # restore original values
				sort { $a->[1] cmp $b->[1] }               # sort
				map  { [$_, &$subRef1($_->$subRef2())] }   # transform: value, sortkey
				@input;
}

sub __sort_by_id {
	my ($subRef, @input) = @_;
	my @result = map { $_->[0] }                           # restore original values
				sort { $a->[1] cmp $b->[1] }               # sort
				map  { [$_, &$subRef($_->id())] }          # transform: value, sortkey
				@input;
}

exit 0;

__END__

=head1 NAME

go2csv.pl - Generates an CSV-formatted file from a Gene Ontology file (in OBO format).

=head1 DESCRIPTION

Generates an CSV-formatted file from a Gene Ontology file (in OBO format). This script is typically used when a flat version of GO is needed for further processing of specific entities (e.g. IDs, names)

Multiple items belonging to the same category (e.g. synonyms) are separated by a '|'.

The following tags are exported (in that order):

 - term ID
 - term name
 - namespace (biological_process, molecular_function, cellular_component)
 - alt_id
 - definition
 - comment
 - synonym(s)
 - xref(s)
 - is_a (parents)
 - disjoint_from
 - relationship (parents)

You can download GO from: http://geneontology.org/page/download-ontology

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut