# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

###################################################################################################
use strict;

use File::Path qw(remove_tree);
use File::Compare;
use File::Basename;
use JSON::XS qw[decode_json];

use Test::More tests => 15;
use Test::Exception;
use Test::Deep;

use lib dirname(__FILE__);

use SPtesting;
use Shatterproof;

my $dir = dirname(__FILE__);

my $config_file_path = "$dir/test_config.pl";
my $output_directory = "$dir/output/";

$tp53_mutation_found = 0;

#populate input file arrays
my @trans_files;
$trans_files[0] = "$dir/spt/testing_trans_1.spt";
$trans_files[1] = "$dir/spt/testing_trans_2.spt";

my @cnv_files;
$cnv_files[0] = "$dir/spc/testing_cnv_1.spc";
$cnv_files[1] = "$dir/spc/testing_cnv_2.spc";

#create output directory
mkdir ("$output_directory",0770) unless (-d "$output_directory");

#check OS type
my $OS = '';
if($^O eq 'MSWin32'){
	$OS = '.mswin32';
}

##### Test loading config file ################################################
ok(Shatterproof::load_config_file($config_file_path),'load_config_file');
###############################################################################

#run analyze cnv
($genome_cnv_data_hash_ref, $chromosome_copy_number_count_hash_ref, $chromosome_cnv_breakpoints_hash_ref) = Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found);

#run analyze trans
($genome_trans_data_hash_ref, $chromosome_translocation_count_hash_ref, $genome_trans_breakpoints_hash_ref) = Shatterproof::analyze_trans_data($output_directory, \@trans_files, $bin_size, \$tp53_mutation_found);


##### test calculate_chromosome_localization ##################################
($suspect_regions_array_ref, $likely_regions_array_ref, $genome_cnv_data_windows_hash_ref, $genome_trans_data_windows_hash_ref, $genome_mutation_data_windows_hash_ref) = Shatterproof::calculate_chromosome_localization($output_directory, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $bin_size, $localization_window_size);

#compare output hashes
open(FILE, "<", "$dir/json/suspect_regions_array_ref.json");
my $test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_bag($suspect_regions_array_ref, $test1_json, "calculate_chromosome_localization-1");

open(FILE, "<", "$dir/json/likely_regions_array_ref.json");
$test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_bag($likely_regions_array_ref, $test1_json, "calculate_chromosome_localization-2");

open(FILE, "<", "$dir/json/genome_cnv_data_windows_hash_ref.json");
$test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_deeply($genome_cnv_data_windows_hash_ref, $test1_json, "calculate_chromosome_localization-3");

open(FILE, "<", "$dir/json/genome_trans_data_windows_hash_ref.json");
$test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_deeply($genome_trans_data_windows_hash_ref, $test1_json, "calculate_chromosome_localization-4");

open(FILE, "<", "$dir/json/genome_mutation_data_windows_hash_ref.json");
$test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_deeply($genome_mutation_data_windows_hash_ref, $test1_json, "calculate_chromosome_localization-5");

#compare output files
my $test_file;
my $ref_file;

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/cnv/chr10_cnv_localization.log");
open ($ref_file, "$dir/ref/chr10_cnv_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-6");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/cnv/chr11_cnv_localization.log");
open ($ref_file, "$dir/ref/chr11_cnv_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-7");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/cnv/chr1_cnv_localization.log");
open ($ref_file, "$dir/ref/chr1_cnv_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-8");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/translocations/chr3_translocation_localization.log");
open ($ref_file, "$dir/ref/chr3_translocation_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-9");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/translocations/chr2_translocation_localization.log");
open ($ref_file, "$dir/ref/chr2_translocation_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-10");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/translocations/chr21_translocation_localization.log");
open ($ref_file, "$dir/ref/chr21_translocation_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-11");;
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/all_types/chr4_mutation_localization.log");
open ($ref_file, "$dir/ref/chr4_mutation_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-12");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/all_types/chrX_mutation_localization.log");
open ($ref_file, "$dir/ref/chrX_mutation_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-13");
close($test_file);
close($ref_file);

$test_file = SPtesting::test_open ($test_file, "$dir/output/mutation_clustering/all_types/chrY_mutation_localization.log");
open ($ref_file, "$dir/ref/chrY_mutation_localization.log.ref".$OS);
ok(compare($test_file, $ref_file)==0, "calculate_chromosome_localization-14");
close($test_file);
close($ref_file);

#delete output directory
remove_tree("$dir/output");
