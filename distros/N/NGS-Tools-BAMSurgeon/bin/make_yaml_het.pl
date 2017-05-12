#!/usr/bin/env perl

### bam_YAML_creater.pl #########################################################################
# Generate HET YAML file using a template yaml structure based upon the node structure and proportions

### HISTORY #######################################################################################
# Version		Date		Developer		Comments
# 0.01			2015-05-25	ssivanandan     		Initial code development.
#
### INCLUDES ######################################################################################
use warnings;
use strict;
use Carp;
use Getopt::Long;
use Pod::Usage;
use Path::Class;
use NGS::Tools::BAMSurgeon::Helper;
use Params::Validate qw(:all);
use YAML qw(LoadFile DumpFile Dump);
use Data::Dumper;
use POSIX qw(strftime ceil floor); 
use Math::Random;

our %opts = (
	yaml_template => undef,
	yaml_dir => undef,
	sex => undef,
	probability_wce => 1,
	cb_dir => '/path/to/callable_bases_bed_dir/'
);

#### MAIN CALLER #####################################################################################
my $result = main();
exit($result);

#### main ############################################################################################
sub main{

	GetOptions(
		\%opts,
		"help|?",
		"man",
		"yaml_template:s",
		"yaml_dir:s",
		"probability_wce:s",
		"name:s",
		"sex:s",
		"cb_dir:s" => \$opts{cb_dir}
		) or pod2usage(64);

	if ($opts{'help'}) { pod2usage(1) };
	if ($opts{'man'}) { pod2usage(-exitstatus => 0, -verbose => 2) };

	my $yaml_dir_str = File::Spec->rel2abs($opts{'yaml_dir'});
	my $yaml_dir = dir($yaml_dir_str);

	File::Path::make_path("$yaml_dir");

	my ($types, $array, $string)=YAML::LoadFile($opts{'yaml_template'});

	my @chr = (1..22);
	push @chr,'X';
	if($opts{sex} eq 'M'){
		push @chr, 'Y';
		}

	
	# find all collapsed bed files in the directory
	# Callable bases calculation
	my $cb_dir = dir($opts{'cb_dir'});
	opendir(DIR, $cb_dir) or croak "unable to open bed directory at : $cb_dir";
	my @cb_files = ();
	while (my $file = readdir(DIR)) {
		next unless (-f "$cb_dir/$file");
		next unless ($file =~ m/\_collapsed.bed$/);
		push (@cb_files, $file);
		}
	@cb_files = sort @cb_files;
	# End of callable bases files retrieval

	my $yaml = {};
	my $cb = {};

	foreach my $bed_file (@cb_files) {
		my $cb_bed = "$cb_dir/$bed_file";
		my ($chrom,$bases) = &calculate_bases($cb_bed);
		$cb->{$chrom} = $bases;
		}

	my @seen_chrs = ();
	foreach my $template (keys $types->{templates}) {
		my $template_chrs = $types->{templates}->{$template}->{chrs};
		my @template_chrs = split(',', $template_chrs);

		foreach my $chrom (@template_chrs){
			if (not grep $_ eq $chrom, @chr) {
				print "ERROR: Chromosome $chrom not acceptable\n";
				exit(1);
				}
			elsif (grep $_ eq $chrom, @seen_chrs) {
				print "ERROR: Chromosome $chrom is duplicated\n";
				exit(1);
				}
			push @seen_chrs, $chrom;
			
			if($opts{sex} eq 'F' || ($opts{sex} eq 'M' && $chrom ne 'X' && $chrom ne 'Y')){
				$yaml->{$chrom}={input_a => "./chr$chrom/phase.0.T.bam",input_b => "./chr$chrom/phase.1.T.bam",root => {}};
				}
			else{
				$yaml->{$chrom}={input_a => "./chr$chrom/phase.0.T.bam",input_b => "",root => {}};
				}
			$yaml->{$chrom}{root} = make_yaml('node',$yaml->{$chrom}{root},'template_node',$types->{templates}->{$template}->{root},'chrom',$chrom,'cb',$cb,'probability_wce',$opts{probability_wce},'counts',$types->{counts},'rates',$types->{rates},'tree',$types->{root});
			}
		}

	if (scalar(@seen_chrs) ne scalar(@chr)) {
		my @missing_chrs;
		foreach my $chrom (@chr) {
			if (not grep $_ eq $chrom, @seen_chrs) {
				push @missing_chrs, $chrom;
				}
			}
		print "Template missing for chromosomes: ", Dumper(@missing_chrs);
		}
	DumpFile("$yaml_dir_str/$opts{name}.yaml",$yaml);
	}


### calculate_muts #################################################################################
# Description:
# 		Calculate the number of picks from the covered bases
# Input Variables:
#		$mut_rate = mutation rate per callable base
# 		$cb_bed = bed file containing callable bases
# Output Variables:
# 		$SNV_num = number of SNVs to spike in
# 		$chromosome = the chromosome of the bed file

sub calculate_bases {
	my ($cb_bed) = @_;

	open (my $bed_in, '<', $cb_bed) or croak "unable to open bed file at : $cb_bed";

	#read first line to get the chromosome
	my $first_line = <$bed_in>;
	$first_line =~ s/\W+$//;
	my @row = split('\t', $first_line);
	my $chromosome = $row[0];
	$chromosome =~ s/chr//;
	my $bases = ($row[2]-$row[1]) + 1;

	while (<$bed_in>) {
		s/\W+$//;
		my @row = split('\t');
		$row[0] =~ s/chr//;
		croak "BED file not for single chromosome" if ($chromosome ne $row[0]);

		#bed is inclusive of start and end
		$bases += ($row[2]-$row[1]) + 1;
		}
	close($bed_in);

	return ($chromosome,$bases);
	}



### make_yaml #################################################################################
# Description:
# 		Recursive function to build YAML file from template
# Input Variables:
#		node = Node in the yaml file
# 		template_node = Node in the template file
#		chrom = Chromosome 
#		cb = Callable bases HASHREF
#		probability_wce = Probability of Whole chromosome event introduced randomly
# Output Variables:
#		YAML node structure (object)
#	

sub make_yaml{
	my %args = validate(
		@_,
		{
		node => {
			type => HASHREF,
			required => 1,
		},
		template_node => {
			type => HASHREF,
			required => 1,
		},
		chrom => {
			type => SCALAR,
			required => 1,
		},
		cb => {
			type => HASHREF,
			required => 1,
		},
		probability_wce => {
			type => SCALAR,
			required => 1,
		},
		counts => {
			type => HASHREF,
			required => 1,
		},
		rates => {
			type => HASHREF,
			required => 1,
		},
		tree => {
			type => HASHREF,
			required => 1,
		}
		});
	my $node = $args{node};
	$node->{percent} = $args{tree}->{percent};
	if(exists $args{template_node}->{mut_type} && ref($args{template_node}->{mut_type}) eq 'ARRAY'){
		$node->{mut_type}=[];
		$node->{mut_indx}=[];
		$node->{mut_arg}=[];

		foreach my $elem ( keys $args{template_node}->{mut_type}){
			my @mut_type_vals = split(' ', $args{template_node}->{mut_type}[$elem]);
			my $mut_type = $mut_type_vals[0];
			my $instances = $mut_type_vals[1];
			
			my @mut_indx_vals = split(' ', $args{template_node}->{mut_indx}[$elem]);
			
			my $mut_str = substr($mut_type,0,-2) eq 'snv' ? 'SNV'
				: substr($mut_type,0,-2) eq 'indel' ? 'Indel'
				: substr($mut_type,0,-2) eq 'sv' ? 'SV'
				: 'WCE';

			next if ($args{chrom} eq 'X' or $args{chrom} eq 'Y') and substr($mut_type,-2) eq '_b';

			if ($mut_str ne 'WCE') {
				my $mut_arg = $args{tree}->{$mut_str} / $args{counts}->{$mut_str} * $args{rates}->{$mut_str};
				$mut_arg *= 2 if $args{chrom} eq 'X' or $args{chrom} eq 'Y';
				my $muts = $args{cb}->{$args{chrom}} * $mut_arg;
				$muts /= $instances;

				$muts = int($muts+0.5) > int $muts ? ceil($muts) : floor($muts);
				next if $muts eq 0;

				foreach my $idx(@mut_indx_vals) {
					push $node->{mut_arg}, $muts ;
					push $node->{mut_type}, $mut_type;
					push $node->{mut_indx}, $idx;
					#print "Chromosome : $args{chrom} :: $args{cb}->{$args{chrom}}"
					}
				}
			else{
				my $r = random_uniform();
				if($r < ($args{probability_wce}*1.0)){
					foreach my $idx(@mut_indx_vals) {
						push $node->{mut_arg}, substr($mut_type,0,-2);
						push $node->{mut_type}, 'wce'.substr($mut_type,-2);
						push $node->{mut_indx}, $idx;
						}
					}
				}
			}
		}
	else{
		$node->{mut_type}=undef;
		$node->{mut_indx}=undef;
		$node->{mut_arg}=undef;
		}

	if(exists $args{template_node}->{children}){
		$node->{children} = [];
		foreach my $child ( keys $args{template_node}->{children}) {
			$node->{children}[$child] = {};
			$node->{children}[$child] = make_yaml('node',$node->{children}[$child],'template_node',$args{template_node}->{children}[$child],'chrom',$args{chrom},'cb',$args{cb},'probability_wce',$args{probability_wce},'counts',$args{counts},'rates',$args{rates},'tree',$args{tree}->{children}[$child]);
			}
		}
	return $node;
	}

### USAGE ###
# perl make_yaml_het.pl --yaml_template S1_template.yaml --yaml_dir output_dir --name tumour_S1 --sex M --probability_wce 1 --cb_dir /path/to/callable_bases_bed_dir/
#
#
# AUTHORS
#
# Srinivasan Sivanandan
#
# Shadrielle Melijah G. Espiritu
#
# ACKNOWLEDGEMENTS
#
# Paul Boutros, PhD, PI -- Boutros Lab
#
# Takafumi Yamaguchi -- Boutros Lab
#
# SUPPORT
#
# For support please mail << <srinivasan.iitkgp at gmail.com> >>
#
# LICENSE AND COPYRIGHT
#
# Copyright 2015 Srinivasan Sivanandan.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
#
# See http://dev.perl.org/licenses/ for more information.
#
