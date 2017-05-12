package NGS::Tools::BAMSurgeon::Merge;

use warnings;
use strict;
use Carp;
use Moose::Role;
use FindBin qw($Bin);
use Params::Validate qw(:all);
use Data::Dumper;
use File::Path qw(make_path);
use YAML qw(LoadFile);
use HPCI;
use Cwd qw(abs_path);

sub merge_to_phases {
	my $self = shift;

	$self->log->info("merge_phases\n");
	$self->log->info("\tbam: " . $self->bam . "\n");
	$self->log->info("\tsex: " . $self->sex . "\n");

	my $stages = [];

	foreach my $chr (@{$self->chromosomes}) {

		my $phase_a_command = 'java -Xmx14g -jar $PICARDROOT/picard.jar MergeSamFiles USE_THREADING=true VALIDATION_STRINGENCY=LENIENT ';
		my $phase_b_command = 'java -Xmx14g -jar $PICARDROOT/picard.jar MergeSamFiles USE_THREADING=true VALIDATION_STRINGENCY=LENIENT ';

		foreach my $leaf (keys %{$self->leaves->{$chr}}) {
			$leaf =~ s/^([^_]*)_//;
			my $current_phase = $1;
			if ($current_phase eq 'a') {
				$phase_a_command .= "INPUT=" . $self->output_dir . "/chr$chr/$leaf.bam_extracted ";
				}
			elsif ($current_phase eq 'b') {
				$phase_b_command .= "INPUT=" . $self->output_dir . "/chr$chr/$leaf.bam_extracted ";
				}
			}
		make_path($self->output_dir . "/chr$chr/output/");
		$phase_a_command .= "OUTPUT=" . $self->output_dir . "/chr$chr/output/phase.0.T.bam; samtools index " . $self->output_dir . "/chr$chr/output/phase.0.T.bam; ";
		$phase_b_command .= "OUTPUT=" . $self->output_dir . "/chr$chr/output/phase.1.T.bam; samtools index " . $self->output_dir . "/chr$chr/output/phase.1.T.bam; ";

		my $merge_phase_0_stage = $self->HPCI_group->stage(
			name => "bs_merge_phase_0_$chr",
			command => $phase_a_command,
			resources_required => {
				h_vmem => '18G'
				},
			modules_to_load => [ 'picard/1.130', 'samtools/1.2' ],
			extra_sge_args_string => " -q transient "
			);
		push(@{$stages}, $merge_phase_0_stage);
		if ('X' ne $chr and 'Y' ne $chr) {
			my $merge_phase_1_stage = $self->HPCI_group->stage(
				name => "bs_merge_phase_1_$chr",
				command => $phase_b_command,
				resources_required => {
					h_vmem => '18G'
					},
				modules_to_load => [ 'picard/1.130', 'samtools/1.2' ],
				extra_sge_args_string => " -q transient "
				);
			push(@{$stages}, $merge_phase_1_stage);
			}
		}
	return $stages;
	}

sub merge_to_chromosomes {
	my $self = shift;

	$self->log->info("merge_chromosomes\n");
	$self->log->info("\tbam: " . $self->bam . "\n");
	$self->log->info("\tsex: " . $self->sex . "\n");

	my $stages = [];

	foreach my $chr (@{$self->chromosomes}) {
		my $inputs = "INPUT=" . $self->output_dir . "/chr$chr/output/phase.0.T.bam ";
		if ('X' ne $chr and 'Y' ne $chr) {
			$inputs .= "INPUT=" . $self->output_dir . "/chr$chr/output/phase.1.T.bam ";
			}

		my $merge_command = 'java -Xmx10g -jar $PICARDROOT/picard.jar MergeSamFiles USE_THREADING=true VALIDATION_STRINGENCY=LENIENT '.
		$inputs .
		"OUTPUT=" . $self->output_dir . "/chr$chr/output/T.bam; samtools index " . $self->output_dir . "/chr$chr/output/T.bam; ";
		$merge_command .= "rm -f " . $self->output_dir . "/chr$chr/output/phase.*.T.bam*; ";

		my $merge_stage = $self->HPCI_group->stage(
			name => "bs_merge_chr_$chr",
			command => $merge_command,
			resources_required => {
				h_vmem => '16G'
				},
			modules_to_load => [ 'picard/1.130', 'samtools/1.2' ],
			extra_sge_args_string => " -q transient "
			);
		push(@{$stages}, $merge_stage);
		}
	return($stages);
	}

sub merge_to_final {
	my $self = shift;

	$self->log->info("merge_chromosomes\n");
	$self->log->info("\tbam: " . $self->bam . "\n");
	$self->log->info("\tsex: " . $self->sex . "\n");

	my $stages = [];

	my $command = 'java -Xmx16g -jar $PICARDROOT/picard.jar MergeSamFiles USE_THREADING=true VALIDATION_STRINGENCY=LENIENT ';

	my @chromosomes = (1..22);
	push @chromosomes, 'X';
	if ($self->sex eq 'M') {
		push @chromosomes, 'Y';
		}
	foreach my $chr (@chromosomes) {
		$command .= "INPUT=" . $self->output_dir . "/chr$chr/output/T.bam ";
		}
	$command .= "OUTPUT=" . $self->output_dir . "/T.bam; samtools index " . $self->output_dir . "/T.bam; ";
	my $merge_stage = $self->HPCI_group->stage(
		name => "bs_merge_final",
		command => $command,
		resources_required => {
			h_vmem => '20G'
			},
		modules_to_load => [ 'picard/1.130', 'samtools/1.2' ],
		extra_sge_args_string => " -q transient "
		);
	push(@{$stages}, $merge_stage);
	return $stages;
	}

sub merge_vcf {
	my $self = shift;

	$self->log->info("merge_vcf\n");
	$self->log->info("\treference: " . $self->config->{reference} . "\n");

	my $stages = [];

	foreach my $chr (@{$self->chromosomes}) {
		my $codes = {
			snv => {
				py => 'makevcf.py',
				r => '',
				l => '',
				regex => ".bam_temp.haplo_$chr\_*_*.log"
				},
			indel => {
				py => 'makevcf_indels.py',
				r => '',
				l => '',
				regex => ".bam_temp.$chr\_*_*.log"
				},
			sv => {
				py => 'makevcf_sv.py',
				r => '-r',
				l => '-l',
				regex => ".bam_temp_$chr\_*_*_*.log"
				}
			};

		my $leaf_nodes = [];
		my $pre_reqs = [];
		while (my ($leaf, $attr) = each(%{$self->leaves->{$chr}})) {
			$leaf =~ s/^([^_]*)_//;
			my $current_phase = $1;

			my $node = $leaf;
			$node =~ s/^([^_]*)_//;
			$node =~ s/_n\d//g;
			push(@{$leaf_nodes}, $node) unless grep {$_ eq $node} @{$leaf_nodes};

			foreach my $mutation_type (('snv','indel','sv')) {

				my $mutation_folder = $self->output_dir . "/mutlogs$chr/$node/$mutation_type/";
				make_path($mutation_folder);
				make_path($self->output_dir . "/vcf/");

				my $check_command = "if [ -d " . $self->output_dir . "/add" . $mutation_type . "_logs_" . $leaf . ".bam_temp/ ];";
				my $find_command = "find " . $self->output_dir . "/add" . $mutation_type . "_logs_" . $leaf . ".bam_temp/ -name " . $leaf . $codes->{$mutation_type}->{regex} . " -exec cp {} $mutation_folder \\;";

				my $find_stage = $self->HPCI_group->stage(
					name => "find_logs_$chr\_" . $current_phase . "_$leaf\_$mutation_type",
					command => join(' ', $check_command, 'then', $find_command, '; fi'),
					resources_required => {
						h_vmem => '2G'
						},
					modules_to_load => [],
					extra_sge_args_string => " -q transient "
					);
				push(@{$pre_reqs}, $find_stage);
				push(@{$stages}, $find_stage);
				}
			}
	
		foreach my $node (@{$leaf_nodes}) {
			foreach my $mutation_type (('snv','indel','sv')) {
				my $makevcf_command = '';
				my $ref = 'snv' eq $mutation_type ? '' : $self->config->{reference};
				my $mutation_folder = $self->output_dir . "/mutlogs$chr/$node/$mutation_type/";
	
				if ('sv' eq $mutation_type) {
					$makevcf_command .= "cat $mutation_folder/\* > $mutation_folder/svs.txt; ";
					$mutation_folder = $mutation_folder . "/svs.txt";
					}

				$makevcf_command .= "$codes->{$mutation_type}->{py} $codes->{$mutation_type}->{l} $mutation_folder $codes->{$mutation_type}->{r} $ref > " . $self->output_dir . "/vcf/chr$chr\_$node\_$mutation_type.vcf";

				my $merge_vcf_stage = $self->HPCI_group->stage(
					name => "bs_merge_vcf_$chr\_$node\_$mutation_type",
					command => $makevcf_command,
					resources_required => {
						h_vmem => '4G',
						},
					modules_to_load => ['Python-BL', 'bamsurgeon/0.1.0-local', 'picard/1.130', 'bwa/0.7.12', 'novocraft/3.02.12', 'samtools/1.2', 'velvet/1.0.13', 'exonerate/2.2.0'],
					extra_sge_args_string => " -q transient "
					);
				$self->HPCI_group->add_deps(
					pre_reqs => $pre_reqs,
					deps => $merge_vcf_stage
					);
				push(@{$stages}, $merge_vcf_stage);
				}
			}		
		}
	return $stages;
	}

1;
