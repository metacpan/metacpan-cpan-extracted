use strict;
use warnings;
use HPCI;
use File::Path qw(make_path);

our ($wd, $chr, $diploid, $reference, $gpercent, $phasing) = @ARGV;
our $group = HPCI->group(cluster => 'SGE', name => "GermlineSim-$chr", base_dir => $wd);

germline_stages(
	chr => $chr,
	diploid => $diploid
	);

$group->execute();


sub germline_stages {
	my %args = (
		chr => "",
		diploid => 1,
		@_
		);

	# input_bam = $self->bam
	# ref = $self->config->{reference}
	# randompick_dir = $self->wd . "/germ_mutations"
	# percent = $self->gpercent

	# $self->HPCI_group->stage(
	# 	name => "",
	# 	command => "",
	# 	resources_required => {
	# 		h_vmem => "60G"
	# 		},
	# 	modules_to_load => $self->modules
	# 	);

	my @phase_list = ("phase.0");

	my %phase_dir = (
		"phase.0" => $wd . "/chr" . $args{chr} . "/phase.0",
		"phase.1" => $wd . "/chr" . $args{chr} . "/phase.1"
		);
	my %phase_dir_with_stem = (
		"phase.0" => $wd . "/chr" . $args{chr} . "/phase.0/phase.0",
		"phase.1" => $wd . "/chr" . $args{chr} . "/phase.1/phase.1"
		);

	my $phasing_command = "samtools sort -m 5G -@ 4 " . $wd . "/chr" . $args{chr} . ".bam " . $phase_dir{"phase.0"};
	if ($args{diploid}) {
		push(@phase_list, "phase.1");
		if ($phasing) {
			$phasing_command =
				"samtools sort -m 5G -@ 4 " . $wd . "/chr" . $args{chr} . ".bam " . $wd . "/chr" . $args{chr} . ";\n" .
				"samtools phase -b phase " . $wd . "/chr" . $args{chr} . ".bam";
			}
		}


	foreach my $phase (@phase_list) {
		if (! -e $phase_dir{$phase}) {
			make_path($phase_dir{$phase});
			}
		my $phasing_stage;
		if ($phasing) {
			$phasing_stage = $group->stage(
				name => "phasing_" . $args{chr} . $phase,
				command => $phasing_command,
				resources_required => {
					h_vmem => "12G"
					},
				modules_to_load => [ 'samtools/1.2' ]
				);
			}

		my $pre_stage;
		if (! -e $phase_dir_with_stem{$phase} . ".postprocessed.bam") {
			$pre_stage = $group->stage(
				name => "germ_hap_pre_" . $args{chr} . $phase,
				command =>
					"cd " . $phase_dir{$phase} . "; " .
					"postprocess.py -f " . $reference . ".fai -t 4 -m 10G " . $phase_dir{$phase} . ".bam;\n" .
					"mv " . $phase_dir{$phase} . ".postprocessed.bam " . $phase_dir_with_stem{$phase} . ".postprocessed.bam;\n" . 
					"samtools sort -m 5G -@ 4 " . $phase_dir_with_stem{$phase} . ".postprocessed.bam " . $phase_dir_with_stem{$phase} . ".postprocessed.sorted;\n" .
					"mv " . $phase_dir_with_stem{$phase} . ".postprocessed.sorted.bam " . $phase_dir_with_stem{$phase} . ".postprocessed.bam;\n" .
					"samtools index " . $phase_dir_with_stem{$phase} . ".postprocessed.bam;\n",
				resources_required => {
					h_vmem => "32G"
					},
				modules_to_load => [ 'samtools/1.2', 'Python-BL', 'bamsurgeon/0.1.0-local' ]
				);
	
			if (defined($phasing_stage)) {
				$group->add_deps(
					pre_req => $phasing_stage,
					deps => $pre_stage
					) if $phasing_stage;
				}
			}

		my $snv_stage = $group->stage(
			name => "snvhet_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"addsnv.py -r " . $reference . " -v " . $wd . "/germ_mutations/pick_" . $args{chr} . "_snv_het.txt -f " . $phase_dir_with_stem{$phase} . ".postprocessed.bam -o snvhet_ph0 --mindepth 10 --ignoresnps --skipmerge",
			resources_required => {
				h_vmem => "8G"
				},
			modules_to_load => [ "Python-BL", 'bamsurgeon/0.1.0-local' ]
			);

		$group->add_deps(
			pre_req => $pre_stage,
			deps => $snv_stage
			) if $pre_stage;

		my $indel_stage = $group->stage(
			name => "indelhet_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"addindel.py -r " . $reference . " -v " . $wd . "/germ_mutations/pick_" . $args{chr} . "_indel_het.txt -f " . $phase_dir_with_stem{$phase} . '.postprocessed.bam -o indelhet_ph0 --mindepth 10 -p 4 --skipmerge --picardjar $PICARDROOT/picard.jar --aligner mem',
			resources_required => {
				h_vmem => "8G"
				},
			modules_to_load => [ "Python-BL", "picard/1.130", 'bamsurgeon/0.1.0-local' ]
			);

		$group->add_deps(
			pre_req => $snv_stage,
			deps => $indel_stage
			);

		my $merge_sort_muts_stage = $group->stage(
			name => "merge_sort_muts_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"samtools merge -f " . $phase_dir_with_stem{$phase} . ".muts.bam *.muts.bam;\n" .
				"samtools sort -m 500M -@ 4 " . $phase_dir_with_stem{$phase} . ".muts.bam " . $phase_dir_with_stem{$phase} . ".muts.sorted; mv " . $phase_dir_with_stem{$phase} . ".muts.sorted.bam " . $phase_dir_with_stem{$phase} . ".muts.bam",
			resources_required => {
				h_vmem => "4G"
				},
			modules_to_load => ["samtools/1.2"]
			);

		$group->add_deps(
			pre_req => $indel_stage,
			deps => $merge_sort_muts_stage
			) if $indel_stage;

		my $replace_read_stage = $group->stage(
			name => "replace_reads_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"replacereads.py -b " . $phase_dir_with_stem{$phase} . ".postprocessed.bam -r " . $phase_dir_with_stem{$phase} . ".muts.bam -o " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.bam --all --progress",
			resources_required => {
				h_vmem => "12G"
				},
			retry_resources_required => {
				h_vmem => ['16G', '20G', '24G']
				},
			modules_to_load => [ "Python-BL", 'bamsurgeon/0.1.0-local', 'samtools/1.2' ]
			);

		$group->add_deps(
			pre_req => $merge_sort_muts_stage,
			deps => $replace_read_stage
			) if $merge_sort_muts_stage;

		my $postprocess_stage = $group->stage(
			name => "post_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"postprocess.py -f " . $reference . ".fai -t 4 -m 10G " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.bam;",
			resources_required => {
				h_vmem => "32G"
				},
			modules_to_load => [ "Python-BL", 'bamsurgeon/0.1.0-local', 'samtools/1.2' ]
			);

		$group->add_deps(
			pre_req => $replace_read_stage,
			deps => $postprocess_stage
			);

		my $sort_post_stage = $group->stage(
			name => "sort_post_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"samtools sort -m 500M -@ 4 " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.bam " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.sorted; mv " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.sorted.bam " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.bam",
			resources_required => {
				h_vmem => "4G"
				},
			modules_to_load => ["samtools/1.2"]
			);

		$group->add_deps(
			pre_req => $postprocess_stage,
			deps => $sort_post_stage
			);

		my $nongpercent = 1 - $gpercent;
		my $bamsplit_stage = $group->stage(
			name => "bamsplit_ph0_" . $args{chr} . $phase,
			command =>
				"cd " . $phase_dir{$phase} . "; " .
				"bamsplit_multiple.py " . $phase_dir_with_stem{$phase} . ".postprocessed.muts.postprocessed.bam " . $phase_dir{$phase} . " $phase.N.bam,$phase.T.bam " . " $nongpercent,$gpercent ",
			resources_required => {
				h_vmem => "4G"
				},
			modules_to_load => [ "Python-BL", 'bamsurgeon/0.1.0-local' ]
			);

		$group->add_deps(
			pre_req => $sort_post_stage,
			deps => $bamsplit_stage
			);
		}

	return 0;
	}
