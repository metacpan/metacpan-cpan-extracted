package NGS::Tools::BAMSurgeon;
### module_name.pm ################################################################################

### HISTORY #######################################################################################
# Version               Date            Developer               Comments
# 0.01                  2012-06-20      Christopher Lalansingh   Initial code development.

### INCLUDES ######################################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Moose;
use Pod::Usage;
use YAML qw(LoadFile);
use FindBin qw($Bin);
use Data::Dumper;
use Params::Validate qw(:all);
use File::Path qw(make_path);
use Cwd qw(abs_path);
use Moose::Util qw( apply_all_roles );
use HPCI;
use File::ShareDir ':ALL';

=head1 NAME

    NGS::Tools::BAMSurgeon

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 DESCRIPTION

This package is a pipeline wrapper for BAMSurgeon (https://github.com/adamewing/bamsurgeon) and provides additional functionality for the simulation of copy number abberations in the tumour.

=cut

=head1 DEPENDENCIES

=cut

=over

=item *

samtools (>= 1.1)

=item *

picardtools (>= 1.130)

=item *

python (2.7.x)

=item *

bamsurgeon (1.0)

=item *

bwa (>= 0.7.12)

=item *

novocraft (>= 3.02.12)

=item *

velvet (>= 1.0.13)

=item *

exonerate (>= 2.2.0)

=item *

alleleCount (>= 2.1.1)

=item *

bedtools (>= 2.24.0)

=back

=head1 USAGE

	use NGS::Tools::BAMSurgeon;

	my $bamsurgeon = NGS::Tools::BAMSurgeon->new(
		working_dir => '/path/to/working/dir',
		config => "path/to/config.yaml",
		somatic_profile => "path/to/somatic.yaml",
		germline_profile => "path/to/germ_mut.yaml",
		bam => 'test.bam',
		tumour_name => "test",
		sex => 'M',
		gpercent => 0.7,
		seed => 12345,
		# parameters for choosing mutations to spike in
		minvaf => 1,
		maxvaf => 1,
		vafbeta1 => 2.0,
		vafbeta2 => 2.0,
		indel_minlen => 1,
		indel_maxlen => 90,
		indel_types => 'INS,DEL',
		sv_minlen => 3000,
		sv_maxlen => 30000,
		sv_types => 'DUP,INV',
		phasing => 0,
		redochrs => 'all'
		);

	$bamsurgeon->run(
		splitbam => 0,
		preparef => 0,
		pickgermmut => 0,
		germsim => 0,
		generatecallable => 0,
		picksomaticmut => 1,
		picktrinucleotides => 1,
		splitsubclones => 1,
		somaticsim => 1,
		makevcf => 1,
		extractleafs => 1,
		mergephases => 1,
		mergechromosomes => 1,
		mergefinal => 1,
		allelecount => 1
		);

=cut

# Define the subroutines to be exported directly to the importer when requested
use Exporter 'import'; 
our @EXPORT_OK = @EXPORT_OK = qw(function1);

### Roles #########################################################################################
with 'BLSupport::Logging::Role';
with 'NGS::Tools::BAMSurgeon::Germline';
with 'NGS::Tools::BAMSurgeon::Somatic';
with 'NGS::Tools::BAMSurgeon::Merge';

### Attributes ####################################################################################

has 'HPCI_group' => (
	is => 'ro',
	writer => '_set_HPCI_group'
	);

has 'existing_stages' => (
	isa => 'ArrayRef',
	is => 'rw'
	);

has 'sex' => (
	is => 'ro',
	writer => '_set_sex',
	default => 'F'
	);

has 'bam' => (
	is => 'ro',
	writer => '_set_bam',
	);

has 'phasing' => (
	is => 'ro',
	writer => '_set_phasing'
	);

has 'modules' => (
	isa => 'ArrayRef',
	is => 'ro',
	writer => '_set_modules'
	);

has 'seed' => (
	is => 'ro',
	writer => '_set_seed'
	);

has 'minvaf' => (
	is => 'ro',
	writer => '_set_minvaf'
	);

has 'maxvaf' => (
	is => 'ro',
	writer => '_set_maxvaf'
	);

has 'vafbeta1' => (
	is => 'ro',
	writer => '_set_vafbeta1'
	);

has 'vafbeta2' => (
	is => 'ro',
	writer => '_set_vafbeta2'
	);

has 'chromosomes' => (
	isa => 'ArrayRef',
	is => 'ro',
	writer => '_set_chromosomes'
	);

has 'mut_minlens' => (
	isa => 'HashRef',
	is => 'ro',
	writer => '_set_mut_minlens'
	);

has 'mut_maxlens' => (
	isa => 'HashRef',
	is => 'ro',
	writer => '_set_mut_maxlens'
	);

has 'mut_types' => (
	isa => 'HashRef',
	is => 'ro',
	writer => '_set_mut_types'
	);

has 'tumour_name' => (
	is => 'ro',
	writer => '_set_tumour_name'
	);

# Directories

has 'wd' => (
	is => 'ro',
	writer => '_set_wd',
	default => '.'
	);

has 'log_dir' => (
	is => 'ro',
	writer => '_set_log_dir'
	);

has 'output_dir' => (
	is => 'ro',
	writer => '_set_output_dir'
	);

has 'bin' => (
	is => 'ro',
	writer => '_set_bin'
	);

has 'config_path' => (
	is => 'ro',
	writer => '_set_config_path'
	);

has 'original_somatic_profile_path' => (
	is => 'ro',
	writer => '_set_original_somatic_profile_path'
	);

has 'adjusted_somatic_profile_path' => (
	is => 'ro',
	writer => '_set_adjusted_somatic_profile_path'
	);

# Configs:

has 'somatic_profile' => (
	is => 'ro',
	writer => '_set_somatic_profile'
	);

has 'germline_profile' => (
	is => 'ro',
	writer => '_set_germline_profile'
	);

has 'config' => (
	#isa => 'HashRef',
	is => 'ro',
	writer => '_set_config'
	);

# Get absolute paths for files and directories:

around [qw(
	_set_bam
	_set_wd
	_set_log_dir
	_set_output_dir
	_set_bin
	_set_config_path
	_set_original_somatic_profile_path
	_set_adjusted_somatic_profile_path
	)] => sub {
		my $orig = shift;
		my $self = shift;
		my $value = shift;
		$self->$orig(abs_path($value));
		};

# Stages:



=head1 METHODS

=head2 new

This subroutine creates a NGS::Tools::BAMSurgeon object with the following parameters (mandatory parameters are denoted with 1, optional with 0, or having a default specified, as per Params::Validate specifications):

	config => 1,
	somatic_profile => 1,
	germline_profile => 1,
	bam => 1,
	sex => 1,
	gpercent => 1,
	seed => 0,
	minvaf => 1,
	maxvaf => 1,
	vafbeta1 => { default => 2.0 },
	vafbeta2 => { default => 2.0 },
	indel_minlen => { default =>  1 },
	indel_maxlen => { default => 90 },
	indel_types => { default => 'INS,DEL' },
	sv_minlen => { default => 3000 },
	sv_maxlen => { default => 30000 },
	sv_types => { default => 'DUP,INV,DEL' },
	working_dir => { default => '.' },
	tumour_name => { default => 'sm' },
	log_dir => 0,
	modules => 0,
	phasing => 1,
	redochrs => { default => 'all' }

=cut

sub BUILD {
	my $self = shift;
	my %args = validate (
		@_,
		{
			config => 1,
			somatic_profile => 1,
			germline_profile => 1,
			bam => 1,
			sex => 1,
			gpercent => 1,
			seed => 0,
			minvaf => 1,
			maxvaf => 1,
			vafbeta1 => { default => 2.0 },
			vafbeta2 => { default => 2.0 },
			indel_minlen => { default =>  1 },
			indel_maxlen => { default => 90 },
			indel_types => { default => 'INS,DEL' },
			sv_minlen => { default => 3000 },
			sv_maxlen => { default => 30000 },
			sv_types => { default => 'DUP,INV,DEL' },
			working_dir => { default => '.' },
			tumour_name => { default => 'sm' },
			log_dir => 0,
			modules => 0,
			phasing => 1,
			redochrs => { default => 'all' }
			}
		);

	$self->_set_config_path($args{config});
	$self->_set_config(LoadFile(abs_path($args{config})));
	$self->_set_original_somatic_profile_path($args{somatic_profile});
	$self->_set_germline_profile(LoadFile(abs_path($args{germline_profile})));

	$self->_set_tumour_name($args{tumour_name});
	$self->_set_bam($args{bam});
	$self->_set_sex($args{sex});
	$self->_set_phasing($args{phasing});

	$self->_set_gpercent($args{gpercent});

	$self->_set_wd($args{working_dir});
	$self->_set_output_dir("$args{working_dir}/$args{tumour_name}");
	if (! -e $self->output_dir) {
		make_path($self->output_dir);
		}
	$self->_set_adjusted_somatic_profile_path($self->output_dir . "/adjusted_somatic_profile.yaml");
	$self->_set_bin($Bin);

	my @chromosomes;
	if ('all' eq $args{redochrs}) {
		@chromosomes = (1..22);
		push @chromosomes,'X';
		if($self->sex eq 'M'){
			push @chromosomes, 'Y';
			}
		}
	else {
		@chromosomes = split(',', $args{redochrs});
		}
	$self->_set_chromosomes(\@chromosomes);

	$self->_set_mut_minlens({
		indel => $args{indel_minlen},
		sv => $args{sv_minlen}
		});
	$self->_set_mut_maxlens({
		indel => $args{indel_maxlen},
		sv => $args{sv_maxlen}
		});
	$self->_set_mut_types({
		indel => $args{indel_types},
		sv => $args{sv_types}
		});
	
	if (defined($args{log_dir})) {
		if (! -e $args{log_dir}) {
			make_path($args{log_dir});
			}
		$self->_set_log_dir($args{log_dir});
		}
	elsif (! -e ($self->wd . "/logs")) {
		make_path($self->wd . "/logs");
		$self->_set_log_dir($self->wd . "/logs");
		}
	else {
		$self->_set_log_dir($self->wd . "/logs");
		}

	$self->validate_config();

	$self->_set_seed($args{seed});
	$self->_set_minvaf($args{minvaf});
	$self->_set_maxvaf($args{maxvaf});
	$self->_set_vafbeta1($args{vafbeta1});
	$self->_set_vafbeta2($args{vafbeta2});

	if (defined($args{modules})) {
		$self->_set_modules($args{modules});
		}
	else {
		$self->_set_modules([
			'Python-BL/2.7.10',
			'samtools/1.2',
			'bcftools/1.1',
			'bwa/0.7.12',
			'picard/1.130',
			'velvet/1.0.13',
			'exonerate/2.2.0',
			'java/1.8.0_45',
			'bamql/head',
			'novocraft/3.02.12',
			'yaml/0.1.5',
			'bedtools'
			]);
		}

	$self->init_logging(directory => $self->log_dir);
	$self->_set_HPCI_group(HPCI->group(name => 'BS-'.$args{tumour_name}, cluster => 'SGE', base_dir => $self->log_dir, max_concurrent => 50));
	}

=head2 run

This subroutine executes the pipeline with the parameters specified when the NGS::Tools::BAMSurgeon object is created. Stages can be turned on/off using the following parameters:

	splitbam => 0,
	preparef => 0,
	pickgermmut => 0,
	germsim => 0,
	generatecallable => 0,
	picksomaticmut => 0,
	picktrinucleotides => 0,
	somaticsim => 0,
	makevcf => 0,
	extractleafs => 0,
	mergephases => 0,
	mergechromosomes => 0,
	mergefinal => 0,
	allelecount => 0

=cut

sub run {
	my $self = shift;
	my %args = (
		splitbam => 0,
		preparef => 0,
		pickgermmut => 0,
		germsim => 0,
		generatecallable => 0,
		picksomaticmut => 0,
		picktrinucleotides => 0,
		somaticsim => 0,
		makevcf => 0,
		extractleafs => 0,
		mergephases => 0,
		mergechromosomes => 0,
		mergefinal => 0,
		allelecount => 0,
		@_
		);

	$self->adjust_yaml_for_cna();
	$self->_set_somatic_profile(LoadFile($self->adjusted_somatic_profile_path));

	my $stage_groups = {};
	if($args{splitbam}){
		$stage_groups->{splitbam} = $self->splitbam2chr();
		}
	if($args{preparef}){
		$stage_groups->{preparef} = $self->prepare_reference();
		}
	if($args{pickgermmut}){
		$stage_groups->{pickgermmut} = $self->pick_germ_mutations();
		}
	if($args{germsim}){
		$stage_groups->{germsim} = $self->germline_simulation();
		$self->HPCI_group->add_deps(
			pre_reqs => [ 
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []}
				],
			deps => $stage_groups->{germsim}
			);
		#$self->check_germ();
		}
	if($args{generatecallable}){
		$stage_groups->{generatecallable} = $self->generate_callable_bases();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []}
				],
			deps => $stage_groups->{generatecallable}
			);
		}
	if($args{picksomaticmut}){
		$stage_groups->{picksomaticmut} = $self->pick_somatic_mutations($args{picktrinucleotides});
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []}
				],
			deps => $stage_groups->{picksomaticmut}
			);
		}
	if ($args{splitsubclones}) {
		$stage_groups->{splitsubclones} = $self->split_subclones();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []}
				],
			deps => $stage_groups->{splitsubclones}
			);
		}
	if($args{somaticsim}){
		$stage_groups->{somaticsim} = $self->somatic_simulation();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{somaticsim}
			);
		}
	if($args{makevcf}){
		$stage_groups->{makevcf} = $self->merge_vcf();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{somaticsim} // []},
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{makevcf} 
			);
		}
	if($args{extractleafs}){
		$stage_groups->{extractleafs} = $self->extract_leafs();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{somaticsim} // []},
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{extractleafs} 
			);
		}
	if($args{mergephases}){
		$stage_groups->{mergephases} = $self->merge_to_phases();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{extractleafs} // []},
				@{$stage_groups->{somaticsim} // []},
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{mergephases}
			);
		}
	if($args{mergechromosomes}){
		$stage_groups->{mergechromosomes} = $self->merge_to_chromosomes();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{mergephases} // []},
				@{$stage_groups->{somaticsim} // []},
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{mergechromosomes}
			);
		}
	if($args{mergefinal}){
		$stage_groups->{mergefinal} = $self->merge_to_final();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{mergechromosomes} // []},
				@{$stage_groups->{mergephases} // []},
				@{$stage_groups->{somaticsim} // []},
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{mergefinal}
			);
		}
	if($args{allelecount}){
		$stage_groups->{allelecount} = $self->allelecount();
		$self->HPCI_group->add_deps(
			pre_reqs => [
				@{$stage_groups->{mergechromosomes} // []},
				@{$stage_groups->{mergephases} // []},
				@{$stage_groups->{somaticsim} // []},
				@{$stage_groups->{picksomaticmut} // []},
				@{$stage_groups->{picktrinucleotides} // []},
				@{$stage_groups->{generatecallable} // []},
				@{$stage_groups->{germsim} // []},
				@{$stage_groups->{splitbam} // []},
				@{$stage_groups->{prepareref} // []},
				@{$stage_groups->{pickgermmut} // []},
				@{$stage_groups->{splitsubclones} // []}
				],
			deps => $stage_groups->{allelecount}
			);
		}

	my %hpci_results = %{$self->HPCI_group->execute()};
	my $ret_val = 0;
	foreach my $name (keys %hpci_results) {
		my $stage = $hpci_results{$name};
		my $stage_length = scalar @{$stage};
		$stage->[$stage_length - 1]->{'wallclock_time'} =~ s/^\s+|\s+$//g ;
		print STDOUT "Stage $name took " . $stage->[$stage_length - 1]->{'wallclock_time'} . " seconds.\n";
		if ($stage_length == 0 || $stage->[$stage_length - 1]->{'exit_status'} !~ m/^\s*0\s*$/g) {
			print STDERR "Failure of stage $name\n";
			$ret_val = 1;
			}
		}
	return $ret_val;
	}

sub validate_config {
	my $self = shift;

	if (!defined($self->config->{reference})) {
		croak("YAML config contains no reference file!\n");
		}

	my $cancer_types = YAML::LoadFile(dist_file('NGS-Tools-BAMSurgeon',  'cancer_sigmut.yaml'));
	if (!exists($cancer_types->{$self->config->{cancer}->{name}})) {
		croak("The cancer type specified in the YAML config file is not supported. Please see below for specified cancer types (these are case sensitive):\n\n".
			Dumper(keys %{$cancer_types}));
		}
	}

sub splitbam2chr {
	my $self = shift;

	$self->log->info("splitbam2chr\n");
	$self->log->info("\tbam: " . $self->bam . "\n");

	# For every chromosome, call the module's splitbam2chr function
	my $stages = [];
	foreach my $chr (@{$self->chromosomes}) {
		if (! -e $self->wd . "/chrbam/") {
			make_path($self->wd . "/chrbam/");
			}
		my $stage = $self->HPCI_group->stage(
			name => 'bs_split_' . $chr,
			command => 'samtools view -bh ' . $self->bam . " $chr > " . $self->wd . "/chrbam/$chr.bam",
			resources_required => {
				h_vmem => '3G'
				},
			modules_to_load => [ 'samtools/1.2' ]
			);
		push(@{$stages}, $stage);
		}
	return $stages;
	}

sub prepare_reference {
	my $self = shift;

	$self->log->info("prepare_reference\n");
	$self->log->info("\treference: " . $self->config->{reference} . "\n");

	if (! -e $self->wd . "/chrFa/") {
		make_path($self->wd . "/chrFa/");
		}

	my $stages = [];
	my $command = '';

	# Call the module's generate_index function
	my $program = "bwa index";
	my $params = join(' ',
		"-a bwtsw",
		$self->config->{reference}
		);
	if (! -e $self->config->{reference} . ".bwt") {
		$command .= join(' ',$program,$params);
		}

	my $nix = $self->config->{reference};
	$nix =~ s/.fasta/.nix/g;
	$program = "novoindex";
	$params = join(' ',
		"$nix",
		$self->config->{reference}
		);
	if (! -e $nix) {
		$command .= join(' ',$program,$params);
		}

	my $dict = $self->config->{reference};
	$dict =~ s/.fasta/.dict/g;
	$program = 'java -jar $PICARDROOT/picard.jar CreateSequenceDictionary';
	$params = join(' ',
		"R=" . $self->config->{reference},
		"O=$dict"
		);
	if (! -e $dict) {
		$command .= join(' ',$program,$params);	
		}

	my $gen_index_stage = $self->HPCI_group->stage(
		name => 'bs_prep_ref_gen_index',
		command => $command,
		resources_required => {
				h_vmem => '8G'
				},
		modules_to_load => [ 'bwa/0.7.12', 'picard/1.130' ]
		);
	push(@{$stages}, $gen_index_stage);

	# Call the module's split_genome function
	my $split_genome_stage = $self->HPCI_group->stage(
		name => 'bs_prep_ref_split_genome',
		command => "cd " . $self->wd . "/chrFa/; awk '/^>/ {s = ++d\".fa\"} {print > s}' " . $self->config->{reference} . "; mv 23.fa X.fa; mv 24.fa Y.fa; mv 25.fa MT.fa; rm [3-9][0-9].fa; rm 2[6-9].fa",
		resources_required => {
			h_vmem => '2G'
			}
		);
	push(@{$stages}, $split_genome_stage);
	$self->HPCI_group->add_deps(
		pre_reqs => [ $gen_index_stage ],
		deps => [ $split_genome_stage ]
		);

	# For every chromosome, call the module's faidx_parallel function
	foreach my $chr (@{$self->chromosomes}) {
		my $faidx_stage = $self->HPCI_group->stage(
			name => 'bs_prep_ref_faidx_parallel_' . $chr,
			command => "cd " . $self->wd . "/chrFa/; samtools faidx $chr.fa",
			resources_required => {
				h_vmem => '2G'
				},
			modules_to_load => [ 'samtools/1.2' ]
			);
		push(@{$stages}, $faidx_stage);
		$self->HPCI_group->add_deps(
			pre_reqs => [ $split_genome_stage ],
			deps => [ $faidx_stage ]
			);
		}

	return $stages;
	}

sub generate_callable_bases {
	my $self = shift;

	$self->log->info("generate_callable_bases\n");
	$self->log->info("\tbam: " . $self->bam . "\n");
	$self->log->info("\tsex: " . $self->sex . "\n");

	my $min_cov = 10;
	my $stages = [];

	foreach my $chr (@{$self->chromosomes}) {
		my $phase_stages = [];
		my @phases = (0,1);
		if ($self->sex eq 'M' && ($chr eq 'X' || $chr eq 'Y')) {
			@phases = (0);
			}
		if (! -e $self->wd . "/cb_bed/chr$chr") {
			make_path($self->wd . "/cb_bed/chr$chr");
			}
		foreach my $phase (@phases) {
			my $cb_stage = $self->HPCI_group->stage(
				name => "bs_gen_cb_p$phase\_$chr",
				command => "samtools view -b " . $self->wd . "/chrbam/chr$chr/phase.$phase.bam " .
					'| bedtools genomecov -bga -ibam - | awk \'$4 >= ' . $min_cov . ' {print $0}\' > ' . $self->wd . "/cb_bed/chr$chr/phase.$phase.bam.cov$min_cov.bed; " .
					"bedtools merge -i " . $self->wd . "/cb_bed/chr$chr/phase.$phase.bam.cov$min_cov.bed > " . $self->wd . "/cb_bed/chr$chr/phase.$phase.bam.cov$min_cov\_collapsed.bed; ",
				resources_required => {
					h_vmem => '10G'
					},
				modules_to_load => ['Perl-BL', 'Schedule-DRMAAc', 'samtools/1.2', 'bedtools/2.24.0']
				);
			push(@{$stages}, $cb_stage);
			push(@{$phase_stages}, $cb_stage);
			}
		if ($self->sex eq 'M' && ($chr eq 'X' || $chr eq 'Y')) {
			my $mv_stage = $self->HPCI_group->stage(
				name => "bs_gen_cb_p0_$chr\_mv",
				command => "mv " . $self->wd . "/cb_bed/chr$chr/phase.0.bam.cov$min_cov\_collapsed.bed " . $self->wd . "/cb_bed/$chr\_collapsed.bed",
				resources_required => {
					h_vmem => '2G'
					}
				);
			push(@{$stages}, $mv_stage);
			$self->HPCI_group->add_deps(
				pre_reqs => $phase_stages,
				deps => [$mv_stage]
				);
			}
		else {
			my $intersect_stage = $self->HPCI_group->stage(
				name => "bs_gen_cb_intersect_$chr",
				command =>
					"bedtools intersect -a " . $self->wd . "/cb_bed/chr$chr/phase.1.bam.cov$min_cov\_collapsed.bed -b " . $self->wd . "/cb_bed/chr$chr/phase.0.bam.cov$min_cov\_collapsed.bed > " . $self->wd . "/cb_bed/$chr\_unsorted.bed; " .
					"sort -k1,1 -k2,2n " . $self->wd . "/cb_bed/$chr\_unsorted.bed > " . $self->wd . "/cb_bed/$chr\_collapsed.bed",
				resources_required => {
					h_vmem => '2G'
					},
				modules_to_load => ['bedtools'],
				extra_sge_args_string => " -q transient "
				);
			push(@{$stages}, $intersect_stage);
			$self->HPCI_group->add_deps(
				pre_reqs => $phase_stages,
				deps => [$intersect_stage]
				);
			}
		}
	return $stages;
	}

sub allelecount {
	my $self = shift;

	my $stages = [];
	my $generation_stages = [];

	if (! -e $self->output_dir . "/alleleCounts") {
		make_path($self->output_dir . "/alleleCounts");
		}

	foreach my $chr (@{$self->chromosomes}) {
		my $chrname = $chr;
		if ($chrname eq 'X') {
			$chrname = 23;
			}
		if ($chrname eq 'Y') {
			next;
			}
		my $allele_count_stage = $self->HPCI_group->stage(
			name => 'bs_allele_count_' . $chr,
			command => "alleleCounter " .
				"-l " . $self->config->{loci} . "/1000genomesloci2012_chr$chr.txt " .
				"-b " . $self->output_dir . "/chr$chr/output/T.bam " .
				"-o " . $self->output_dir . "/alleleCounts/chr$chrname.txt " .
				"-r " . $self->config->{reference} . " ",
			resources_required => {
				h_vmem => '4G'
				},
			modules_to_load => [ 'alleleCount' ],
			extra_sge_args_string => " -q transient "
			);
		push(@{$stages}, $allele_count_stage);
		push(@{$generation_stages}, $allele_count_stage);
		}
	my $coverage_stage = $self->HPCI_group->stage(
		name => 'bs_allele_count_coverage',
		command => "cd " . $self->output_dir . "/alleleCounts; Rscript " . $self->bin . "/get_coverage.R;",
		resources_required => {
			h_vmem => '4G'
			},
		modules_to_load => [ 'R-BL', 'alleleCount' ],
		extra_sge_args_string => " -q transient "
		);
	push(@{$stages}, $coverage_stage);
	$self->HPCI_group->add_deps(
		pre_reqs => $generation_stages,
		deps => [$coverage_stage],
		);

	return $stages;
	}


=head1 AUTHORS

Christopher Lalansingh - Boutros Lab

Shadrielle Melijah G. Espiritu - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

Lydia Liu - Boutros Lab

Takafumi Yamaguchi - Boutros Lab

Srinivasan Sivanandan - Boutros Lab

Adam D. Ewing - BAMSurgeon author

The Ontario Institute for Cancer Research

=cut

1;

