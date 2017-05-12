# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

###################################################################################################
use strict;

use File::Path qw(remove_tree);
use File::Compare;
use File::Basename;
use JSON::XS qw[decode_json];

use Test::More tests => 12;
use Test::Exception;
use Test::Deep;

use lib dirname(__FILE__);

use SPtesting;
use Shatterproof;

my $dir = dirname(__FILE__);

my $config_file_path = "$dir/test_config.pl";
my $output_directory = "$dir/output/";

$tp53_mutation_found = 0;

#populate 	@cnv_files
my @cnv_files;
$cnv_files[0] = "$dir/spc/testing_cnv_1.spc";
$cnv_files[1] = "$dir/spc/testing_cnv_2.spc";

#create output directory
mkdir ("$output_directory",0770) unless (-d "$output_directory");

##### Test loading config file ################################################
ok(Shatterproof::load_config_file($config_file_path),'load_config_file');
###############################################################################


##### test analyze_cnv_data-1_file-valid_input-no_tp53 ########################
($genome_cnv_data_hash_ref, $chromosome_copy_number_count_hash_ref, $chromosome_cnv_breakpoints_hash_ref) = Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found);

open(FILE, "<", "$dir/json/genome_cnv_data_hash_ref_test_1.json");
my $test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_deeply($genome_cnv_data_hash_ref,$test1_json, 'analyze_cnv_data-1-1-file-valid_input-no_tp53');

open(FILE, "<", "$dir/json/chromosome_copy_number_count_hash_ref_test_1.json");
$test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_deeply($chromosome_copy_number_count_hash_ref,$test1_json, 'analyze_cnv_data-1-2-file-valid_input-no_tp53');

open(FILE, "<", "$dir/json/chromosome_cnv_breakpoints_hash_ref_test_1.json");
$test1_json = JSON::XS::decode_json(<FILE>);
close(FILE);
cmp_deeply($chromosome_cnv_breakpoints_hash_ref,$test1_json, 'analyze_cnv_data-1-3-file-valid_input-no_tp53');

my $test_file;
my $ref_file;
open ($test_file, "$dir/output/TP53/TP53.spc");
open ($ref_file, "$dir/ref/TP53_non.spc.ref");
ok(compare($test_file, $ref_file)==0, 'analyze_cnv_data-1-4-file-valid_input-no_tp53');
close($test_file);
close($ref_file);

ok($tp53_mutation_found==0,'analyze_cnv_data-1-5-file-valid_input-no_tp53');
###############################################################################


##### test analyze_cnv_data-2_empty-file ######################################
@cnv_files = ();
$cnv_files[0] = "$dir/spc/empty.txt";
dies_ok(sub{Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found)}, 'analyze_cnv_data-2_empty-file');
###############################################################################

##### test analyze_cnv_data-3_invalid-header ##################################
@cnv_files = ();
$cnv_files[0] = "$dir/spc/testing_cnv_invalid_header.spc";
dies_ok(sub{Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found)}, 'analyze_cnv_data-3_invalid_header');
###############################################################################

##### test analyze_cnv_data-4_invalid-data ####################################
@cnv_files = ();
$cnv_files[0] = "$dir/spc/testing_cnv_invalid_data.spc";
dies_ok(sub{Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found)}, 'analyze_cnv_data-4_invalid_data');
###############################################################################

##### test analyze_cnv_data-5_no-files ########################################
@cnv_files = ();
dies_ok(sub{Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found)}, 'analyze_cnv_data-5_no-files');
###############################################################################

##### test analyze_cnv_data-6_tp53-file #######################################
@cnv_files = ();
$cnv_files[0] = "$dir/spc/testing_cnv_tp53.spc";
Shatterproof::analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found);
$test_file = SPtesting::test_open ($test_file, "$dir/output/TP53/TP53.spc");
open ($ref_file, "$dir/ref/TP53.spc.ref");
ok(compare($test_file, $ref_file)==0, 'analyze_cnv_data-6-1_tp53-file');
ok($tp53_mutation_found==1,'analyze_cnv_data-6-2_tp53-file');
close($test_file);
close($ref_file);
###############################################################################

#delete output directory
remove_tree("$dir/output");
