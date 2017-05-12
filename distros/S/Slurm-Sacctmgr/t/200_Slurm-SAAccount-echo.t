#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 200_Slurm-SAAccount-echo.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Account;

my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";

my $entity = 'Slurm::Sacctmgr::Account';
my $entname = 'account';

#Tests to run
my @basic_tests = 
(	{ 	name => "sacctmgr_list $entname single field",
		meth => 'sacctmgr_list',
		args2use => [ name => 'testacct1', ],
	},

	{ 	name => "sacctmgr_list $entname multi-fields",
		meth => 'sacctmgr_list',
		args2use => [ 	cluster=>'yottascale', 
				organization=>'nsa',
			],
	},

	{	name => "sacctmgr_add $entname",
		meth => 'sacctmgr_add',
		args2use => [ 	cluster=>'yottascale',
				organization => 'nsa',
				parent => 'special',
				name => 'abc124', 
			],
	},

	{	name => "sacctmgr_modify $entname",
		meth => 'sacctmgr_modify',
		args2use => [ 	cluster=>'yottascale',
				organization => 'nsa',
				account => 'abc124', 
			],
		args2use2 => [	parent => 'topsecret',
				rawusage => 0,
			],
	},

	{	name => "sacctmgr_delete $entname",
		meth => 'sacctmgr_delete',
		args2use => [ 	cluster=>'yottascale',
				account => 'abc124',
			],
	},

);

#Format strings we expect
my @format_common = qw( account description organization coordinators );
my @format_preTRES = qw(  );
my @format_postTRES = qw( );
my (@format, $fmtstr);
my @list_suffix_args = ( '--parsable2', '--noheader', '--readonly' );

my ($setname, $sa, $slurm_version);

my ($record, $name, $meth, $args2use, $args2use2, $function, $outmeth );
my (@expargs, @args2give);
my ($got, $exp);

my %rawoutput_meth_by_function =
(	list 	=> '_eblist_last_raw_output',
	add  	=> '_ebadddel_last_raw_output',
	delete  => '_ebadddel_last_raw_output',
	modify  => '_ebmod_last_raw_output',
);

#================================================================================
#		Test various commands with echo sacctmgr
#================================================================================

my @slurm_versions = ( '14', '15.08.2' );
foreach my $slurm_version (@slurm_versions)
{  foreach my $dryrun (0, 1 )
   {

	$setname = "slurm $slurm_version, ";
	$setname .= ($dryrun)?'DRYRUN':'no dryrun';
	$sa = Slurm::Sacctmgr->new(sacctmgr=>"${testDir}/helpers/echo_cmdline", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	@format = @format_common;
	if ( $slurm_version eq '14' )
	{	push @format, @format_preTRES;
	} else
	{	push @format, @format_postTRES;
	}
	$fmtstr = join ',', @format;


	BASIC_TEST: foreach $record (@basic_tests)
	{	$name = $record->{name};
		$meth = $record->{meth};
		$args2use = $record->{args2use};
		$args2use2 = $record->{args2use2};

		$function = $meth; $function=~ s/^sacctmgr_//;

		#note('Ignore output to stderr about return value from sacctmgr_modify')
		#	if $function eq 'modify';

		@expargs = ();
		push @expargs, '-i' unless $function eq 'list';
		push @expargs, $function, $entname;

		push @expargs, "format=$fmtstr", "withcoord" if $function eq 'list';
		if ( $function eq 'modify' )
		{	push @expargs, 'where', hash_to_arglist_lexical(@$args2use);
			push @expargs, 'set', hash_to_arglist_lexical(@$args2use2);
		} elsif ( $function eq 'delete' )
		{	push @expargs, 'where', hash_to_arglist_lexical(@$args2use);
		} else
		{ 	#Everything else just takes the args from args2use
			push @expargs, hash_to_arglist_lexical(@$args2use); 
		}
		push @expargs, @list_suffix_args if $function eq 'list';

		$outmeth = $rawoutput_meth_by_function{$function};
		#my $clear_meth = "_clear$outmeth";
		#$entity->$clear_meth;

		if ( $function eq 'modify' )
		{	@args2give = ( { @$args2use } , { @$args2use2}, 1 );
		} else
		{	@args2give = @$args2use; 
		}

		$exp = [ @expargs ];
		note("Please ignore [DRYRUN] output below, this is  normal") if $dryrun && $function ne 'list';
		$entity->$meth($sa, @args2give); 

		$got = $entity->$outmeth;
		if ( $dryrun  && $function ne 'list' )
		{	is_deeply($got, [], "$setname: $name");
			$num_tests_run++;
		} else
		{	check_results($exp, $got, "$setname: $name");
		}
	} 
    }
}

done_testing($num_tests_run);

