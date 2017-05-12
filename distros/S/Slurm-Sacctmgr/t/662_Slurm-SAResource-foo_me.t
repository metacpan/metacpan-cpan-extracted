#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 662_Slurm-SAResource-foo_me.t'
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

require "$testDir/helpers/echo-help.pl";
my $fake_sa = "${testDir}/helpers/fake_sacctmgr_show+echo";

our $num_tests_run = 0;
our @fake_resource_data;
require "$testDir/helpers/fake-resource-data.pl";

#===============================================================================
#		Test definitions, subroutines
#===============================================================================

my %resource_args_by_name = map { $_->{name} => $_ } @fake_resource_data;

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

	foreach my $record (@fake_resource_data)
	{	my $name = $record->{name};
		my $cluster = $record->{cluster};

		my $exp = $entity->new( %$record );
		my $inst = $entity->new( name=>$name, cluster=>$cluster);
		my $got = $inst->sacctmgr_list_me($sa);

		$cluster = '' unless defined $cluster;
		is_deeply($got, $exp, "list_me on $entname=$name/$cluster, $setname");
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
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", 
	#$sa->verbose, "\n";
	note("Ignore DRYRUN output for following add_me tests...") 
		if ( $dryrun );

	my @new_accounts =
	(	{ 	name => 'abaqus',
			servertype => 'flexlm',
			type => 'License',
			description => 'test',
			server => 'flexlm.umd.edu',
			count => 10,
			percentallowed => 100,
			#allocated => 100,  #This is read only
			cluster => 'yottascale',
		},
	);

	foreach my $data (@new_accounts)
	{	
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_add_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

		my $testname = $data->{$entname} || $data->{name};
		$testname = "add_me on $testname, $setname";

		#if ( exists $data->{name} )
		#{	$data->{$entname} = delete $data->{name};
		#}
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
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", 
	#$sa->verbose, "\n";
	note("Ignore DRYRUN output for following delete_me tests...") 
		if ( $dryrun );

	foreach my $record (@fake_resource_data)
	{	my $name = $record->{name};
		my $cluster = $record->{cluster};

		my $inst = $entity->new( name=>$name, cluster=>$cluster);

		my @exp = ( '-i', 'delete', $entname, 'where' );
		my @where = ( name => $name, );
		push @where, ( cluster => $cluster ) if defined $cluster;
		push @exp, hash_to_arglist_lexical(@where);
		my $exp = [ @exp ];

		$cluster = '' unless defined $cluster;
		my $testname = "delete_me on $name/$cluster, $setname";

		$inst->sacctmgr_delete_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

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
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", 
	# $sa->verbose, "\n";
	note("Ignore DRYRUN output for following modify_me tests...") 
		if ( $dryrun );

	my @updates = ( count=>999, );

	foreach my $record (@fake_resource_data)
	{	my $name = $record->{name};
		my $cluster = $record->{cluster};

		my @exp = ( '-i', 'modify', $entname, 'where' );
		my @where = ( name => $name, );
		push @where, ( cluster => $cluster ) if defined $cluster;
		push @exp, hash_to_arglist_lexical(@where);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@updates);

		my $inst = $entity->new( name=>$name, cluster=>$cluster);

		$inst->sacctmgr_modify_me($sa,@updates, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		$cluster = '' unless defined $cluster;
		my $testname = "modify_me on $name/$cluster, $setname";


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
	(	{ 	name => 'abaqus',
			servertype => 'flexlm',
			type => 'License',
			description => 'test',
			server => 'flexlm.umd.edu',
			count => 10,
			percentallowed => 100,
			#allocated => 100, #this is readonly
			cluster => 'yottascale',
		},
	);

	my ($data, $inst, $got, $exp, $testname);
	foreach $data (@new_accounts)
	{	
		my @exp = ( '-i', 'add', $entname );
		push @exp, hash_to_arglist_lexical(%$data, @extra);

		$inst = $entity->new(%$data);
		$inst->sacctmgr_save_me($sa, @extra);
		my $got = $entity->_ebadddel_last_raw_output;

		my $name = $data->{name};
		$testname = "save_me on new record $name, $setname";

		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
	

	my $i = -1;
	my $modulus = 3;
	foreach my $data (@fake_resource_data)
	{	$i++;
		my $mod = $i % $modulus;
		my $inst = $entity->new(%$data);

		my $name = $data->{name};
		my $cluster = $data->{cluster};
		my $cluster2 = (defined $cluster)?$cluster:'';

		my $testname = "save_me on existing record $name/$cluster2 " .
			"with extra ($setname)";
		my @tmpexp = @extra;
		if ( $mod == 1 || $mod == 2 )
		{	#Change count
			#print STDERR "Changing count for $name/$cluster2...\n";
			my $tmp = 999;
			push @tmpexp, count => $tmp;
			$inst->count($tmp);
		}
		if ( $mod == 2 )
		{	#Change description
			#print STDERR "Changing description for $name...\n";
			my $tmp = 'new descr';
			push @tmpexp, description => $tmp;
			$inst->description($tmp);
		}

		my @exp = ( '-i', 'modify', $entname, 'where' );
		my @where = ( name => $name, );
		push @where, ( cluster => $cluster ) if defined $cluster;
		push @exp, hash_to_arglist_lexical(@where);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@extra, @tmpexp);
		my $exp = [ @exp ];

		$inst->sacctmgr_save_me($sa,@extra, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;



		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}

	$i = -1;
	@extra = ();
	foreach my $data (@fake_resource_data)
	{	$i++;
		my $mod = $i % $modulus;
		my $inst = $entity->new(%$data);

		my $name = $data->{name};
		my $cluster = $data->{cluster};
		my $cluster2 = (defined $cluster)?$cluster:'';

		my $testname = "save_me on existing record $name/$cluster2 " .
			"no updates ($setname)";
		my @tmpexp = @extra;
		if ( $mod == 1 || $mod == 2 )
		{	#Change count
			#print STDERR "Changing count for $name/$cluster2...\n";
			my $tmp = 999;
			push @tmpexp, count => $tmp;
			$inst->count($tmp);
		}
		if ( $mod == 2 )
		{	#Change description
			#print STDERR "Changing description for $name...\n";
			my $tmp = 'new descr';
			push @tmpexp, description => $tmp;
			$inst->description($tmp);
		}

		my @exp = ( '-i', 'modify', $entname, 'where' );
		my @where = ( name => $name, );
		push @where, ( cluster => $cluster ) if defined $cluster;
		push @exp, hash_to_arglist_lexical(@where);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@extra, @tmpexp);
		my $exp = [ @exp ];

		$inst->_clear_ebmod_last_raw_output;
		$inst->sacctmgr_save_me($sa,@extra, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;



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

