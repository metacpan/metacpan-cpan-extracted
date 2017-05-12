package NGS::Tools::BAMSurgeon::Germline;

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

has 'gpercent' => (
	is => 'ro',
	writer => '_set_gpercent',
	default => 0.7
	);

sub check_germ {
	my $self = shift;

	$self->log->info("check_germ\n");

	# Call check_germ in module
	}

sub pick_germ_mutations {
	my $self = shift;

	$self->log->info("pick_germ_mutations\n");
	$self->log->info("\tgermline_profile: " . $self->germline_profile . "\n");

	# to store germline mutations
	if (! -e $self->wd . "/chrbam/germ_mutations/") {
		make_path($self->wd . "/chrbam/germ_mutations/");
		}

	my $stages = [];
	
	# For every chromosome, iterate over the types and muts in the profile
	# Call pick_germ_mutations in the module
	foreach my $chr (@{$self->chromosomes}) {
		foreach my $type (keys $self->germline_profile->{$chr}) {
			foreach my $mut (keys %{$self->germline_profile->{$chr}{$type}}) {
				if (! -e $self->wd . "/chrbam/germ_mutations/" . "pick_$chr\_$mut\_$type.txt") {
					my $split_genome_stage = $self->HPCI_group->stage(
						name => "bs_pick_germ_$chr\_$type\_$mut",
						command => 'randomsites.py ' .
							"-g " . $self->wd . "/chrFa/$chr.fa " .
							"-n " . $self->germline_profile->{$chr}{$type}{$mut}{n} . " " .
							"--avoidN " .
							"--minvaf " . ($self->minvaf // 1) . " " .
							"--maxvaf " . ($self->maxvaf // 1) . " " .
							"'$mut' " .
							"> " . $self->wd . "/chrbam/germ_mutations/" . "pick_$chr\_$mut\_$type.txt",
						resources_required => {
							h_vmem => '1G'
							},
						modules_to_load => ['Python-BL', 'bamsurgeon/0.1.0-local']
						);
					push(@{$stages}, $split_genome_stage);
					}
				}
			}
		}
	return $stages;
	}

sub germline_simulation {
	my $self = shift;

	$self->log->info("germline_simulation\n");
	$self->log->info("\tbam: " . $self->bam . "\n");
	$self->log->info("\treference: " . $self->config->{reference} . "\n");
	$self->log->info("\tgpercent: " . $self->gpercent . "\n");
	$self->log->info("\tsex: " . $self->sex . "\n");
	$self->log->info("\tphasing: " . $self->phasing . "\n");

	my $stages = [];

	foreach my $chr (@{$self->chromosomes}) {
		my $diploid = 1;
		if ($self->sex eq 'M' && ($chr eq 'X' || $chr eq 'Y')) {
			$diploid = 0;
			}
		my $germline_stage = $self->HPCI_group->stage(
			name => 'bs_germline_sim_' . $chr,
			command => "perl " . $self->bin . "/germline.pl " . $self->wd . "/chrbam/ $chr $diploid " . $self->config->{reference} . " " . $self->gpercent . " " . $self->phasing,

			resources_required => {
				h_vmem => '20G'
				},
			modules_to_load => [ 'Perl-BL', 'Schedule-DRMAAc' ]
			);
		push(@{$stages}, $germline_stage);
		}

	return $stages;
	}

1;
