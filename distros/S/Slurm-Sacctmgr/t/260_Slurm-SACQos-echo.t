#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 260_Slurm-SAQos-echo.t'
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
require "$testDir/helpers/echo-help.pl";

our $num_tests_run = 0;
my $fake_sa = "${testDir}/helpers/echo_cmdline";

my %rawoutput_meth_by_function =
(	list	=> '_eblist_last_raw_output',
	add	=> '_ebadddel_last_raw_output',
	delete	=> '_ebadddel_last_raw_output',
	modify	=> '_ebmod_last_raw_output',
);


#===========================================================================
#	Define  tests to run
#===========================================================================

my @tests =
(	{	testname => "sacctmgr list $entname by name (standard)",
		meth => 'sacctmgr_list',
		args2use => [ name => 'standard' ],
	},

	{	testname => "sacctmgr list $entname, multiple fields",
		meth => 'sacctmgr_list',
		args2use => [ name => 'standard', id => 2, ],
	},
		
	{	testname => "sacctmgr add $entname",
		meth => 'sacctmgr_add',
		args2use => [
			name=>'high-priority', 
			description=>'high-priority qos',
			gracetime=>'10', 
			grpcpumins=>60000, grpcpus=>1000, grpjobs=>200, grpnodes=>100, 
			grpsubmitjobs=>150, grpwall=>40000,
			maxcpumins=>120000, maxcpus=>2000, maxjobs=>400, maxnodes=>300,
			maxsubmitjobs=>275, maxwall=>80000,
			preempt=>'scavenger,normal', preemptmode=>'cluster', 
			priority=>10, 
			usagefactor=>2,
		],
	},

	{	testname => "sacctmgr delete $entname",
		meth => 'sacctmgr_delete',
		args2use => [ name => 'high-priority' ],
	},

	{	testname => "sacctmgr modify $entname",
		meth => 'sacctmgr_modify',
		args2use => [ name=>'high-priority' ],
		args2use2 => [ priority=>75 ],
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
	my @format = qw( 
		description
		gracetime
		grpjobs
		grpsubmitjobs
		grpwall
		id
		maxjobs
		maxsubmitjobs
		maxwall
		name
		preempt
		preemptmode
		priority
		usagefactor
		usagethreshold
		flags
	);
	if ( $slurm_version eq '14' )
	{	#Add preTRES fields
		push @format, qw(
			grpcpumins
			grpcpus
			grpnodes
			maxcpumins
			maxcpus
			maxcpusperuser
			maxnodes
			maxnodesperuser
			mincpus
		);
	} else
	{	#Add postTRES fields
		push @format, qw(
			grptresmins
			grptresrunmins
			grptres
			maxtresmins
			maxtresperjob
			maxtrespernode
			maxtresperuser
			mintresperjob
		);
	}
	my $fmtstr = join ",", @format;


	foreach my $test (@tests)
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

__END__

my @listtmp2 = ( '--parsable2', '--noheader', '--readonly' );
@temp = ( name=>'high-priority', );
$results = $saqos->sacctmgr_list($sa,@temp);
$results = $saqos->_eblist_last_raw_output;
$args = [ @listtmp1, hash_to_arglist_lexical(@temp), @listtmp2 ];
check_results($args, $results, 'sacctmgr_list single qos');


@temp = ( preempt=>'scavenger', priority=>10  );
$results = $saqos->sacctmgr_list($sa,@temp);
$results = $saqos->_eblist_last_raw_output;
$args = [ @listtmp1, hash_to_arglist_lexical(@temp), @listtmp2 ];
check_results($args, $results, 'sacctmgr_list qos multi-fields');



#Now verify that nothing is run when we are in debug mode
note('The remaining tests generate [DRYRUN] lines, which you can ignore');
note('We just want to make sure they dont actually _do_ anything');
$sa->dryrun(1);

@temp = ( name=>'high-priority', description=>'high-priority qos',);
$results = $saqos->sacctmgr_add($sa,@temp);
$results =$saqos->_ebadddel_last_raw_output; 
is_deeply( $results, [], "sacctmgr_add qos (dryrun mode)");
$num_tests_run++;

@temp = ( name=>'high-priority',  );
@temp2 = ( priority => 75 );
$temp = { @temp }; 
$temp2 = { @temp2 };
$results = $saqos->sacctmgr_modify($sa,$temp, $temp2);
$results = $saqos->_ebmod_last_raw_output;
is_deeply( $results, [], "sacctmgr_modify qos (dryrun mode)");
$num_tests_run++;

@temp = ( name=>'high-priority', );
$results = $saqos->sacctmgr_delete($sa,@temp);
$results = $saqos->_ebadddel_last_raw_output;
is_deeply( $results, [], "sacctmgr_delete qos (dryrun mode)");
$num_tests_run++;

#This one actually _should_ run, as is just a list
@temp = ( name=>'high-priority', );
$results = $saqos->sacctmgr_list($sa,@temp);
$results = $saqos->_eblist_last_raw_output;
$args = [ @listtmp1, hash_to_arglist(@temp), @listtmp2 ];
check_results($args, $results, 'sacctmgr_list single qos (dryrun mode)');

done_testing($num_tests_run);

