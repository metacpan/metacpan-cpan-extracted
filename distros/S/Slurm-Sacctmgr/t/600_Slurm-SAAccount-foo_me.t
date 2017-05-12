#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 600_Slurm-SAAccount-foo_me.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Account;
my $entity = 'Slurm::Sacctmgr::Account';
my $entname = 'account';


my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";
our @fake_account_data;
require "$testDir/helpers/fake-account-data.pl";


my $fake_sa = "${testDir}/helpers/fake_sacctmgr_show+echo";

#===============================================================================
#		Test definitions, subroutines
#===============================================================================

my %account_args_by_name = map { $_->{account} => $_ } @fake_account_data;

sub do_list_me_tests($$)
#Given version number and dryrun flag, do set of tests
#on sacctmgr_list_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);

	my @names = sort ( keys %account_args_by_name );
	foreach my $name (@names)
	{	my $data = $account_args_by_name{$name};
		my $exp = $entity->new( %$data );

		my $inst = $entity->new( account=>$name);
		my $got = $inst->sacctmgr_list_me($sa);

		is_deeply($got, $exp, "list_me on acct=$name, $setname");
		$num_tests_run++;
	}
}

sub do_add_me_tests($$)
#Given version number and dryrun flag, do set of tests for sacctmgr_add_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, 
	#	" and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following add_me tests...") 
		if ( $dryrun );

	my @new_accounts =
	(	{ 	account => 'xxx',
			organization => 'xx',
			description => 'new account',
		},
	);

	foreach my $data (@new_accounts)
	{	
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_add_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

		my $testname = $data->{$entname} || $data->{name};
		$testname = "add_me on $testname, $setname";

		if ( exists $data->{name} )
		{	$data->{$entname} = delete $data->{name};
		}
		my @exp = ( '-i', 'add', $entname );
		push @exp, hash_to_arglist_lexical(%$data);

		my $exp = [ @exp ];


		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
}

sub do_delete_me_tests($$)
#Given version number and dryrun flag, do set of tests for sacctmgr_delete_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, 
	#	" and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following delete_me tests...") 
		if ( $dryrun );

	my @names = sort ( keys %account_args_by_name );
	foreach my $name (@names)
	{	my $data = $account_args_by_name{$name};
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_delete_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

		my $testname = "delete_me on $name, $setname";

		my @exp = ( '-i', 'delete', $entname, 'where' );
		push @exp, hash_to_arglist_lexical( $entname => $name);

		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
}

sub do_modify_me_tests($$)
#Given version number and dryrun flag, do set of tests for sacctmgr_modify_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, 
	#	" and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following modify_me tests...") 
		if ( $dryrun );

	my @updates = ( organization=>'new org', description => 'new desc' );

	my @names = sort ( keys %account_args_by_name );
	foreach my $name (@names)
	{	my $data = $account_args_by_name{$name};
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_modify_me($sa,@updates, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		my $testname = "modify_me on $name, $setname";

		my @exp = ( '-i', 'modify', $entname, 'where' );
		push @exp, hash_to_arglist_lexical($entname => $name);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@updates);


		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
}

sub do_save_me_tests($$)
#Given version number and dryrun flag, do set of tests for sacctmgr_save_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, 
	#	" and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following modify_me tests...") 
		if ( $dryrun );

	my @extra = ( 'extra_flag' => 772 );

	#save/add a new entries
	my @new_accounts =
	(	{ 	account => 'xxx',
			organization => 'xx',
			description => 'new account',
		},
	);

	my ($data, $inst, $got, $exp, $testname);
	foreach $data (@new_accounts)
	{	$inst = $entity->new(%$data);
		$inst->sacctmgr_save_me($sa, @extra);
		my $got = $entity->_ebadddel_last_raw_output;

		if ( exists $data->{name} )
		{	$data->{$entname} = delete $data->{name};
		}
		my $name = $data->{$entname};
		$testname = "save_me on new record $name, $setname";

		my @exp = ( '-i', 'add', $entname );
		push @exp, hash_to_arglist_lexical(%$data, @extra);

		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
	

	my @names = sort ( keys %account_args_by_name );
	my $i = -1;
	my $modulus = 4;
	foreach my $name (@names)
	{	$i++;
		my $mod = $i % $modulus;

		$testname = "save_me on existing record $name, $setname, " .
			"with extra";
		#print STDERR "starting $testname, mod=$mod\n";

		my $data = $account_args_by_name{$name};
		my $inst = $entity->new(%$data);

		my @tmpexp = @extra;
		if ( $mod == 1 || $mod == 3 )
		{	#Change org
			#print STDERR "Changing org for $name...\n";
			my $tmp = 'new org';
			push @tmpexp, organization => $tmp;
			$inst->organization($tmp);
		}
		if ( $mod == 2 || $mod == 3 )
		{	#Change desc
			#print STDERR "Changing desc for $name...\n";
			my $tmp = 'new desc';
			push @tmpexp, description => $tmp;
			$inst->description($tmp);
		}

		$inst->sacctmgr_save_me($sa,@extra, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		my @exp = ( '-i', 'modify', $entname, 'where' );
		push @exp, hash_to_arglist_lexical($entname => $name);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@extra, @tmpexp);

		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}

	$i = -1;
	@extra = ();
	foreach my $name (@names)
	{	$i++;
		my $mod = $i % $modulus;

		$testname = "save_me on existing record $name, $setname, " .
			"no updates";
		#print STDERR "starting $testname, mod=$mod\n";

		my $data = $account_args_by_name{$name};
		my $inst = $entity->new(%$data);

		my @tmpexp = @extra;
		if ( $mod == 1 || $mod == 3 )
		{	#Change org
			#print STDERR "Changing org for $name...\n";
			my $tmp = 'new org';
			push @tmpexp, organization => $tmp;
			$inst->organization($tmp);
		}
		if ( $mod == 2 || $mod == 3 )
		{	#Change desc
			#print STDERR "Changing desc for $name...\n";
			my $tmp = 'new desc';
			push @tmpexp, description => $tmp;
			$inst->description($tmp);
		}

		$inst->_clear_ebmod_last_raw_output;
		$inst->sacctmgr_save_me($sa,@extra, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		my @exp = ( '-i', 'modify', $entname, 'where' );
		push @exp, hash_to_arglist_lexical($entname => $name);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@extra, @tmpexp);

		my $exp = [ @exp ];

		#print STDERR "mod=$mod\n";
		if ( $dryrun || $mod == 0 )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
}

	
	
#===============================================================================
#		Test various commands for slurm version, dryrun modes
#===============================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	
		do_list_me_tests($slurm_version, $dryrun);
		do_add_me_tests($slurm_version, $dryrun);
		do_delete_me_tests($slurm_version, $dryrun);
		do_modify_me_tests($slurm_version, $dryrun);
		do_save_me_tests($slurm_version, $dryrun);
	}
}


done_testing($num_tests_run);

