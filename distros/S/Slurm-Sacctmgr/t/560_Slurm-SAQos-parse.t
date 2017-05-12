#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 560_Slurm-SAQos-parse.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Qos;
my $entity = "Slurm::Sacctmgr::Qos";
my $entname = 'qos';

my $testDir = dirname(abs_path($0));
my $num_tests_run = 0; 
require "${testDir}/helpers/fake-${entname}-data.pl";
my $fake_sa = "${testDir}/helpers/fake_sacctmgr_${entname}";

#=================================================================
#		Set up tests
#=================================================================

my @tests = 
(	{	name => "list all ${entname}s",
		filter => undef,
	},

	{ 	name => "list $entname by name (high-priority)",
		filter => { name => 'high-priority' },
	},

	{ 	name => "list $entname by name (standard)",
		filter => { name => 'standard' },
	},

	{ 	name => "list $entname by name (scavenger)",
		filter => { name => 'scavenger' },
	},

	{ 	name => "list $entname by name (no match)",
		filter => { name => 'zzzNO_SUCH_QOS' },
	},

);

sub filter_fake_data($;$)
{	my $rawfilter = shift;
	my $data = shift;
	$data = generate_fake_objs() unless $data && ref($data) eq 'ARRAY';

	return $data unless $rawfilter && ref($rawfilter) eq 'HASH';
	my $filter = { %$rawfilter };

	my @filterable_fields = qw( name preempt );
	my @data = @$data;

	FILTER_FIELD: foreach my $fld (@filterable_fields)
	{	next FILTER_FIELD unless exists $filter->{$fld};
		my $val = delete $filter->{$fld};
		next FILTER_FIELD unless defined $val;

		@data = grep { $_->{$fld} eq $val } @data;
	}

	if ( %$filter )
	{	my @tmp = keys %$filter;
		my $tmp = join ", ", @tmp;
		die "Extraneous keys [ $tmp ] in filter at ";
	}

	return [ @data ];
}


#=================================================================
#		Routine to run tests
#=================================================================

sub do_run_tests($$)
#Run tests for given slurm_version and dryrun mode
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= ($dryrun)?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(
		sacctmgr=>"$fake_sa", slurm_version => $slurm_version );
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	#Need to regenerate as strip* functions will modify fake data objects
	my $fake_data = generate_fake_objs();


	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $args = $test->{filter} || {};

		my $testname = "$tname ($setname)";


		my $filter = { %$args };
		my $exp = filter_fake_data($filter, $fake_data);
		if ( $slurm_version eq '14' )
		{	strip_all_tres_but_cpu_nodes($exp);
		}

		my $got = $entity->sacctmgr_list($sa, %$args);

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}


#=================================================================
#		Run tests
#=================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);
