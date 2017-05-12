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

##### test calculate_genome_localization ######################################
$genome_mutation_density_hash_ref = Shatterproof::calculate_genome_localization($output_directory, $chromosome_copy_number_count_hash_ref, $chromosome_translocation_count_hash_ref);

#check output hash
cmp_deeply($genome_mutation_density_hash_ref, {"11"=>num(9.66885049803208e-08,1),"21"=>num(1.27810981532314e-07,1),"7"=>num(6.92601773926923e-08,1),"Y"=>num(1.35084462079471e-06,1),"17"=>num(7.62827497419037e-08,1),"2"=>num(4.11944497119558e-08,1),"22"=>num(1.41331475349378e-07,1),"1"=>num(6.8770304710581e-08,1),"18"=>num(3.9412929697988e-08,1),"16"=>num(2.92719434928999e-07,1),"13"=>num(0,1),"6"=>num(1.34583994699076e-07,1),"X"=>num(3.87312284743936e-08,1),"3"=>num(8.02218828981421e-08,1),"9"=>"0","12"=>num(4.5355061875114e-08,1),"20"=>"0","14"=>num(5.6411874756048e-08,1),"15"=>num(3.98648919016117e-08,1),"8"=>num(5.46915707833418e-08,1),"4"=>num(2.82333656865048e-07,1),"19"=>num(7.8361736929274e-08,1),"10"=>num(1.32964247236174e-07,1),"5"=>num(6.08279684078997e-08,1)}, 'calculate_genome_localization-1');
###############################################################################

#delete output directory
remove_tree("$dir/output");
