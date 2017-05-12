package RandomJungle::TestData;

=head1 NAME

RandomJungle::TestData - Test data for the RandomJungle* modules

=cut

use strict;
use warnings;

=head1 VERSION

Version 0.01

=cut

our $VERSION = 0.01;

our @ISA = ( "Exporter" );
our @EXPORT_OK = qw( get_exp_data );

# This package contains the expected values for the 'testdata_20samples_10vars' dataset

my %testdata;

sub get_exp_data
{
	return \%testdata;
}

#*************************************************
#                       XML
#*************************************************

$testdata{XML}{filename} = 'testdata_20samples_10vars.jungle.xml';

@{ $testdata{XML}{tree_ids} } = ( 0 .. 9 );

$testdata{XML}{options} =
	{
		file => '/home/freir2/RandomJungle/testdata/testdata_20samples_10vars.raw',
		delimiter => ' ', treetype => 1, ntree => 10, mtry => 3, depvar => 1,
		depvarname => 'PHENOTYPE', nrow => 20, ncol => 12, varnamesrow => 0,
		depvarcol => 0, outprefix => 'testdata_20samples_10vars', skiprow => 0,
		skipcol => 0, missingcode => 3, impmeasure => 3, backsel => 0, nimpvar => 100,
		downsampling => 0, verbose => 0, memMode => 2, write => 2, predict => '',
		varproximities => 0, summary => 0, testlib => 0, plugin => '',
		colselection => '', impute => 0, gwa => 0, impcont => 0, transpose => 0,
		sampleproximities => 0, weightsim => 0, extractdata => 0, yaimp => 0,
		seeed => 1, nthreads => 0, pluginpar => '', maxtreedepth => 100,
		targetpartitionsize => 1, pedfile => 1,
	};

$testdata{XML}{treedata}{1} =
	{
		varID => '((9,11,4,6,10,0,8,11,0,0,0,3,2,0,0,4,0,0,0,0,0))',
		values => '(((1)),((1)),((1)),((0)),((0)),((1)),((0)),((0)),((1)),((2)),((1)),((0)),((1)),((1)),((2)),((0)),((1)),((2)),((2)),((2)),((1)))',
		branches => '((1,20),(2,19),(3,18),(4,11),(5,6),(0,0),(7,10),(8,9),(0,0),(0,0),(0,0),(12,15),(13,14),(0,0),(0,0),(16,17),(0,0),(0,0),(0,0),(0,0),(0,0))',
		nodes_at_vector_i => {
								0 => {
		                                 vector_index => 0,
		                                 is_terminal => 0,
		                                 variable_index => 9,
		                                 next_vector_i => [ 1, 1, 20 ],
		                                 path => [ 0 ],
		                             },
								1 => {
		                                 vector_index => 1,
		                                 is_terminal => 0,
		                                 variable_index => 11,
		                                 next_vector_i => [ 2, 2, 19 ],
	                                     index_of_parent_node => 0,
										 path => [ 0, 1 ],
		                             },
								2 => {
		                                 vector_index => 2,
		                                 is_terminal => 0,
		                                 variable_index => 4,
		                                 next_vector_i => [ 3, 3, 18 ],
	                                     index_of_parent_node => 1,
										 path => [ 0, 1, 2 ],
		                             },
								3 => {
		                                 vector_index => 3,
		                                 is_terminal => 0,
		                                 variable_index => 6,
		                                 next_vector_i => [ 4, 11, 11 ],
	                                     index_of_parent_node => 2,
										 path => [ 0, 1, 2, 3 ],
		                             },
								4 => {
		                                 vector_index => 4,
		                                 is_terminal => 0,
		                                 variable_index => 10,
		                                 next_vector_i => [ 5, 6, 6 ],
	                                     index_of_parent_node => 3,
										 path => [ 0, 1, 2, 3, 4 ],
		                             },
		                        5 => {
	                                     vector_index => 5,
	                                     is_terminal => 1,
	                                     terminal_value => 1,
	                                     index_of_parent_node => 4,
										 path => [ 0, 1, 2, 3, 4, 5 ],
	                                   },
								6 => {
		                                 vector_index => 6,
		                                 is_terminal => 0,
		                                 variable_index => 8,
		                                 next_vector_i => [ 7, 10, 10 ],
	                                     index_of_parent_node => 4,
										 path => [ 0, 1, 2, 3, 4, 6 ],
		                             },
								7 => {
		                                 vector_index => 7,
		                                 is_terminal => 0,
		                                 variable_index => 11,
		                                 next_vector_i => [ 8, 9, 9 ],
	                                     index_of_parent_node => 6,
										 path => [ 0, 1, 2, 3, 4, 6, 7 ],
		                             },
								8 => {
										 vector_index => 8,
										 is_terminal => 1,
										 terminal_value => 1,
										 index_of_parent_node => 7,
										 path => [ 0, 1, 2, 3, 4, 6, 7, 8 ],
									 },
								9 => {
										 vector_index => 9,
										 is_terminal => 1,
										 terminal_value => 2,
										 index_of_parent_node => 7,
										 path => [ 0, 1, 2, 3, 4, 6, 7, 9 ],
									 },
								10 => {
										 vector_index => 10,
										 is_terminal => 1,
										 terminal_value => 1,
										 index_of_parent_node => 6,
										 path => [ 0, 1, 2, 3, 4, 6, 10 ],
									 },
								11 => {
		                                 vector_index => 11,
		                                 is_terminal => 0,
		                                 variable_index => 3,
		                                 next_vector_i => [ 12, 15, 15 ],
	                                     index_of_parent_node => 3,
										 path => [ 0, 1, 2, 3, 11 ],
		                             },
								12 => {
		                                 vector_index => 12,
		                                 is_terminal => 0,
		                                 variable_index => 2,
		                                 next_vector_i => [ 13, 13, 14 ],
	                                     index_of_parent_node => 11,
										 path => [ 0, 1, 2, 3, 11, 12 ],
		                             },
								13 => {
										 vector_index => 13,
										 is_terminal => 1,
										 terminal_value => 1,
										 index_of_parent_node => 12,
										 path => [ 0, 1, 2, 3, 11, 12, 13 ],
									 },
								14 => {
										 vector_index => 14,
										 is_terminal => 1,
										 terminal_value => 2,
										 index_of_parent_node => 12,
										 path => [ 0, 1, 2, 3, 11, 12, 14 ],
									 },
								15 => {
		                                 vector_index => 15,
		                                 is_terminal => 0,
		                                 variable_index => 4,
		                                 next_vector_i => [ 16, 17, 17 ],
	                                     index_of_parent_node => 11,
										 path => [ 0, 1, 2, 3, 11, 15 ],
		                             },
								16 => {
										 vector_index => 16,
										 is_terminal => 1,
										 terminal_value => 1,
										 index_of_parent_node => 15,
										 path => [ 0, 1, 2, 3, 11, 15, 16 ],
									 },
								17 => {
										 vector_index => 17,
										 is_terminal => 1,
										 terminal_value => 2,
										 index_of_parent_node => 15,
										 path => [ 0, 1, 2, 3, 11, 15, 17 ],
									 },
								18 => {
										 vector_index => 18,
										 is_terminal => 1,
										 terminal_value => 2,
										 index_of_parent_node => 2,
										 path => [ 0, 1, 2, 18 ],
									 },
								19 => {
										 vector_index => 19,
										 is_terminal => 1,
										 terminal_value => 2,
										 index_of_parent_node => 1,
										 path => [ 0, 1, 19 ],
									 },
								20 => {
										 vector_index => 20,
										 is_terminal => 1,
										 terminal_value => 1,
										 index_of_parent_node => 0,
										 path => [ 0, 20 ],
									 },
	                         },
	};

$testdata{XML}{treedata}{1}{var_indices_used_in_tree} =
	do
	{
		my @nonterm_noderefs =
			grep { defined $_->{variable_index} }
		 		 ( values %{ $testdata{XML}{treedata}{1}{nodes_at_vector_i} } );
		my @var_indices = map { $_->{variable_index} } @nonterm_noderefs;
		my %uniq_var_i = map { $_ => 1 } @var_indices;
		[ sort { $a <=> $b } ( keys %uniq_var_i ) ];
	};

#*************************************************
#                       OOB
#*************************************************

$testdata{OOB}{filename} = 'testdata_20samples_10vars.oob';

$testdata{OOB}{matrix} =
	[
		'0	0	0	1	1	0	1	0	0	0',
		'0	1	1	0	1	1	1	1	0	1',
		'0	0	0	0	1	0	0	1	0	1',
		'0	0	0	1	0	0	0	0	0	1',
		'0	0	1	0	0	0	0	0	0	0',
		'0	1	0	0	0	0	0	0	0	1',
		'0	0	0	0	0	0	1	0	0	0',
		'1	0	0	0	0	0	1	1	0	0',
		'0	0	0	0	1	1	0	0	0	1',
		'0	1	1	0	0	0	0	1	0	0',
		'0	0	1	1	1	1	1	1	0	0',
		'1	0	0	1	1	1	0	0	0	1',
		'0	0	1	0	0	1	0	0	0	1',
		'1	0	1	0	0	1	0	0	1	1',
		'1	0	1	1	1	0	0	0	0	1',
		'0	0	0	1	1	0	0	0	1	0',
		'0	1	1	1	0	0	1	1	0	0',
		'0	0	0	0	0	0	0	1	1	1',
		'1	1	0	0	0	0	1	0	0	1',
		'1	0	0	1	0	0	1	0	1	0',
	];

$testdata{OOB}{data_by_sample_index}{0} =
	{
		sample_used_to_construct_trees => [ 0, 1, 2, 5, 7, 8, 9 ],
		sample_not_used_to_construct_trees => [ 3, 4, 6 ],
		state_for_tree => [ 0, 0, 0, 1, 1, 0, 1, 0, 0, 0 ],
	};
# removed key (not needed?): 		trees_with_unrecognized_OOB_state => [],

$testdata{OOB}{data_by_sample_index}{19} =
	{
		sample_used_to_construct_trees => [ 1, 2, 4, 5, 7, 9 ],
		sample_not_used_to_construct_trees => [ 0, 3, 6, 8 ],
		state_for_tree => [ 1, 0, 0, 1, 0, 0, 1, 0, 1, 0 ],
	};
# removed key (not needed?): 		trees_with_unrecognized_OOB_state => [],

$testdata{OOB}{data_by_tree_index}{2} =
	{
		oob_samples => [ qw( s2 s5 s10 s11 s13 s14 s15 s17 ) ],
		in_bag_samples => [ qw( s1 s3 s4 s6 s7 s8 s9 s12 s16 s18 s19 s20 ) ],
		state_for_sample_index => [ 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0 ],
	};
# removed key (not needed?): 		trees_with_unrecognized_OOB_state => [],

#*************************************************
#                       RAW
#*************************************************

$testdata{RAW}{filename} = 'testdata_20samples_10vars.raw';

$testdata{RAW}{variable_labels} = [ 'SEX', 'PHENOTYPE', 'Var1', 'Var2', 'Var3', 'Var4',
									'Var5', 'Var6', 'Var7', 'Var8', 'Var9', 'Var10' ];

$testdata{RAW}{header_labels} = [ 'FID', 'IID', 'PAT', 'MAT' ];

foreach my $i ( 0 .. 19 )
{
	$testdata{RAW}{sample_labels}[$i] = 's' . ($i+1);
	$testdata{RAW}{data_by_sample_label}{ 's' . ($i+1) }{i} = $i;
}

$testdata{RAW}{data_by_sample_label}{s1}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s2}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s3}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s4}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s5}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s6}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s7}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s8}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s9}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s10}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s11}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s12}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s13}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s14}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s15}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s16}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s17}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s18}{phenotype} = 2;
$testdata{RAW}{data_by_sample_label}{s19}{phenotype} = 1;
$testdata{RAW}{data_by_sample_label}{s20}{phenotype} = 2;

$testdata{RAW}{data_by_sample_index}{0} =
	{
		label => 's1',
		phenotype => 1,
		orig_data => '1 s1 0 0 1 1 1 0 0 0 1 1 1 0 0 0',
		spliced_data => [ 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0 ],
	};

$testdata{RAW}{data_by_sample_index}{19} =
	{
		label => 's20',
		phenotype => 2,
		orig_data => '20 s20 0 0 1 2 0 1 1 0 1 1 0 1 0',
		spliced_data => [ 1, 2, 0, 1, 1, 0, 1, 1, 0, 1, 0 ],
	};

#*************************************************
#                 CLASSIFICATION
#*************************************************

# manually-determined classification data
# $testdata{classification}{$tree_id}{$sample_label} = $vector_index_of_terminal_node
$testdata{classification}{1} =
	{
		s1 => 13,
		s2 => 17,
		s3 => 5,
		s4 => 19,
		s5 => 16,
		s6 => 10,
		s7 => 14,
		s8 => 9,
		s9 => 20,
		s10 => 13,
		s11 => 18,
		s12 => 10,
		s13 => 8,
		s14 => 18,
		s15 => 19,
		s16 => 5,
		s17 => 13,
		s18 => 17,
		s19 => 8,
		s20 => 19,
	};

# computationally determined classification data
# $testdata{classification}{data_by_sample_label}{$sample_label}{by_tree}{$tree_id} = href

$testdata{classification}{data_by_sample_label}{s1}{by_tree} =
	{
		0 => { pred_pheno => 1, term_node_vi => 4 },
		1 => { pred_pheno => 1, term_node_vi => 13 },
		2 => { pred_pheno => 1, term_node_vi => 9 },
		3 => { pred_pheno => 1, term_node_vi => 5 },
		4 => { pred_pheno => 1, term_node_vi => 12 },
		5 => { pred_pheno => 1, term_node_vi => 8 },
		6 => { pred_pheno => 1, term_node_vi => 2 },
		7 => { pred_pheno => 1, term_node_vi => 12 },
		8 => { pred_pheno => 1, term_node_vi => 12 },
		9 => { pred_pheno => 1, term_node_vi => 7 },
	};

#*************************************************

=head1 SEE ALSO

RandomJungle::Jungle, RandomJungle::Tree, RandomJungle::Tree::Node,
RandomJungle::XML, RandomJungle::OOB, RandomJungle::RAW,
RandomJungle::DB, RandomJungle::Classification_DB

=head1 AUTHOR

Robert R. Freimuth

=head1 COPYRIGHT

Copyright (c) 2011 Mayo Foundation for Medical Education and Research.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
