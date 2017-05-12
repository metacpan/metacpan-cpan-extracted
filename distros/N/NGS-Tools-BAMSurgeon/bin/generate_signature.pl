#!/usr/bin/env perl

### generate_signature.pl ############################################################################
# Generate mutation input varfile according to the Trinucleotide Signature and Proportions specified
# - read the signatures file table for mutation types and probabilities
# - calculate mutation number and probabilities for each signature specified
# - randomly choose positions in the chromosome according to mutation type (BY INDEPENDENT SAMPLING)
# - specify chromosome, start, end, vaf, and alternative base in BEDfile format as output (varfile)
# - take in custome mutations vcf file and incorporate according to chromosome
# - take in cancer file and cancer name to generate cancer proportioned mutations and rates
# - take in covered bases bed file and only spike in mutation in bases with over 10x coverage

# Usage: <generate_signature.pl> [options] [file ...]
	# Options:
	# --help				brief help message
	# --man				full documentation
	# --config			configuration file in YAML format containing signature information (Required)
	# --chromosome        the chromosome that mutations are generated for (Required)
	# --cb_bed            the bed file for the callable bases of the chromosome (default = "None")
	# --mut_num			number of sites to generate (default = 0)
	# --mut_rate			rate of mutation to generate (default = 0)
	# --seed              seed used for reproducible random mutation location generation (default = "None")
	# --mut_file          file to output mutations to (default = "./mut_file.txt")
	# --minvaf            minimum variant allele fraction (default = 0.25)
	# --maxvaf            maximum variant allele fraction (default = 0.5)
	# --vafbeta1          left shape parameter for beta distribution of VAFs (default = 2.0)
	# --vafbeta2          right shape parameter for beta distribution of VAFs (default = 2.0)


### HISTORY #######################################################################################
# Version		Date		Developer		Comments
# 0.01			2015-05-15	lliu     		Initial code development.
#
# 0.02			2016-01-10	lliu			Incorporate replication timing effect in mutation rate
#				
# 0.03			2016-05-01	lliu			Incorporate mutation rate and signature variations
#
#
### INCLUDES ######################################################################################
use NGS::Tools::BAMSurgeon::Helper;
use warnings;
use strict;
use Carp;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Path qw(make_path);   # makes directories given paths
use FindBin qw($Bin);           # finds bin where this method was invoked
use Path::Class;
use YAML qw(LoadFile);
use YAML::Tiny;
use Data::Dumper;
use List::MoreUtils qw( each_array );
use POSIX qw(strftime);
use POSIX qw(ceil);
use Bio::SeqIO;                 # reads reference genome fasta file
use Bio::SeqIO::fasta;
use Math::Random;
use POSIX qw(ceil);
use File::ShareDir ':ALL';

### COMMAND LINE DEFAULT ARGUMENTS ################################################################
# list of arguments and default values go here as hash key/value pairs
our %opts = (
	config			            => "$Bin/../share/config.yaml",	### the yaml config file
	chromosome 					=> undef,
	reference					=> undef,
	cb_bed                      => undef,            						### full path to chromosome callable bases bed file
	mut_num                     => 0,
	mut_rate                    => 0,                 						
	seed                        => "None",            						###seed to make reproducible random picks
	mut_file                    => "./snv_mutations.txt", 					###file to output mutations to
	);

$opts {'scripts'} = {
	};

### MAIN CALLER ###################################################################################
my $result = main();
exit($result);

### FUNCTIONS #####################################################################################

### main ##########################################################################################
# Description:
# 		Main subroutine for program
# Input Variables:
# 		%opts = command line arguments
# Output Variables:
# 		N/A
sub main {
	GetOptions(
		\%opts,
		"help|?",
		"man",
		"config|c=s" => \$opts{'config'},		### YAML file,
		"chromosome|chrom=s" => \$opts{'chromosome'},
		"reference|ref=s" => \$opts{'reference'},
		"cb_bed=s" => \$opts{'cb_bed'},
		"mut_num|n:i" => \$opts{'mut_num'},
		"mut_rate:f" => \$opts{'mut_rate'},
		"seed:i" => \$opts{'seed'},
		"mut_file|mf:s" => \$opts{'mut_file'},
		) or pod2usage(64);

	if ($opts{'help'}) { pod2usage(1) };
	if ($opts{'man'}) { pod2usage(-exitstatus => 0, -verbose => 2) };

	### check for undef arguments in %opts ###
	while(my ($arg, $value) = each(%opts)) {
		if (!defined $value) {
			print("ERROR: Missing argument $arg\n");
			pod2usage(128);		# prints out SYNOPSIS
			}
		} # while

	#load seed
	if ($opts{'seed'} eq 'None') {
		srand;
	} else {
		srand($opts{'seed'});
		random_set_seed_from_phrase($opts{'seed'});
		}

	#read in files
	my $config = YAML::LoadFile($opts{'config'});
	my $cb_bed = $opts{'cb_bed'};
	my $chromosome = $opts{'chromosome'};

	#read in chromosome genome
	my $genome = Bio::SeqIO->new(-file => "<$opts{'reference'}",
									-format => "largefasta");
	my $primary_id;
	my $seq;
	while ($seq = $genome->next_seq){
		$primary_id = $seq->primary_id;
		last if ($primary_id eq $chromosome);
	} 

	croak "ERROR: chromosome $chromosome inputted not found in the reference genome given" if ($primary_id ne $chromosome);

	#read in signature file
	my $signature_file = dist_file('NGS-Tools-BAMSurgeon',  'signatures.txt');
	croak "ERROR: no signatures file given, please use --picksomatic to generate random mutations" if (not $signature_file);
	my $signatures = &read_signature($signature_file);

	#read in proportions from config file
	my ($signature, $mut_rate, $vaf_param) = &read_config($config, $signatures, $config->{'cancer'}->{'sig_vary'});

	#determine number of mutations to pick and basic information of the chromosome
	my $num_picks;
	my $min_loc; # smallest covered base location
	my $max_loc; # largest covered base location
	my $bases; # number of covered bases
	if ($opts{'mut_rate'} != 0){ #if mutation rate is given
		$mut_rate = $opts{'mut_rate'};
		($num_picks, $min_loc, $max_loc, $bases) = &calculate_muts($mut_rate, $cb_bed, $chromosome);
	} elsif ($mut_rate != 0){ #if given cancer
		($num_picks, $min_loc, $max_loc, $bases) = &calculate_muts($mut_rate, $cb_bed, $chromosome);
	} else { #use default mutation rate
		($num_picks, $min_loc, $max_loc, $bases) = &calculate_muts(0.0000002, $cb_bed, $chromosome);
		}
	if ($opts{'mut_num'} != 0) { # if mutation number is given, takes precedence
		$num_picks = $opts{'mut_num'};
		say ("INFO: choosing $num_picks mutations.");
	} else {
		say ("INFO: choosing $num_picks mutations with mutation rate of $mut_rate.");
	}
	
	my $locations = []; #chosen mutations
	my %loc = (); #variable for testing for duplicate locations
	my $vcf_num = 0;

	#read vcf file and extract relevant mutations
	if ($config->{'vcf_file'}) {
		my $vcf_file = $config->{'vcf_file'};
		my $vcf_mutations = &read_vcf($vcf_file, $chromosome);
		my @vcf_muts;

		foreach my $i (0..scalar(@{$vcf_mutations})-1) {
			if (exists $loc{${${$vcf_mutations}[$i]}[1]}) {
				say ("WARN: duplicated location in vcf file, omitted");
			} else {
				my $vaf = &choose_vaf($vaf_param);
				push (@vcf_muts, [${${$vcf_mutations}[$i]}[0], ${${$vcf_mutations}[$i]}[1], ${${$vcf_mutations}[$i]}[1], $vaf, ${${$vcf_mutations}[$i]}[2]]);
				$loc{${${$vcf_mutations}[$i]}[1]} = 1;
				}
			}

		$vcf_num = scalar(@vcf_muts);
		say ("INFO: added $vcf_num SNVs from vcf file");
		push (@{$locations}, @vcf_muts);

		$num_picks -= $vcf_num;
		say ("INFO: choosing $num_picks after subtracting from vcf file");
		}

	#read in replication timing
	my $timing_effect = $config->{'rep_time_effect'};
	my $rep_time_file = dist_file('NGS-Tools-BAMSurgeon',  'imputed_byref.csv');
	$timing_effect = 1 if ((!defined $timing_effect) & (defined $rep_time_file));
	my $rep_time = &read_replication_time($rep_time_file, $chromosome, $timing_effect);

	my $i = 1; #number chosen so far
	my @alt_C = ('A', 'T', 'G');
	my @alt_T = ('A', 'C', 'G');

	my $current_signature = {};

	while ($i <= $num_picks) {

		my $vaf = &choose_vaf($vaf_param);

		my $location = []; #current mutation in construction
		push (@{$location}, $chromosome); #chrom[0]

		my ($base, $tri_region) = &sample_base($bases, $min_loc, $max_loc, $cb_bed, $seq);
		push (@{$location}, $base); #location[1]
		push (@{$location}, substr($tri_region, 1, 1)); #ref[2]

		my ($mut_prob, $NA_use) = &mutation_probability($base, $rep_time);

		if ($NA_use){
			say ("WARN: position with no replication information ".join("  ", @{$location})." chosen at number $i, choosing again");
			next;
		}

		if (exists $loc{${$location}[1]}) {
			say ("WARN: duplicated location ".join("  ", @{$location})." chosen at number $i, choosing again");
			next;
		}

		#Layer 1: replication time
		my $rand_num = random_uniform(1, 0, 1);
		next if ($rand_num > $mut_prob);

		#Layer 2: signature
		my $alt;
		if (substr($tri_region, 1, 1) eq 'C'){
			$alt = $alt_C[rand @alt_C];
		} else {
			$alt = $alt_T[rand @alt_T];
		}
		#my $alt_rand = random_uniform(1, 0, 1);
		#next if ($alt_rand > ($signature->{$tri_region}->{$alt} / $signature->{'max'}));
		if (!$current_signature->{$tri_region}->{$alt}){
			$current_signature->{$tri_region}->{$alt} = 0;
		}
		my $current_rate = $current_signature->{$tri_region}->{$alt} / $i;
		next if ($current_rate >= $signature->{$tri_region}->{$alt});

		#Passed all layers
		push (@{$location}, $alt); #alt[3]
		$current_signature->{$tri_region}->{$alt} += 1;

		#actual format required by BAMsurgeon
		#'chr', 'start', 'end', 'vaf', 'alt'
		push (@{$locations}, [${$location}[0], ${$location}[1], ${$location}[1], $vaf, ${$location}[3]]);

		#used for testing with R script
		#'chr', 'start', 'ref', 'alt'
		#push (@{$locations}, $location); 
		say "INFO: ".$i." mutations chosen" if ($i % 100 == 0);
		$loc{${$location}[1]} = 1;
		$i += 1;
		}
 
	my $mut_file = $opts{'mut_file'};

	#sort mutations by ascending location
	@{$locations} = sort { $a->[1] <=> $b->[1] } @{$locations};

	(open my $mutation_file, ">", "$mut_file") or croak "ERROR: unable to open mut_file file at: $mut_file";
	foreach my $location (@{$locations}) {
		print ($mutation_file join("\t", @{$location})."\n");
		}
	close ($mutation_file);

	return 0;
	} #main

### read_signature #################################################################################
# Description:
# 		Read the signature file provided assuming that the third column is "Somatic Mutation Type"
# Input Variables:
# 		$signature_file = signature file
# Output Variables:
# 		$signatures = all of the signatures stored in a hash of hash of hash

sub read_signature {
	my ($signature_file) = @_;
	say "INFO: reading signatures file $signature_file";
	
	open (my $sig_in, '<', $signature_file) or croak "ERROR: unable to open signatures file at : $signature_file";

	my $signatures = {};

	my $header = <$sig_in>;
	$header =~ s/\W+$//;
	my @header = split('\t', $header);

	#read the header line and make a key for each of the valid mutations
	foreach my $signature (@header){
		#if ($signature =~ m/Signature\s\d/) { #assume that signatures that begin with a number are validated
		if ($signature =~ m/Signature/){
			$signatures->{$signature} = {};
		} else {
			say ("WARN: unvalidated signature $signature dropped") if ($signature =~ m/Signature/);
			}
		}

	#read each line and assign the probabilities of each mutation to each signature
	while (<$sig_in>){
		s/\W+$//;
		my %row;
		@row{@header} = split('\t');
		foreach my $signature (keys %$signatures){
			$signatures->{$signature}->{$row{$header[2]}} = $row{$signature}; #assume that the 3rd column is 'somatic mutation type'
			}
		}
	close($sig_in);

	#validate that each signature has probabilities rdding up to 1
	foreach my $signature (keys %{$signatures}) {
		my $sum = 0;
		foreach my $mutation (keys %{$signatures->{$signature}}) {
			$sum += $signatures->{$signature}->{$mutation};
			}
		$sum = int(($sum * 10000.0) + 0.5) / 10000.0;

		if ($sum != 1.0000) {
			delete $signatures->{$signature};
			say ("WARN: $signature dropped for probabilities not added up to 1");

			print $sum;

			}
		}

	return ($signatures);
	}

### read_config ####################################################################################
# Description:
# 		Read the config hash specified by the YAML file
# Input Variables:
# 		$config = config of signature type or cancer type to simulate
#		$signatures = the hash of probabilities of all signatures from file
#		$sig_vary = file containing variation in cancer signature
# Output Variables:
# 		$signature = the overall trinucleotide signature to follow
#		$mut_rate = the mutation rate determined by the cancer or by default
sub read_config {
	my ($config, $signatures) = @_;

	my $proportions = {};
	my $mut_rate = 0.000001;

	#checking if signature or cancer information present, if both present signature info is used
	if ((not $config->{'signatures'}) && (not $config->{'cancer'}->{'name'})) {
		croak "ERROR: no signature or cancer type has been specified, please use randomsites.py to generate random mutations";

	} elsif (not $config->{'signatures'}) {
		#read in cancer related files
		my ($cancer_sigs) = &read_cancer($config, $config->{'cancer'}->{'mut_vary'});

		my $cancer = $config->{'cancer'}->{'name'};
		$cancer = lc ($cancer);

		my $proportions_sum = 0;
		my @sig_list;
		my $pro_hash;

		#TODO find better way to generation variation in signatures
		if ((defined $config->{'cancer'}->{'sig_vary'}) && ($config->{'cancer'}->{'sig_vary'}) == 1) {
			#read in cancer signatures variation file
			my $yaml = YAML::Tiny->read(dist_file('NGS-Tools-BAMSurgeon',  'cancer_sig_vary.yaml'));
			my $cancer_var = $yaml->[0];
			#save lowercase cancer keys
			foreach my $cancer (keys %{$cancer_var}) {
				my $mod_cancer = lc ($cancer);
				$cancer_var->{$mod_cancer} = $cancer_var->{$cancer};
			}
			if ($cancer_var->{$cancer}){
				#pick a signature proportion for the cancer at random
				my @cancer_pp = @{$cancer_var->{$cancer}};
				my $chosen_pp = $cancer_pp[rand @cancer_pp];
				@sig_list = (keys $chosen_pp);
				$pro_hash = $chosen_pp;
				}
			else {
				say "WARN: sig_vary chosen as 1 but no sig_vary information available for ".$cancer.", using default signatures";
				}

			}

		if ((!@sig_list) || (!defined $pro_hash)){
			croak "ERROR: $cancer signature is not defined in the cancer files provided" if (scalar (keys %{$cancer_sigs->{$cancer}}) <= 1);
			@sig_list = keys %{$cancer_sigs->{$cancer}};
			$pro_hash = $cancer_sigs->{$cancer};
		}
		my @requests = ();
		foreach my $request (@sig_list) {
			next if ($request eq 'Mut rate');
			if ($signatures->{$request}) {
				push (@requests, $request);
				$proportions_sum += $pro_hash->{$request};
			} else {
				say "WARN: $request is not defined in signatures file, proportions recalculated";
			}
		}
		say ("INFO: using signature information of $cancer");
		foreach my $request (@requests) {
			next if ($request eq 'Mut rate');
			$proportions->{$request}->{'mutations'} = $signatures->{$request};
			$proportions->{$request}->{'proportion'} = ($pro_hash->{$request})/$proportions_sum;
			say "INFO:	$request with proportion ".$proportions->{$request}->{'proportion'};
		}
		if (!$cancer_sigs->{$cancer}->{'Mut rate'}){
			say "WARN: $cancer mutation rate is not defined in the cancer files provided, using default of 0.0000002 if necessary";
			$mut_rate = 0.0000002;
		} else {
			$mut_rate = $cancer_sigs->{$cancer}->{'Mut rate'};
		}
	} else {
		my @requests = (keys %{$config->{'signatures'}});
		my $proportions_sum = 0;
		say ("INFO: using specified signature information");
		foreach my $request (@requests) {
			my $mod_request = ucfirst (lc ($request));
			$mod_request =~ s/1a$/1A/;
			$mod_request =~ s/1b$/1B/;
			croak "ERROR: $mod_request is not defined in signatures file" if (not $signatures->{$mod_request});
			$proportions->{$request}->{'mutations'} = $signatures->{$mod_request};
			$proportions->{$request}->{'proportion'} = $config->{'signatures'}->{$request};
			$proportions_sum += $proportions->{$request}->{'proportion'};
			say "INFO:	$request with proportion ".$proportions->{$request}->{'proportion'};
		}
		croak "ERROR: signatures proportions not adding up to 1" if ($proportions_sum != 1);
	}

	my $signature = &concat_signature($proportions);

	my $vaf_param;
	$vaf_param->{'minvaf'} = (defined $config->{'minvaf'})? $config->{'minvaf'} : 1;
	$vaf_param->{'maxvaf'} = (defined $config->{'maxvaf'})? $config->{'maxvaf'} : 1;
	$vaf_param->{'vafbeta1'} = (defined $config->{'vafbeta1'})? $config->{'vafbeta1'} : 2.0;
	$vaf_param->{'vafbeta2'} = (defined $config->{'vafbeta2'})? $config->{'vafbeta2'} : 2.0;

	return ($signature, $mut_rate, $vaf_param);
	}

### read_cancer ####################################################################################
# Description:
# 		Read the config hash with regards to the cancer information
# Input Variables:
# 		$config = config of signature type or cancer type to simulate
# 		$mut_vary = file containing information of the mutation rate distribution of cancers
# Output Variables:
# 		$cancer_sigs = the trinucleotide signatures and mutation rate information of cancers
sub read_cancer {
	my ($config, $mut_vary) = @_;

	my $cancer_sigs = YAML::LoadFile(dist_file('NGS-Tools-BAMSurgeon',  'cancer_sigmut.yaml'));
	#save lowercase cancer keys
	foreach my $cancer (keys %{$cancer_sigs}) {
		my $mod_cancer = lc ($cancer);
		$cancer_sigs->{$mod_cancer} = $cancer_sigs->{$cancer};
		}

	#alter chosen cancer mutation and signature according to vary options
	my @cancers = (keys %{$cancer_sigs});
	my $cancer = $config->{'cancer'}->{'name'};
	$cancer = lc ($cancer);
	my @full_names = grep/$cancer/i, @cancers;

	#TODO change variation to scale
	if ((defined $mut_vary) && $mut_vary == 1) {
		#read in mutation rate variation file
		my $yaml = YAML::Tiny->read(dist_file(  'NGS-Tools-BAMSurgeon',  'cancer_mut_vary.yaml'));
		my $cancer_muts = $yaml->[0];
		#save lowercase cancer keys
		foreach my $cancer_mut (keys %{$cancer_muts}) {
			my $mod_cancer = lc ($cancer_mut);
			$cancer_muts->{$mod_cancer} = $cancer_muts->{$cancer_mut};
		}

		if (not $cancer_muts->{$cancer}){
			say "WARN: mut_vary chosen as 1 but no mut_vary information available for ".$cancer.", using default mutation rates";
			}
		else {
			foreach my $name (@full_names) {
				$cancer_sigs->{$name}->{'Mut rate'} = &cancer_mut_sim($cancer_muts->{$cancer});
				}
			#also add in name in case it is not found in sigmut file
			$cancer_sigs->{$cancer}->{'Mut rate'} = &cancer_mut_sim($cancer_muts->{$cancer});
			}
		}

	return ($cancer_sigs);
	}

### cancer_mut_sim ###############################################################################
# Description:
# 		Simulate the mutation rate of the cancer according to 2 Normal Gaussian mixture model *see R script
# Input Variables:
#		$cancer_model: the lambda, mu, sigma parameters of the specific cancer
# Output Variables:
# 		$rate = the simulated mutation rate of the cancer
sub cancer_mut_sim {
	my ($cancer_model) = @_;

	my $mu;
	my $sigma;
	my $rate;

	my $rand_num = random_uniform(1, 0, 1);

	if ($rand_num <= $cancer_model->{'lambda'}->[0]){
		$mu = $cancer_model->{'mu'}->[0];
		$sigma = $cancer_model->{'sigma'}->[0];
	} else {
		$mu = $cancer_model->{'mu'}->[1];
		$sigma = $cancer_model->{'sigma'}->[1];
	}

	my $log_rate = random_normal(1, $mu, $sigma);
	$rate = 10**$log_rate/1000000;

	return ($rate);
	}

### concat_signature ###############################################################################
# Description:
# 		Calcualte the overall trinucleotide signature
# Input Variables:
#		$proportion = the mutations and their proportion makeup of the signature
# Output Variables:
# 		$signature = the overall trinucleotide signature to follow

sub concat_signature {
	my ($proportions) = @_;

	my @nucleotides = ('A', 'T', 'C', 'G');
	my $signature = {};

	#generate all trinucleodie combinations
	foreach my $first (@nucleotides) {
		foreach my $middle ('C', 'T') {
			foreach my $last (@nucleotides) {
				$signature->{"$first$middle$last"} = {};
				}
			}
		}

	#cumulate the effects of all signatures
	foreach my $mut_sig (keys %{$proportions}) {
		foreach my $mutation (keys %{$proportions->{$mut_sig}->{'mutations'}}){
			$proportions->{'Total'}->{'mutations'}->{$mutation} += $proportions->{$mut_sig}->{'mutations'}->{$mutation} * $proportions->{$mut_sig}->{'proportion'};
			}
		}

	#find the maximum for normalization
	my $pro_max = 0;
	foreach my $mutation (keys %{$proportions->{'Total'}->{'mutations'}}){
		if ($proportions->{'Total'}->{'mutations'}->{$mutation} > $pro_max){
			$pro_max = $proportions->{'Total'}->{'mutations'}->{$mutation};
			}
		}

	#assign to "XXX" -> "ALT" format
	foreach my $mutation (keys %{$proportions->{'Total'}->{'mutations'}}){
			my $mut_tri = substr($mutation, 0, 1).substr($mutation, 2, 1).substr($mutation, 6, 1);
			my $alt_base = substr($mutation, 4, 1);
			$signature->{$mut_tri}->{$alt_base} += $proportions->{'Total'}->{'mutations'}->{$mutation};
		}

	$signature->{'max'} = $pro_max;

	return ($signature);
	}

### sample_base ###################################################################################
# Description:
# 		Randomly sampling a base location in the genome, in the covered bases given
# Input Variables:
#		$bases = total number of callable bases
#		$min_loc = minimum location of covered base
#		$max_loc = maximum location of covered base
#		$cb_bed = cb_bed file
# 		$seq = the genome sequence
# Output Variables:
# 		$base = the randomly sampled location
# 		$tri_region = the trinucleotide context of the location

sub sample_base {
	my ($bases, $min_loc, $max_loc, $cb_bed, $seq) = @_;
	my $flag = 0;
	my $base;
	my $tri_region;
	while (!$flag){
		my $position = random_uniform_integer(1, 1, $bases);

		$base = &find_location($position, $cb_bed);

		$tri_region = $seq->subseq($base-1,$base+1);
		$tri_region = uc($tri_region);

		my $ref = substr($tri_region, 1, 1);
		if ($ref =~ m/A|G/) {
			$tri_region =~ tr/ATCG/TAGC/;
			$tri_region =~ s/^(.)(.)(.)$/$3$2$1/;
		}
		
		#skip regions that are not given in the reference genome
		$flag = ($tri_region !~ m/N+/);
		say "WARN: callable trinucleotide region ".$base." ".$tri_region." contains N in reference genome, choosing again" if (!$flag);	
	}

	return ($base, $tri_region);
	}

### find_location #############################################################################
# Description:
# 		Find location of base in covered bases
# Input Variables:
#		$position = position of base in covered bases
# 		$cb_bed = covered bases bed file
# Output Variables:
# 		$base = location of base

sub find_location {
	my ($position, $cb_bed) = @_;
	my $base;
	my $sum = 0;
	open (my $bed_in, '<', $cb_bed) or croak "ERROR: unable to open bed file at : $cb_bed";
	while (<$bed_in>) {
		s/\W+$//;
		my @row = split('\t');
		my $pos = $position + $row[1] - 1;
		if ($pos >= $row[2]){
			$position = $position - ($row[2] - $row[1]);
		} else {
			$base = $pos;
			last;
			}
		}
	close($bed_in);

	#correct for the fact that bed files are 0 based
	$base = $base + 1;

	return ($base);
	}

### mutation_probability #########################################################################
# Description:
# 		Calcualte the probability that the given base would be mutated, based on replication timing
# Input Variables:
#		$base = the location of the base
#		$rep_time = replicating timing data
# Output Variables:
# 		$mut_prob = probability of mutation of given base
#		$NA_use = whether the region has no replication timing information

sub mutation_probability {
	my ($base, $rep_time) = @_;

	my $mut_prob;
	my $NA_use = 0;

	my $base_region = ceil($base / 100000) - 1;
	$mut_prob = $rep_time->[$base_region];

	if (!defined $mut_prob) {
			$NA_use = 1;
		}

	return ($mut_prob, $NA_use);
	}

### read_replication_time #########################################################################
# Description:
# 		Read and process file storing replication time of the genome
# Input Variables:
#		$rep_time_file = csv file storing chromosome location and replication time
#		$chromosome = the current chromosome
#		$timing_effect = how much the mutation rate of regions should be affected by replication
# Output Variables:
# 		$rep_times = store replciation times of chromosome locations

sub read_replication_time {
	my ($rep_time_file, $chromosome, $timing_effect) = @_;

	my $rep_time = [];
	my @equal_time = (1)x3000;

	$chromosome = 23 if ($chromosome eq 'X');

	if (not $rep_time_file){
		say "WARN: no replication timing effect file given, treating all bases as with same replication time";
		$rep_time = \@equal_time;
		return $rep_time;
	}

	if ($chromosome eq 'Y'){
		say "WARN: no replication timing available for chromosome Y, treating all bases as with same replication time";
		$rep_time = \@equal_time;
		return $rep_time;
	}

	open (my $csv_in, '<', $rep_time_file) or croak "ERROR: unable to open vcf file at : $rep_time_file";
	my $header_line = <$csv_in>;
	$header_line =~ s/\W+$//;
	my @header = split('\t', $header_line);
	my ($index) = grep {$header[$_] eq 'corr' } (0 .. @header-1);

	if (not defined $index){
		say "WARN: replication timing effect file does not have \'corr\' column, treating all bases as same";
		$rep_time = \@equal_time;
		close($csv_in);
		return $rep_time;
	}

	my $min = 2000;
	my $max = -2000;

	#read each line and assign the mutation rate to the chromosome location
	while (<$csv_in>){
		s/\W+$//;
		my $row = [split('\t')];
		next if (${$row}[0] != $chromosome); #skip to current chromosome

		if (${$row}[$index] eq "NA" || ${$row}[$index] eq "NaN"){
			push (@{$rep_time}, undef);
		} else{ 
			my $corr = ${$row}[$index];
			$corr = 10**$corr;
			push (@{$rep_time}, $corr);
			$max = $corr if ($corr > $max);
			$min = $corr if ($corr < $min);
			}
		}
	close($csv_in);

	my $diff = $max - $min;

	my $scale = ($max - $diff * $timing_effect) / $max;
	#my $scale = 1 - abs(($diff * $timing_effect) / $max);

	#scale the range by timing effect
	foreach my $i (0..scalar(@{$rep_time})-1) {
		next if (!defined $rep_time->[$i]);
		$rep_time->[$i] = ((1 - $scale)*($rep_time->[$i] - $min)) / $diff + $scale;
	}
	return ($rep_time);
	}

### rep_mut_correlation ###########################################################################
# Description:
# 		Use correlation to calculate mutation rate of region by replication time
# Input Variables:
#		$replication = replication time of region
#		$$rep_mut_numbers = contains coefficients and values used to calculate mutation rate
# Output Variables:
# 		$with_error = mutation of region calculated

sub rep_mut_correlation {
	my ($replication, $rep_mut_numbers) = @_;

	my $slope = $rep_mut_numbers->{'rep_mut_regression'}->{'slope'};
	my $intercept = $rep_mut_numbers->{'rep_mut_regression'}->{'intercept'};
	my $se = $rep_mut_numbers->{'rep_mut_regression'}->{'se'};

	my $rep_mut = $replication*$slope + $intercept;

	#my $with_error = random_normal(1, $rep_mut, $se);

	return ($rep_mut);
	}

### choose_vaf ###############################################################################
# Description:
# 		Choose the variant allele fraction according to parameters described
# Input Variables:
#		$vaf_param = the parameters for generating vaf
# Output Variables:
# 		$vafs = the vafs generated

sub choose_vaf {
	my ($vaf_param) = @_;

	my $vaf = Math::Random::random_beta(1, $vaf_param->{'vafbeta1'}, $vaf_param->{'vafbeta2'});

	$vaf = $vaf * ($vaf_param->{'maxvaf'}-$vaf_param->{'minvaf'}) + $vaf_param->{'minvaf'};

	return ($vaf);
	}

### calculate_muts #################################################################################
# Description:
# 		Calculate the number of picks from the covered bases
# Input Variables:
#		$mut_rate = mutation rate per callable base
# 		$cb_bed = bed file containing callable bases
#       $chromosome = the fasta chromosome
# Output Variables:
# 		$SNV_num = number of SNVs to spike in

sub calculate_muts {
	my ($mut_rate, $cb_bed, $chromosome) = @_;

	my $bases = 0;
	my $min_loc = 0;
	my $max_loc;

	open (my $bed_in, '<', $cb_bed) or croak "ERROR: unable to open bed file at : $cb_bed";

	my $first_line = <$bed_in>;
	my @first_row = split('\t', $first_line);
	croak "ERROR: primary_id of fasta file not the same as chromosome of bed file given" if ($first_row[0] ne $chromosome);
	#bed file includes position at chromSTART and excludes position at chromEND
	#range calculated by END - START + 1 - 1
	$bases += ($first_row[2] - $first_row[1]);
	$min_loc = $first_row[1];

	my @last_row;
	while (<$bed_in>) {
		s/\W+$//;
		my @row = split('\t');
		croak "ERROR: primary_id of fasta file not the same as chromosome of bed file given" if ($row[0] ne $chromosome);
		
		$bases += ($row[2] - $row[1]);
		@last_row = @row;
		}
	close($bed_in);
	$max_loc = $last_row[2] - 1;
	print "INFO: Chromosome: $chromosome\tCovered bases: $bases\tMin: $min_loc\tMax: $max_loc\n";


	my $SNV_num = 200;
	if ($bases){
		$SNV_num = $bases * $mut_rate;
		$SNV_num = sprintf("%.0f", $SNV_num);
	} else {
		say ("INFO: cannot obtain readcount information for chromosome $chromosome, picking 200 mutations.");
	}

	return ($SNV_num, $min_loc, $max_loc, $bases);
	}

### check_location ################################################################################
# Description:
# 		Check if the location generated is one of the callable bases
# Input Variables:
#		$location = location to spike in mutation
# 		$cb_bed = covered bases bed file
# Output Variables:
# 		$flag = 0 for location exists, 1 for location not covered

sub check_location {
	my ($location, $cb_bed) = @_;

	# preset flag assuming that location is NOT found
	my $flag = 1;

	#correct for the fact that bed files are 0 based
	my $pos = $location - 1;
	open (my $bed_in, '<', $cb_bed) or croak "ERROR: unable to open bed file at : $cb_bed";
	while (<$bed_in>) {
		s/\W+$//;
		my @row = split('\t');
		#bed file includes position at chromSTART and excludes position at chromEND
		if ($pos >= $row[1] && $pos < $row[2]){
			$flag = 0;
			last;
			}
		}
	close($bed_in);

	return ($flag);
	}

### read_vcf #################################################################################
# Description:
# 		Read the vcf file with the required mutations and record those applicable to this chromosome
# Input Variables:
# 		$vcf_file = vcf file
#		$chromosome = the current chromosome
# Output Variables:
# 		$vcf_mutations = the mutations listed in the vcf file for the current chromosome

sub read_vcf {
	my ($vcf_file, $chromosome) = @_;
	say "INFO: reading vcf file $vcf_file";
	
	open (my $vcf_in, '<', $vcf_file) or croak "ERROR: unable to open vcf file at : $vcf_file";

	my $vcf_mutations = [];

	while (<$vcf_in>) {
		s/\W+$//;
		my @row = split('\t');
		#$row[0] =~ s/chr//;
		if ($row[0] eq $chromosome) {
			# check that line represents a SNV
			if (length($row[3]) == 1 && length($row[4]) == 1) {
				push (@{$vcf_mutations}, [$chromosome, $row[1], $row[4]]);
				} 
			}
		}
	close($vcf_in);

	return ($vcf_mutations);
	}

__END__
