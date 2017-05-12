#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 210_Slurm-SACluster-echo.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Cluster;

my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";

my $entity = 'Slurm::Sacctmgr::Cluster';
my $entname = 'cluster';

my %rawoutput_meth_by_function =
(       list    => '_eblist_last_raw_output',
        add     => '_ebadddel_last_raw_output',
        delete  => '_ebadddel_last_raw_output',
        modify  => '_ebmod_last_raw_output',
);


#===========================================================================
#			Define tests to run
#===========================================================================

my @basic_tests = 
(	{	testname => "sacctmgr_list $entname single field",
		meth => 'sacctmgr_list',
		args2use => [ cluster => 'yottascale' ],
	},

	{	testname => "sacctmgr_list $entname multiple fields",
		meth => 'sacctmgr_list',
		args2use => [ cluster => 'yottascale', controlhost => 'ys-master1' ],
	},

	{	testname => "sacctmgr_add $entname (preTRES style)",
		meth => 'sacctmgr_add',
		args2use => [   cluster=>'yottascale', 
				controlhost=>'ys-master1', 
				controlport=>6817, 
				rpc=>7168,
        			nodecount=>1000000, 
				cpucount=>20000000, 
				nodenames=>'compute-[0-99999]',
		],
	},

	{	testname => "sacctmgr_add $entname (postTRES style)",
		meth => 'sacctmgr_add',
		args2use => [   cluster=>'yottascale', 
				controlhost=>'ys-master1', 
				controlport=>6817, 
				rpc=>7168,
        			tres => { node=>1000000, cpu=>20000000, },
				nodenames=>'compute-[0-99999]',
		],
	},

	{	testname => "sacctmgr_add $entname (postTRES str style)",
		meth => 'sacctmgr_add',
		args2use => [   cluster=>'yottascale', 
				controlhost=>'ys-master1', 
				controlport=>6817, 
				rpc=>7168,
        			tres => "cpu=20000000,node=1000000", 
				nodenames=>'compute-[0-99999]',
		],
	},

	{	testname => "sacctmgr_modify $entname (simple)",
		meth => 'sacctmgr_modify',
		args2use => [   cluster=>'yottascale', ],
		args2use2 => [   classificiation => 'virtual', ],
	},

	{	testname => "sacctmgr_modify $entname (preTRES)",
		meth => 'sacctmgr_modify',
		args2use => [   cluster=>'yottascale', ],
		args2use2 => [   cpucount => 20000010, ],
	},

	{	testname => "sacctmgr_modify $entname (postTRES)",
		meth => 'sacctmgr_modify',
		args2use => [   cluster=>'yottascale', ],
		args2use2 => [   tres => { cpu=>20000020, node=>1000001, } ],
	},

	{	testname => "sacctmgr_delete $entname",
		meth => 'sacctmgr_delete',
		args2use => [   cluster=>'yottascale', ],
	},
);

#===========================================================================
#			Routine to run tests
#===========================================================================

sub do_run_tests($$)
#Given slurm version and dryrun flag, run a set of tests
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= ($dryrun)?'DRYRUN':'no dryrun';
	
	my $sa = Slurm::Sacctmgr->new(
		sacctmgr=>"${testDir}/helpers/echo_cmdline",
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	#Common format fields
	my @format = qw( classification cluster controlhost controlport
		flags nodenames pluginidselect rpc);
	if ( $slurm_version eq '14' )
	{	#Add preTRES fields
		push @format, qw(cpucount nodecount);
	} else
	{	#Add postTRES fields
		push @format, qw(tres);
	}
	my $fmtstr = join ",", @format;


	foreach my $test (@basic_tests)
	{	my $tname = $test->{testname};
		my $meth = $test->{meth};
		my $args2use = $test->{args2use} || [];
		my $args2use2 = $test->{args2use2} || [];

		my $testname = "$tname ($setname)";
		my $function = $meth;
		$function =~ s/^sacctmgr_//;

		#Generate expected argument list
		my $exp = [];
		push @$exp, '-i' unless $function eq 'list';
		push @$exp, $function, $entname;
		push @$exp, "format=$fmtstr" if $function eq 'list';
		push @$exp, 'where' if ( $function eq 'modify' || $function eq 'delete' );
		push @$exp, hash_to_arglist_lexical(@$args2use);
		if ( $function eq 'list' )
		{	push @$exp, ( '--parsable2', '--noheader', '--readonly' );
		} elsif ( $function eq 'modify' )
		{	push @$exp, 'set', hash_to_arglist_lexical(@$args2use2);
		}

		my $outmeth = $rawoutput_meth_by_function{$function};

		my @args2give = @$args2use;
		if ( $function eq 'modify' )
		{	@args2give = ( { @$args2use }, { @$args2use2 }, 'QUIET' );
		}

		#Run the command to check
		note("Please ignore [DRYRUN] output below, this is normal") 
			if $dryrun && $function ne 'list';
		$entity->$meth($sa, @args2give);
		my $got = $entity->$outmeth;
		
		if ( $dryrun && $function ne 'list' )
		{	#Dryrun mode
			is_deeply($got, [], "$testname");
			$num_tests_run++;
		} else
		{	check_results($exp,$got, $testname);
		}
	}
}
		
#===========================================================================
#			Actually run the tests
#===========================================================================


my @slurm_versions = ( '14', '15.08.2' );
foreach my $slurm_version (@slurm_versions)
{  foreach my $dryrun (0, 1 )
   { 	do_run_tests($slurm_version,$dryrun);
   }
}

done_testing($num_tests_run);
		
