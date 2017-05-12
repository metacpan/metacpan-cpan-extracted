#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 262_Slurm-SAResource-echo.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Resource;
my $entity = 'Slurm::Sacctmgr::Resource';
my $entname = 'resource';

my $testDir = dirname(abs_path($0));
my $fake_sa = "${testDir}/helpers/echo_cmdline";
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";

#=====================================================================
#		Define our tests
#=====================================================================

my @tests =
(	{	name => "sacctmgr_list $entname (single field)",
		meth => 'sacctmgr_list',
		args2use => [ name => 'matlab' ],
	},

	{	name => "sacctmgr_list $entname (multiple fields)",
		meth => 'sacctmgr_list',
		args2use => [ name => 'matlab', cluster => 'yottascale',  ],
	},

	{	name => "sacctmgr_add $entname",
		meth => 'sacctmgr_add',
		args2use => [ 	name => 'abaqus',
				servertype => 'flexlm',
				type => 'License',
				description => 'test',
				server => 'flexlm.umd.edu',
				count => '10',
				percentallowed => 100,
				allocated => 100,
				cluster => 'yottascale',
			],
	},

	{	name => "sacctmgr_modify $entname",
		meth => 'sacctmgr_modify',
		args2use => [ name => 'abaqus', ],
		args2use2 => [ count=> '20', ],
	},

	{	name => "sacctmgr_delete $entname",
		meth => 'sacctmgr_delete',
		args2use => [ name => 'abaqus' ],
	},
);

#=====================================================================
#		Routine to run tests
#=====================================================================

#Format strings we expect
my @format_common = qw(cluster count description name percentallowed 
	server servertype type flags allocated);
my @format_preTRES = qw(  );
my @format_postTRES = qw( );
my @list_suffix_args = ( '--parsable2', '--noheader', '--readonly' );


my %rawoutput_meth_by_function =
(       list    => '_eblist_last_raw_output',
        add     => '_ebadddel_last_raw_output',
        delete  => '_ebadddel_last_raw_output',
        modify  => '_ebmod_last_raw_output',
);

sub do_run_tests($$)
#Run tests with given slurm_version, dryrun
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>$fake_sa, slurm_version=>$slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	my @format = @format_common;
	if ( $slurm_version eq '14' )
	{	push @format, @format_preTRES;
	} else
	{	push @format, @format_postTRES;
	}
	my $fmtstr = join ',', @format;

	TEST: foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $meth = $test->{meth};
		my $args2use = $test->{args2use};
		my $args2use2 = $test->{args2use2};

		my $testname = "$tname ($setname)";
		my $function = $meth; $function =~ s/^sacctmgr_//;

		my @expargs = ();
		push @expargs, '-i' unless $function eq 'list';
		push @expargs, $function, $entname;

		push @expargs, "format=$fmtstr", "withcluster" if $function eq 'list';
		if ( $function eq 'modify' )
		{	push @expargs, 'where', hash_to_arglist_lexical(@$args2use);
			push @expargs, 'set', hash_to_arglist_lexical(@$args2use2);
		} elsif ( $function eq 'delete' )
		{	push @expargs, 'where', hash_to_arglist_lexical(@$args2use);
		} else
		{	#Everything else just takes args from args2use
			push @expargs, hash_to_arglist_lexical(@$args2use);
		}
		push @expargs, @list_suffix_args if $function eq 'list';

		my $outmeth = $rawoutput_meth_by_function{$function};
		my @args2give = @$args2use;
		if ( $function eq 'modify' )
		{	@args2give = ( { @$args2use }, { @$args2use2 }, 1 );
		}

		my $exp = [ @expargs ];
		note( "Please ignore [DRYRUN] output below, this is normal") if $dryrun && $function ne 'list';
		$entity->$meth($sa, @args2give);

		my $got = $entity->$outmeth;

		if ( $dryrun && $function ne 'list' )
		{	is_deeply($got, [], $testname);
			$num_tests_run++;
		} else
		{	check_results($exp, $got, $testname);
		}
	}
}

		
#=====================================================================
#		Actually run the tests
#=====================================================================

my @slurm_versions = ( '14', '15.08.2' );
foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1 )
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);
