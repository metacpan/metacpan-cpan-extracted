# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

###################################################################################################
use strict;

use File::Path qw(remove_tree);
use File::Compare;
use File::Basename;

use Test::More tests => 2;
use Test::Exception;
use Test::Deep;

use lib dirname(__FILE__);

use SPtesting;
use Shatterproof;

my $dir = dirname(__FILE__);

my $config_file_path = "$dir/test_config.pl";
my $output_directory = "$dir/output/";

$tp53_mutation_found = 0;

#populate 	input file arrays
my @trans_files;
$trans_files[0] = "$dir/spt/testing_trans_1.spt";
$trans_files[1] = "$dir/spt/testing_trans_2.spt";

my @cnv_files;
$cnv_files[0] = "$dir/spc/testing_cnv_1.spc";
$cnv_files[1] = "$dir/spc/testing_cnv_2.spc";

#create output directory
mkdir ("$output_directory",0770) unless (-d "$output_directory");

##### Test loading config file ################################################
ok(Shatterproof::load_config_file($config_file_path),'load_config_file');
###############################################################################

#run analyze cnv
($genome_cnv_data_hash_ref, $chromosome_copy_number_count_hash_ref, $chromosome_cnv_breakpoints_hash_ref) = Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found);

#run analyze trans
($genome_trans_data_hash_ref, $chromosome_translocation_count_hash_ref, $genome_trans_breakpoints_hash_ref) = Shatterproof::analyze_trans_data($output_directory, \@trans_files, $bin_size, \$tp53_mutation_found);


$genome_mutation_density_hash_ref = Shatterproof::calculate_genome_localization($output_directory, $chromosome_copy_number_count_hash_ref, $chromosome_translocation_count_hash_ref);


($suspect_regions_array_ref, $likely_regions_array_ref, $genome_cnv_data_windows_hash_ref, $genome_trans_data_windows_hash_ref, $genome_mutation_data_windows_hash_ref) = Shatterproof::calculate_chromosome_localization($output_directory, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $bin_size, $localization_window_size);

##### test analyze_likely_regions ######################################
my $likely_regions;
$likely_regions = Shatterproof::analyze_likely_regions($output_directory, $likely_regions_array_ref, $genome_mutation_density_hash_ref, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $bin_size, $localization_window_size);

cmp_deeply($likely_regions, ["4","39099000","49099000",num(2.2e-06,1),"Y","37000","10043000",num(1.39916050369778e-06,1),"16","33979000","43987000",num(1.19904076738609e-06,1),"4","49517000","59637000",num(1.18577075098814e-06,1),"10","29112000","39125000",num(1.09857185658644e-06,1),"4","0","13817000",num(1.08561916479699e-06,1),"6","159333000","170897000",num(1.03770321687997e-06,1),"16","23954000","33972000",num(9.98203234178479e-07,1),"10","39080000","49125000",num(9.95520159283226e-07,1),"7","51750000","71559000",num(8.07713665505578e-07,1),"Y","13869000","23869000",num(7e-07,1),"21","775000","20698000",num(3.51352707925513e-07,1),"2","81795000","99865000",num(3.32042058660764e-07,1)], "calculate_chromosome_localization-1");
###############################################################################

#delete output directory
remove_tree("$dir/output");
