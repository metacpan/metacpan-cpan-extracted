#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 610_Slurm-SACluster-foo_me.t'
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
our @fake_cluster_data;
require "$testDir/helpers/fake-cluster-data.pl";

my $entity = 'Slurm::Sacctmgr::Cluster';
my $entname = 'cluster';

my $fake_sa = "${testDir}/helpers/fake_sacctmgr_show+echo";

#================================================================================
#		Test definitions, subroutines
#================================================================================

my %cluster_args_by_name = map { $_->{cluster} => $_ } @fake_cluster_data;

sub do_list_me_tests($$)
#Given version number and dryrun flag, do set of tests
#on sacctmgr_list_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);

	my @names = sort ( keys %cluster_args_by_name );
	foreach my $name (@names)
	{	my $data = $cluster_args_by_name{$name};
		my $exp = $entity->new( %$data );
		strip_all_tres_but_cpu_nodes_from_obj($exp) if $slurm_version eq '14';

		my $inst = $entity->new( cluster=>$name);
		my $got = $inst->sacctmgr_list_me($sa);

		is_deeply($got, $exp, "list_me on clus=$name, $setname");
		$num_tests_run++;
	}
}

sub do_add_me_tests($$)
#Given version number and dryrun flag, do set of tests for sacctmgr_add_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following add_me tests...") if ( $dryrun );

	my @new_clusters =
	(	{ 	cluster => 'newcluster',
			classification => 'new',
			controlhost => 'new-master',
			controlport => 6818,
			flags => 'virtual',
			rpc => 7169,
			tres => { node=>100, cpu=>1600, mem=>12800000 },
			cpucount => 1600,
			nodecount => 100,
		},
	);

	foreach my $data (@new_clusters)
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
		my $tmpdata = { %$data };
		if ( $slurm_version eq '14' )
		{	delete $tmpdata->{tres};
		} else
		{	delete $tmpdata->{cpucount};
			delete $tmpdata->{nodecount};
		}
		push @exp, hash_to_arglist_lexical(%$tmpdata);

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
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following delete_me tests...") if ( $dryrun );

	my @names = sort ( keys %cluster_args_by_name );
	foreach my $name (@names)
	{	my $data = $cluster_args_by_name{$name};
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_delete_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

		my $testname = "delete_me on $name, $setname";

		my @exp = ( '-i', 'delete', $entname, 'where' );
		push @exp, hash_to_arglist_lexical($entname => $name);

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
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following modify_me tests...") if ( $dryrun );

	my @updates = ( classification =>'newer class', flags => 'deprecated' );

	my @names = sort ( keys %cluster_args_by_name );
	foreach my $name (@names)
	{	my $data = $cluster_args_by_name{$name};
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
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);
	#print STDERR "sa: dryrun is ", $sa->dryrun, " and verbose is ", $sa->verbose, "\n";
	note("Ignore DRYRUN output for following modify_me tests...") if ( $dryrun );

	my @extra = ( 'extra_flag' => 772 );

	#save/add a new entries
	my @new_clusters =
	(	{ 	cluster => 'newcluster',
			classification => 'new',
			controlhost => 'new-master',
			controlport => 6818,
			flags => 'virtual',
			rpc => 7169,
			tres => { node=>100, cpu=>1600, mem=>12800000 },
			cpucount => 1600,
			nodecount => 100,
		},
	);

	my ($data, $inst, $got, $exp, $testname);
	foreach $data (@new_clusters)
	{	$inst = $entity->new(%$data);
		$inst->sacctmgr_save_me($sa, @extra);
		my $got = $entity->_ebadddel_last_raw_output;

		if ( exists $data->{name} )
		{	$data->{$entname} = delete $data->{name};
		}
		my $name = $data->{$entname};
		$testname = "save_me on new record $name, $setname";

		my @exp = ( '-i', 'add', $entname );
		my $tmpdata = { %$data };
		if ( $slurm_version eq '14' )
		{	delete $tmpdata->{tres};
		} else
		{	delete $tmpdata->{cpucount};
			delete $tmpdata->{nodecount};
		}
		push @exp, hash_to_arglist_lexical(%$tmpdata, @extra);

		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
	

	my $i = -1;
	my @names = sort ( keys %cluster_args_by_name );
	foreach my $name (@names)
	{	$i++;

		$testname = "save_me on existing record $name, $setname, with extra";

		my $data = $cluster_args_by_name{$name};
		my $inst = $entity->new(%$data);

		my @tmpexp = @extra;
		if ( $i > 0 )
		{	my $tmp = 'updated';
			push @tmpexp, flags => $tmp;
			$inst->flags($tmp);
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

		$testname = "save_me on existing record $name, $setname, no updates";

		my $data = $cluster_args_by_name{$name};
		my $inst = $entity->new(%$data);

		my @tmpexp = @extra;
		if ( $i > 0 )
		{	my $tmp = 'updated';
			push @tmpexp, flags => $tmp;
			$inst->flags($tmp);
		}

		$inst->_clear_ebmod_last_raw_output;
		$inst->sacctmgr_save_me($sa,@extra, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		my @exp = ( '-i', 'modify', $entname, 'where' );
		push @exp, hash_to_arglist_lexical($entname => $name);
		push @exp, 'set';
		push @exp, hash_to_arglist_lexical(@extra, @tmpexp);

		my $exp = [ @exp ];

		if ( $dryrun || $i == 0 )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
}

	
	
#================================================================================
#		Test various commands for slurm version, dryrun modes
#================================================================================

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

