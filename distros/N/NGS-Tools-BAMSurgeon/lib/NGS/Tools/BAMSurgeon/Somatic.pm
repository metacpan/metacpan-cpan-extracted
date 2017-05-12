package NGS::Tools::BAMSurgeon::Somatic;

use warnings;
use strict;
use Carp;
use Moose::Role;
use FindBin qw($Bin);
use Params::Validate qw(:all);
use Data::Dumper;
use File::Path qw(make_path);
use YAML qw(LoadFile DumpFile Dump);
use HPCI;
use Cwd qw(abs_path);
use List::Util qw(sum min max);
use File::Basename;
use File::Copy;
use List::MoreUtils qw(each_array uniq);

our %opts = ();
our $max_total_copies = 1;

has 'leaves' => (
	isa => 'HashRef',
	is => 'rw',
	default => sub { {} }
	);

sub adjust_yaml_for_cna {
	my $self = shift;

	$self->log->info("adjust_yaml_for_cna\n");
	$self->log->info("\toriginal_somatic_profile_path: " . $self->original_somatic_profile_path . "\n");
	$self->log->info("\tadjusted_somatic_profile_path: " . $self->adjusted_somatic_profile_path . "\n");
	
	$opts{yaml} = $self->original_somatic_profile_path;
	$opts{output_dir} = $self->output_dir;
	$opts{output_yaml} = "adjusted_somatic_profile";

	my $config = YAML::LoadFile($opts{yaml});	

	my $total = {};

	# calculate total data per chromosome, per phase
	foreach my $chr (keys $config) {
		my @phases = ('a');
		if ("X" ne $chr and "Y" ne $chr) { push(@phases, 'b'); }

		foreach my $phase (@phases) {
			my ($cellularPrevalence_hash, $copyNumber_hash) = $self->_determineProfiles($config->{$chr}->{root}, $phase, {'' => 1}, '', {});

			$total->{cellularPrevalence}->{$chr}->{$phase} = $cellularPrevalence_hash;
			$total->{copyNumber}->{$chr}->{$phase} = $copyNumber_hash;
			$total->{total_copies}->{$chr}->{$phase} = 1;

			my $total_copies = 0;
			foreach my $name (keys $total->{cellularPrevalence}->{$chr}->{$phase}) {
				$total_copies = $total_copies + $total->{cellularPrevalence}->{$chr}->{$phase}->{$name} * $total->{copyNumber}->{$chr}->{$phase}->{$name};
				}
			$total->{total_copies}->{$chr}->{$phase} = $total_copies;
			if ($total_copies >= $max_total_copies) {
				$max_total_copies = $total_copies;
				}
			}
		}
	
	my $new_config = $config;
	# assign new cellularPrevalence to tree structure, taking into account CNAs
	foreach my $chr (keys $config) {
		my @phases = ('a');
		if ("X" ne $chr and "Y" ne $chr) { push(@phases, 'b'); }
		foreach my $phase (@phases) {
			$self->_designatePortions($new_config->{$chr}->{root}, $total, $chr, $phase, $max_total_copies, '');
			$self->_getReads($new_config->{$chr}->{root}, $total, $chr, $phase, '', 1);
			}
		}
	
	DumpFile("$opts{output_dir}/$opts{output_yaml}.yaml", $new_config);

	# print leaf files
	foreach my $chr (keys $total->{cellularPrevalence}) {
		foreach my $phase (keys $total->{cellularPrevalence}->{$chr}) {
			my $cellularPrevalence_hash = $total->{cellularPrevalence}->{$chr}->{$phase};
			my $copyNumber_hash = $total->{copyNumber}->{$chr}->{$phase};
			my $total_copies_phase = $total->{total_copies}->{$chr}->{$phase};

			# #printing to leaf text files
			(my $bampath = $config->{$chr}->{"input_".$phase}) =~ s/\.[^.]+$//;

			my $leaf_out = "$opts{output_dir}/leaf_files_phase_" . $phase . "_$chr.txt";

			(open my $leaf_fh, ">", $leaf_out) || die "unable to open file: $leaf_out";
			print($leaf_fh $total_copies_phase / $max_total_copies, "\n");
			close($leaf_fh);
			}	# foreach phase
		}	# foreach chr
	
	DumpFile("$opts{output_dir}/$opts{output_yaml}.total.txt", $total);

	# create matrix
	my $skip = 0;
	open(my $fh, '>', "$opts{output_dir}/$opts{output_yaml}.matrix.csv");
	}

sub pick_somatic_mutations {
	my $self = shift;
	my $picktrinucleotides = shift;

	$self->log->info("pick_somatic_mutations\n");
	$self->log->info("\tsomatic_profile: " . "$self->somatic_profile" . "\n");

	my $phase_a_stages = [];
	my $phase_b_stages = [];

	# For every chromosome, for every mutation type in the profile, for every subclone create a file of randomly chosen mutations for that subclone and all of it's children to contain
	foreach my $chr (@{$self->chromosomes}) {
		my $top = $self->somatic_profile->{$chr};

		my $phase0 = basename($top->{input_a});
		$phase0  =~ s/.bam$//;
		my $phase1 = basename($top->{input_b});
		$phase1  =~ s/.bam$//;

		$self->_pick_traversal(
			root => $top->{root}->{children},
			stem => [$phase0],
			phase => "a",
			stages => $phase_a_stages,
			chr => $chr,
			parent_muts => {
				snv => 0,
				indel => 0,
				sv => 0
				},
			cat_commands => {
				snv => "",
				indel => "",
				sv => ""
				},
			picktrinucleotides => $picktrinucleotides
			);

		if ($chr ne 'X' and $chr ne 'Y') {
			$self->_pick_traversal(
				root => $top->{root}->{children},
				stem => [$phase1],
				phase => "b",
				stages => $phase_b_stages,
				chr => $chr,
				parent_muts => {
					snv => 0,
					indel => 0,
					sv => 0
					},
				cat_commands => {
					snv => "",
					indel => "",
					sv => ""
					},
				picktrinucleotides => $picktrinucleotides
				);
			}
		}
	return [@{$phase_a_stages}, @{$phase_b_stages}];
	}

sub split_subclones {
	my $self = shift;

	my $phase_a_stages = [];
	my $phase_b_stages = [];

	foreach my $chr (@{$self->chromosomes}) {
		my $top = $self->somatic_profile->{$chr};

		if (! -e $self->output_dir . "/chr$chr") {
			make_path($self->output_dir . "/chr$chr") or die "Making " . $self->output_dir . "/chr$chr failed: $!";
			}
		
		my $cp_phase_0;
		if (! -e $self->output_dir . "/chr$chr/phase.0.T.bam") {
			$cp_phase_0 = $self->HPCI_group->stage(
				name => 'bs_cp_p0_' . $chr,
				command => "cp " . $self->wd . "/chrbam/chr$chr/phase.0/phase.0.T.bam " . $self->output_dir . "/chr$chr/phase.0.T.bam;",
				resources_required => {
					h_vmem => '4G'
					},
				extra_sge_args_string => " -q transient "
				);
			push(@{$phase_a_stages}, $cp_phase_0);
			}

		my $cp_phase_1 = undef;
		if ($chr ne 'X' and $chr ne 'Y') {
			if (! -e $self->output_dir . "/chr$chr/phase.1.T.bam") {
				$cp_phase_1 = $self->HPCI_group->stage(
					name => 'bs_cp_p1_' . $chr,
					command => "cp " . $self->wd . "/chrbam/chr$chr/phase.1/phase.1.T.bam " . $self->output_dir . "/chr$chr/phase.1.T.bam;",
					resources_required => {
						h_vmem => '4G'
						},
					extra_sge_args_string => " -q transient "
					);
				push(@{$phase_b_stages}, $cp_phase_1);
				}
			}

		my $phase0 = basename($top->{input_a});
		$phase0  =~ s/.bam$//;
		my $phase1 = basename($top->{input_b});
		$phase1  =~ s/.bam$//;

		my $split_phase_0 = $self->_split_multiple(
			root => $top->{root},
			stem => $phase0,
			phase => "a",
			deps => [ $cp_phase_0 ],
			chr => $chr
			);
		push(@{$phase_a_stages}, $split_phase_0);

		if ($chr ne 'X' and $chr ne 'Y') {
			my $split_phase_1 = $self->_split_multiple(
				root => $top->{root},
				stem => $phase1,
				phase => "b",
				deps => [ $cp_phase_1 ],
				chr => $chr
				);
			push(@{$phase_b_stages}, $split_phase_1);
			}
		}
	return [@{$phase_a_stages}, @{$phase_b_stages}];
	}

sub somatic_simulation {
	my $self = shift;

	$self->log->info("somatic_simulation\n");
	$self->log->info("\tsomatic_profile: " . "$self->somatic_profile" . "\n");
	$self->log->info("\tbam: " . $self->bam . "\n");
	$self->log->info("\treference: " . $self->config->{reference} . "\n");
	$self->log->info("\tsex: " . $self->sex . "\n");

	my $stages = [];
	
	# For every chromosome call copybam2dir from module
	# After all copies are completed, call bam_simulator in module
	foreach my $chr (@{$self->chromosomes}) {
		while (my ($leaf, $attr) = each(%{$self->leaves->{$chr}})) {
			$leaf =~ s/^([^_]*)_//;
			my $current_phase = $1;
			my $pre_req;
			while (my ($mutation_type, $cat_command) = each(%{$attr->{cats}})) {
				my $h_vmem;

				my $sort_before_mut_stage = $self->_sortFile(
					jobname => "mut_$chr\_sort_before_" . $mutation_type . "_" . $leaf,
					filename => $self->output_dir . "/chr$chr/$leaf",
					pre_req => $pre_req,
					sortByRead => 0
					);
				$pre_req = $sort_before_mut_stage;

				$cat_command .= "> " . $self->output_dir . "/pick_$chr\_$current_phase\_$leaf\_final\_$mutation_type.txt;";
				
				my $command_line_args = " -v pick_$chr\_$current_phase\_$leaf\_final\_$mutation_type.txt -f " . $self->output_dir . "/chr$chr/$leaf.bam -r " . $self->config->{reference} . " -o " . $self->output_dir . "/chr$chr/$leaf.bam_temp -n $attr->{muts}->{$mutation_type} -p 4 --tmpdir chr$chr\_$leaf\_$mutation_type";
				
				if ($mutation_type eq "snv") {
					$command_line_args .= " --mindepth 10 --ignoresnps";
					$h_vmem = "12G";
					}
				if ($mutation_type eq "indel") {
					$command_line_args .= ' --mindepth 10 --picardjar $PICARDROOT/picard.jar --aligner mem';
					$h_vmem = "20G";
					}
				if ($mutation_type eq "sv") {
					my $nix = $self->config->{reference};
					$nix =~ s/fa$/nix/;
					$command_line_args .= " --aligner novoalign --alignopts novoref:" . $nix;
					$h_vmem = "45G";
					}

				# if mutations are spiked in correctly, a temp file will be created
				# otherwise -> NO MUTATIONS
				my $postmut_command =
					" if [ -s " . $self->output_dir . "/chr$chr/$leaf.bam_temp ]; then mv " .
					$self->output_dir . "/chr$chr/$leaf.bam_temp " . $self->output_dir . "/chr$chr/$leaf.bam; fi";
				my $mut_stage = $self->HPCI_group->stage(
					name => "mut_$chr\_" . $mutation_type . "_" . $leaf,
					command => "$cat_command cd ". $self->output_dir ."; add" . $mutation_type . ".py " . $command_line_args . "; $postmut_command",
					resources_required => {
						h_vmem => $h_vmem
						},
					retry_resources_required => {
						h_vmem => ['6G', '12G', '24G', '32G', '45G', '60G']
						},
					modules_to_load => ['Python-BL', 'bamsurgeon/0.1.0-local', 'picard/1.130', 'bwa/0.7.12', 'novocraft/3.02.12', 'samtools/1.2', 'velvet/1.0.13', 'exonerate/2.2.0'],
					extra_sge_args_string => " -q transient "
					);

				$self->HPCI_group->add_deps(
					pre_req => $pre_req,
					deps => $mut_stage
					) if $pre_req;
				$pre_req = $mut_stage;

				push(@{$stages}, $sort_before_mut_stage);
				push(@{$stages}, $mut_stage);
				}
			}
		}
	return $stages;
	}

sub extract_leafs {
	my $self = shift;
	
	$self->log->info("extract_leafs\n");
	my $stages = [];

	foreach my $chr (@{$self->chromosomes}) {
		while (my ($leaf, $attr) = each(%{$self->leaves->{$chr}})) {
			$leaf =~ s/^([^_]*)_//;
			my $current_phase = $1;
			# generated in adjust_yaml_for_cna
			my $leaf_file = $self->output_dir . "/leaf_files_phase_$current_phase\_$chr.txt";
			next unless -e $leaf_file;

			open(my $fh, '<', $leaf_file);
			my $prop = <$fh>;
			chomp($prop);
			my $other_prop = 1 - $prop;
			$self->log->info("prop: $prop\n");
			$self->log->info("other prop: $other_prop\n");
			my $wd = $self->output_dir . "/chr$chr";

			my $sortcheck = "samtools index $wd/$leaf.bam 2> $wd/$leaf.bam.log; if [ -s $wd/$leaf.bam.log ];";
			my $extract_command =
				"$sortcheck then samtools sort $wd/$leaf.bam $wd/$leaf.sorted; mv $wd/$leaf.sorted.bam $wd/$leaf.bam; fi; " .
				"bamsplit_multiple.py " .
				"$wd/$leaf.bam $wd $leaf.bam_extracted,$leaf.bam_delete_me $prop,$other_prop; rm -f $wd/$leaf.bam_delete_me";

			my $get_reads_command =
				"samtools view $wd/$leaf.bam | grep -oP \"^[^\\t]*|RG:[^\\t]*\" | awk '{f=\$0; getline; print \$0, f}' | sort -u > $wd/$leaf.bam.reads; " .
				"samtools view $wd/$leaf.bam_extracted | grep -oP \"^[^\\t]*|RG:[^\\t]*\" | awk '{f=\$0; getline; print \$0, f}' | sort -u > $wd/$leaf.bam_extracted.reads";

			my $extract_stage = $self->HPCI_group->stage(
				name => "extract_leaf_$chr\_" . $leaf,
				command => $extract_command,
				resources_required => {
					h_vmem => "16G"
					},
				retry_resources_required => {
					h_vmem => ['6G', '12G', '24G', '32G', '45G', '60G']
					},
				modules_to_load => [ 'samtools/1.2', 'Python-BL', 'bamsurgeon/0.1.0-local' ],
				extra_sge_args_string => " -q transient "
				);

			my $get_reads_stage = $self->HPCI_group->stage(
				name => "get_reads_$chr\_" . $leaf,
				command => $get_reads_command,
				resources_required => {
					h_vmem => "4G"
					},
				retry_resources_required => {
					h_vmem => ['6G', '12G', '24G', '32G', '45G', '60G']
					},
				modules_to_load => [ 'samtools/1.2' ],
				extra_sge_args_string => " -q transient "
				);

			$self->HPCI_group->add_deps(
				pre_reqs => $extract_stage,
				deps => $get_reads_stage
				);

			push(@{$stages}, $extract_stage);
			}
		}
	return $stages;
	}

sub _pick_traversal {
	my $self = shift;
	my %args = (
		root => undef,
		stem => '',
		phase => '',
		stages => [],
		chr => '',
		parent_muts => {
			snv => 0,
			indel => 0,
			sv => 0
			},
		cat_commands => {
			snv => "",
			indel => "",
			sv => ""
			},
		picktrinucleotides => 0,
		@_
		);

	my $root = $args{root};
	my $current_clone = 0;

	if (scalar(@{$root}) == 2) {
		#Use bamsplit the two subclones for both phases and traverse the two clones
		my $split_deps = [];
		my $sub0_stem = [];
		my $sub1_stem = [];
		foreach my $stem (@{$args{stem}}) {
			push(@{$sub0_stem}, $stem . "_c" . $current_clone);
			push(@{$sub1_stem}, $stem . "_c" . ($current_clone+1));
			}

		# Handle mutations for subclone 0
		$self->_mutation_generation(
			child => $root->[0],
			stem => $sub0_stem,
			phase => $args{phase},
			stages => $args{stages},
			chr => $args{chr},
			parent_muts => $args{parent_muts},
			cat_commands => $args{cat_commands},
			picktrinucleotides => $args{picktrinucleotides}
			);

		# Handle mutations for subclone 1
		$self->_mutation_generation(
			child => $root->[1],
			stem => $sub1_stem,
			phase => $args{phase},
			stages => $args{stages},
			chr => $args{chr},
			parent_muts => $args{parent_muts},
			cat_commands => $args{cat_commands},
			picktrinucleotides => $args{picktrinucleotides}
			);
		}
	else {
		# BAMs are split sequentially for children > 2
		my $percent_sum = 0;
		my $pre_req = $args{deps};

		foreach my $child (@{$root}) {
			my $sub_stem = [];
			foreach my $stem (@{$args{stem}}) {
				push(@{$sub_stem}, $stem . "_c" . $current_clone);
				}

			$self->_mutation_generation(
				child => $child,
				stem => $sub_stem,
				phase => $args{phase},
				stages => $args{stages},
				chr => $args{chr},
				parent_muts => $args{parent_muts},
				cat_commands => $args{cat_commands},
				picktrinucleotides => $args{picktrinucleotides}
				);
			$current_clone++;
			}
		}
	}

sub _mutation_generation {
	my $self = shift;
	my %args = (
		child => undef,
		stem => [],
		phase => '',
		stages => [],
		chr => '',
		parent_muts => {
			snv => 0,
			indel => 0,
			sv => 0
			},
		cat_commands => {
			snv => "",
			indel => "",
			sv => ""
			},
		picktrinucleotides => 0,
		@_
		);
	my $child = $args{child};
	my $current_phase = $args{phase};
	my %muts = %{$args{parent_muts}};
	my %cats = %{$args{cat_commands}};

	if ((defined($child->{mut_arg})) && (@{$args{stem}} > 0)) {
		my $mutations = each_array(@{$child->{mut_arg}}, @{$child->{mut_type}}, @{$child->{mut_indx}});
		while (my ($arg, $type, $indx) = $mutations->()) {
			if (($type =~ m/(.*)_$current_phase$/) && ($1 ne "wce")) {
				my $full_command;
				if ('snv' eq $1 and 1 eq $args{picktrinucleotides}) {
					$full_command = "perl " . "$Bin/generate_signature.pl " .
						"--c " . $self->config_path . " " .
						"--chromosome $args{chr} " .
						"--mf " . $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt " .
						"--n $arg " .
						"--cb_bed " . $self->wd . "/cb_bed/$args{chr}\_collapsed.bed " .
						"--reference " . $self->wd . "/chrFa/$args{chr}.fa " .
						"--seed " . ($self->seed // 12345);
					}
				else {
					my $pick_command = 'randomsites.py ' .
						"-g " . $self->wd . "/chrFa/$args{chr}.fa " .
						"-n $arg " .
						"--avoidN " .
						"--minvaf " . ($self->minvaf // 1) . " " .
						"--maxvaf " . ($self->maxvaf // 1) . " " .
						"--vafbeta1 " . ($self->vafbeta1 // 2) . " " .
						"--vafbeta2 " . ($self->vafbeta2 // 2) . " " .
						"'$1' ";
	
					$pick_command .= " --minlen " . $self->mut_minlens->{$1} if defined $self->mut_minlens->{$1};
					$pick_command .= " --maxlen " . $self->mut_maxlens->{$1} if defined $self->mut_maxlens->{$1};
	
					$pick_command .= " > " . $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt";
	
					# RND sites require insertion library
					my $filter_command = ' grep -v RND ' . $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt";
	
					# for indel and sv only
					if (defined $self->mut_types->{$1}) {
						my $types = join('|', (split(',', $self->mut_types->{$1})));
						$filter_command .= " | egrep \'$types\'";
						}
					
					$filter_command .= " | head -n $arg > " . $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt_temp; mv " . $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt_temp " . $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt";
	
					$full_command = join(';', $pick_command, $filter_command);
					}
                    
				if (! -e $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt" or -s $self->output_dir . "/pick_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1.txt" <= 1) {
					my $pick_mut_stage = $self->HPCI_group->stage(
						name => "bs_pick_somatic_$args{chr}\_$current_phase\_$args{stem}->[$indx]\_$1",
						command => $full_command,
						resources_required => {
							h_vmem => '2G'
							},
						modules_to_load => ['Python-BL', 'bamsurgeon/0.1.0-local'],
						extra_sge_args_string => " -q transient "
						);
					push(@{$args{stages}}, $pick_mut_stage);
					}
				$muts{$1} += $arg;
				$cats{$1} .= "$args{stem}->[$indx] ";
				}
			}

		# currently applies all gain AFTER mutations applied to node
		map {
			if ($child->{mut_type}->[$_] eq "wce_" . $current_phase) {
				push(@{$args{stem}}, $args{stem}->[$child->{mut_indx}->[$_]]);
				# Label both the old index of interest and the new element to have _n0 and _n1 to signify that they are chromosome gains
				$args{stem}->[$child->{mut_indx}->[$_]] .= "_n0";
				$args{stem}->[-1] .= "_n1";
				}
			} grep {
				$child->{mut_arg}->[$_] eq 'gain';
				} 0 .. $#{$child->{mut_arg}};


		map {
			if ($child->{mut_type}->[$_] eq "wce_" . $current_phase) {
				splice @{$args{stem}}, $child->{mut_indx}->[$_], 1;
				}
			} grep {
				$child->{mut_arg}->[$_] eq 'del';
				} 0 .. $#{$child->{mut_arg}};

		}

	# If the current subclone has children, continue descending
	if (ref($child->{children}) eq 'ARRAY') {
		$self->_pick_traversal(
			root => $child->{children},
			stem => $args{stem},
			phase => $args{phase},
			stages => $args{stages},
			chr => $args{chr},
			parent_muts => \%muts,
			cat_commands => \%cats,
			picktrinucleotides => $args{picktrinucleotides}
			);
		}
	else {
		foreach my $leaf (@{$args{stem}}) {
			my %temp_cats = %cats;
			while (my ($mutation_type, $cat_command) = each %temp_cats) {
				if (defined $muts{$mutation_type} and $muts{$mutation_type} == 0) {
					delete($muts{$mutation_type});
					delete($temp_cats{$mutation_type});
					}
				else {
					my @stems_of_interest = split(" ", $temp_cats{$mutation_type});
					$temp_cats{$mutation_type} = "cat ";
					foreach my $stem_of_interest (@stems_of_interest) {
						if (($current_phase . $leaf) =~ m/$stem_of_interest/) {
							$temp_cats{$mutation_type} .= $self->output_dir . "/pick_$args{chr}\_$current_phase\_$stem_of_interest\_$mutation_type.txt ";
							}
						}
					}
				}
			$self->leaves->{$args{chr}}->{"$current_phase\_$leaf"}->{muts} = \%muts;
			$self->leaves->{$args{chr}}->{"$current_phase\_$leaf"}->{cats} = \%temp_cats;
			}
		}
	}

sub _split_multiple {
	my $self = shift;
	
	my %args = (
		root => undef,
		stem => '',
		deps => [],
		phase => '',
		chr => '',
		@_
		);

	my $root = $args{root};
	my $reads = $self->_getReads($root, {}, $args{chr}, $args{phase}, '', 1);
	my (@phase_bams, @outbams, @percentages);

	while (my ($leaf, $attr) = each(%{$self->leaves->{$args{chr}}})) {
		$leaf =~ s/^([^_]*)_//;
		if ($1 eq $args{phase}) {
			push @phase_bams, $leaf;
			}
		}

	while (my ($node, $attr) = each(%{$reads->{$args{chr}}->{$args{phase}}})) {
		$node =~ s/^_//g;
		my @c = split('_', $node);
		my $regex = join('[_n\d]*', @c, '');
		$regex = basename($args{stem}) . "_$regex" . '$';

		my @bams_for_split;
		foreach my $leaf (@phase_bams) {
			if ($leaf =~ /$regex/) {
				push @bams_for_split, $leaf;
				}
			}

		foreach my $leaf (@bams_for_split) {
			push @outbams, "$leaf.bam";
			push @percentages, $attr / scalar(@bams_for_split);
			}
		}

	my $sort_before_split_stage = $self->_sortFile(
		jobname => "bs_$args{chr}\_sort_before_split_" . basename($args{stem}),
		filename => $self->output_dir . "/chr$args{chr}/" . $args{stem},
		pre_req => $args{deps},
		sortByRead => 0
		);

	# split into multiple BAMs, then delete original copied BAM
	my $remove_cp = "rm -f " . $self->output_dir . "/chr$args{chr}/" . $args{stem} . ".bam ";
	my $split_stage = $self->HPCI_group->stage(
		name => "bs_$args{chr}\_split_" . basename($args{stem}),
		command => "bamsplit_multiple.py " . $self->output_dir . "/chr$args{chr}/" . $args{stem} . ".bam " . $self->output_dir . "/chr$args{chr}/ " . join(',', @outbams) . " " . join(',', @percentages) . " ; $remove_cp ",
		resources_required => {
			h_vmem => "16G"
			},
		retry_resources_required => {
			h_vmem => ['8G', '12G', '24G', '32G', '45G', '60G']
			},
		modules_to_load => ['Python-BL', 'bamsurgeon/0.1.0-local'],
		extra_sge_args_string => " -q transient "
		);

	$self->HPCI_group->add_deps(
		pre_req => $sort_before_split_stage,
		deps => $split_stage
		);

	return($split_stage)
	}

sub _sortFile {
	my $self = shift;
	my %args = (
		jobname => undef,
		filename => undef,
		pre_req => undef,
		sortByRead => 0,
		@_
		);
	
	# default sort by coordinate
	my $sortcheck = "samtools index $args{filename}.bam 2> $args{filename}.bam.log; if [ -s $args{filename}.bam.log ];";
	my $samtools = "samtools sort";
	# if sorting by read ID
	if (1 eq $args{sortByRead}) {
		$samtools .= " -n";
		}
	
	my $sort_stage = $self->HPCI_group->stage(
		name => $args{jobname},
		command => "cd " . $self->output_dir . "; $sortcheck then $samtools $args{filename}.bam $args{filename}.sorted; mv $args{filename}.sorted.bam $args{filename}.bam; samtools index $args{filename}.bam; fi",
		resources_required => {
			h_vmem => "4G"
			},
		retry_resources_required => {
			h_vmem => ['6G', '12G', '24G', '32G', '45G', '60G']
			},
		modules_to_load => ['samtools/1.2'],
		extra_sge_args_string => " -q transient ",
		);
	
	$self->HPCI_group->add_deps(
		pre_req => $args{pre_req},
		deps => $sort_stage
		) if $args{pre_req};

	return($sort_stage)
	}

sub _determineProfiles {
	my $self = shift;
	# TYPES: hash, string, hashref, string, hashref
	# $phase = 'a' or 'b'
	# $child = '_c0', '_c1', etc.
	my ($config_hash, $phase, $cellularPrevalence_ref, $child, $copyNumber_ref) = @_;

	# multiply all cellularPrevalence_ref as indicated on yaml file
	my $percent = $config_hash->{percent} * 1;	# convert percent string to decimal
	my $new_cellularPrevalence = {};
	my $levels;		# counts number of tree levels for this node

	while (my ($name, $prop) = each %$cellularPrevalence_ref ) {
		# e.g. parent = _c0; child = _c0_c1
		my $parent = $name;
		$name = $name . $child;		# new child name
		$prop = $prop * $percent;	# associated proportion
		$new_cellularPrevalence->{$name} = $prop;

		$levels = ($name =~ tr/c//);
	
		if (defined $copyNumber_ref->{$parent}) {
			$copyNumber_ref->{$name} = $copyNumber_ref->{$parent};
			}
		else {	# base case when passing in root node
			$copyNumber_ref->{$name} = 1;
			}
		}
	$cellularPrevalence_ref = $new_cellularPrevalence;

	# check for any chromosome phase gains or deletions
	if (defined $config_hash->{mut_arg} and defined $config_hash->{mut_type}) {
		for my $idx (0 .. scalar(@{$config_hash->{mut_arg}})-1) {
			# check if applicable to current phase
			if (@{$config_hash->{mut_type}}[$idx] eq "wce_".$phase) {
				# check for del or gain
				if (@{$config_hash->{mut_arg}}[$idx] eq "del") {
					#print "Deleting phase " .$phase. "\n";

					foreach my $key (keys $cellularPrevalence_ref) {
						$copyNumber_ref->{$key}--;
						if (0 eq $copyNumber_ref->{$key}) {
							delete $cellularPrevalence_ref->{$key};
							}
						}

					my $sum = 0;
					foreach my $key (keys $copyNumber_ref) {
						$sum = $sum + $copyNumber_ref->{$key};
						}

					# if this chromosome phase has no more total_copies
					if (0 == $sum) { return; }
					}
				else {
					#print "Gaining phase " .$phase. "\n";
					foreach my $key (keys $cellularPrevalence_ref) {
						$copyNumber_ref->{$key}++;
						}
					}
				}
			}
		}

	# if at leaf node
	if (! defined $config_hash->{children} ) {
		return ($cellularPrevalence_ref, $copyNumber_ref);
		}
	else {
		my $new_cellularPrevalence = {};
		my $new_copyNumber_ref;
		my $child_num = 0;
	
		foreach my $config (@{$config_hash->{children}}) {
			# create copy for each child
			my %child_cellularPrevalence = %$cellularPrevalence_ref;
			my $add_cellularPrevalence;
			($add_cellularPrevalence, $new_copyNumber_ref) = $self->_determineProfiles($config, $phase, \%child_cellularPrevalence, "_c".$child_num, $copyNumber_ref);

	
			# child phases not completely deleted
			if (defined $add_cellularPrevalence) {
				# merge hash
				$new_cellularPrevalence = {%$add_cellularPrevalence, %$new_cellularPrevalence};
				$copyNumber_ref = $new_copyNumber_ref;
				}
			$child_num = $child_num + 1;
			}
		return ($new_cellularPrevalence, $new_copyNumber_ref);
		}
	} # _determineProfiles


sub _designatePortions {
	my $self = shift;
	# HR = hash ref
	my ($config_HR, $total_HR, $chr, $phase, $max_total_copies, $child) = @_;

	# if at leaf node
	if (! defined $config_HR->{children} ) {
		#print "AT LEAF NODE -- child $child\n";
		# if at root node (i.e. entire chromosome is deleted) -> should just remove entirely...
		if ('' eq $child) { return; }
		# for complete phase deletions
		if (0 eq $total_HR->{total_copies}->{$chr}->{$phase}) { return 0; }
		if (! defined $total_HR->{copyNumber}->{$chr}->{$phase}->{$child}) { return 0; }
		if (! defined $total_HR->{cellularPrevalence}->{$chr}->{$phase}->{$child}) { return 0; }

		my $quantity = $total_HR->{cellularPrevalence}->{$chr}->{$phase}->{$child} * $total_HR->{copyNumber}->{$chr}->{$phase}->{$child} / $total_HR->{total_copies}->{$chr}->{$phase};

		return ($quantity);
		}
	
	else {
		my $num = 0;
		my $quantity_sum = 0;
		my $quantities = {};
		my $configs = {};
		my @children = ();	# used to keep track of children in the order they appear on config file

		foreach my $config (@{$config_HR->{children}}) {
			push @children, "$child\_c$num";
			$configs->{"$child\_c$num"} = $config;
			$quantities->{"$child\_c$num"} = $self->_designatePortions($config, $total_HR, $chr, $phase, $max_total_copies, "$child\_c$num");

			$quantity_sum = $quantity_sum + $quantities->{"$child\_c$num"};
			$num = $num + 1;
			}

		#$self->subclone_proportions->{$chr}->{$phase} = { %{$self->subclone_proportions->{$chr}->{$phase}}, %{$quantities} };

		# reconstruct child config
		$config_HR->{children} = ();
		foreach my $child (@children) {
			if (0 eq $quantity_sum) {
				$configs->{$child}->{"percent_$phase"} = 0;
				}
			else {
				$configs->{$child}->{"percent_$phase"} = $quantities->{$child} / $quantity_sum;
				}
			push @{$config_HR->{children}}, $configs->{$child};
			}

		return ($quantity_sum);
		}
	} # _designatePortions


sub _getReads {
	my $self = shift;
	my ($config_HR, $total_HR, $chr, $phase, $child, $parent_percent) = @_;

	# if at leaf node
	if (! defined $config_HR->{children}) {
		if ($child eq '') {
			$total_HR->{reads}->{$chr}->{$phase}->{$child} = $config_HR->{percent};
			}
		else {
			$total_HR->{reads}->{$chr}->{$phase}->{$child} = $parent_percent * $config_HR->{"percent_$phase"};
			}
		}
	else {
		my $num = 0;
		foreach my $config (@{$config_HR->{children}}) {
			if ($child eq '') {
				$self->_getReads($config, $total_HR, $chr, $phase, "$child\_c$num", $config_HR->{"percent"});
				}
			else {
				$self->_getReads($config, $total_HR, $chr, $phase, "$child\_c$num", $parent_percent*$config_HR->{"percent_$phase"});
				}
			$num = $num + 1;
			}
		}
	
	return($total_HR->{reads});
	} # _getReads

1;
