#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 660_Slurm-SAQos-foo_me.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Qos;

my $entity = 'Slurm::Sacctmgr::Qos';
my $entname = 'qos';

my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";
our @fake_qos_data;
require "$testDir/helpers/fake-${entname}-data.pl";

my $fake_sa = "${testDir}/helpers/fake_sacctmgr_show+echo";

#================================================================================
#		Slurm version conversions
#================================================================================


sub deep_copy($);
sub deep_copy($)
#Returns a deep copy of object.
#Non-ref scalars are simply copied;
#Array refs become like [ @$array ] except all elements are deep copied recursively.
#Hash refs become { %$hash } except all values in hash are deep copied recursively.
#
#Returns copy
{	my $original = shift;
	my $me = 'deep_copy';
	return $original unless defined $original; #undef => undef
	return $original unless ref($original); #non-ref => non-ref

	if ( ref($original) eq 'ARRAY' )
	{	my $new = [];
		foreach my $oelem (@$original)
		{	my $nelem = deep_copy($oelem);
			push @$new, $nelem;
		}
		return $new;
	}

	if ( ref($original) eq 'HASH' )
	{	my $new = {};
		my @keys = keys %$original;
		foreach my $key (@keys)
		{	my $oval = $original->{$key};
			my $nval = deep_copy($oval);
			$new->{$key} = $nval;
		}
		return $new;
	}

	die "$me: Don't know how to handle object of type " . ref($original) . ", aborting at ";
}

sub _convert_to_s14_helper($$$$)
#Helper for convert_to_slurm14
#Takes:
#	data: main data hash ref
#	tresfld: name of TRES field
#	tres: name of TRES (key of %$tresfld)
#	pretres: name of preTRES field
{	my $data = shift;
	my $tresfld = shift;
	my $tres = shift;
	my $pretres = shift;

	return unless $data && ref($data) eq 'HASH';
	return unless exists $data->{$tresfld};
	my $tres_hash = $data->{$tresfld};
	return unless $tres_hash && ref($tres_hash) eq 'HASH';
	return unless exists $tres_hash->{$tres};
	my $tres_val = $tres_hash->{$tres};
	return unless defined $tres_val;

	my $pretres_val = $data->{$pretres};
	return if defined $pretres_val; #Already exists, don't clobber

	$data->{$pretres} = $tres_val;
}


	
sub convert_to_slurm14($)
#Converts a hash ref  of key=>value pairs to Slurm14 format
{	my $orig = shift;
	my $me = 'convert_to_slurm14';

	my $new = deep_copy($orig);

	#Convert various TRES flds to non-TRES counterparts if don't already exist

	#grptres
	_convert_to_s14_helper($new, 'grptres', 'cpu', 'grpcpus');
	_convert_to_s14_helper($new, 'grptres', 'node', 'grpnodes');
	#grptresmins
	_convert_to_s14_helper($new, 'grptresmins', 'cpu', 'grpcpumins');
	#maxtresmins
	_convert_to_s14_helper($new, 'maxtresmins', 'cpu', 'maxcpumins');
	#maxtresperjob
	_convert_to_s14_helper($new, 'maxtresperjob', 'cpu', 'maxcpus');
	_convert_to_s14_helper($new, 'maxtresperjob', 'node', 'maxnodes');
	#maxtresperuser
	_convert_to_s14_helper($new, 'maxtresperuser', 'cpu', 'maxcpusperuser');
	_convert_to_s14_helper($new, 'maxtresperuser', 'node', 'maxnodesperuser');
	#mintresperjob
	_convert_to_s14_helper($new, 'mintresperjob', 'cpu', 'mincpus');

	#Delete TRES fields
	my @flds2del = qw(grptres grptresmins maxtresmins maxtresperjob maxtresperuser mintresperjob);
	foreach my $fld (@flds2del) { delete $new->{$fld}; }

	return $new;
}

sub _convert_to_s15_helper($$$$)
#Helper for convert_to_slurm15
#Takes:
#	data: main data hash ref
#	tresfld: name of TRES field
#	tres: name of TRES (key of %$tresfld)
#	pretres: name of preTRES field
{	my $data = shift;
	my $tresfld = shift;
	my $tres = shift;
	my $pretres = shift;

	return unless $data && ref($data) eq 'HASH';
	return unless exists $data->{$pretres};
	my $pretres_val = $data->{$pretres};
	return unless defined $pretres_val;
	
	my $tres_hash = $data->{$tresfld};
	unless ( $tres_hash && ref($tres_hash) eq 'HASH' )
	{	$tres_hash = $data->{$tresfld} = {};
	}

	my $tres_val = $tres_hash->{$tres};
	return if defined $tres_val; #Already defined, don;t clobber
	
	$tres_hash->{$tres} = $pretres_val;
}

sub convert_to_slurm15($)
#Converts a hash ref  of key=>value pairs to Slurm15 format
{	my $orig = shift;
	my $me = 'convert_to_slurm14';

	my $new = deep_copy($orig);
	my ($thash, $tfld, $tval, $ptfld, $ptval);

	#Convert various TRES flds to non-TRES counterparts if don't already exist

	#grptres
	_convert_to_s15_helper($new, 'grptres', 'cpu', 'grpcpus');
	_convert_to_s15_helper($new, 'greptres', 'node', 'grpnodes');
	#grptresmins
	_convert_to_s15_helper($new, 'grptresmins', 'cpu', 'grpcpumins');
	#maxtresmins
	_convert_to_s15_helper($new, 'maxtresmins', 'cpu', 'maxcpumins');
	#maxtresperjob
	_convert_to_s15_helper($new, 'maxtresperjob', 'cpu', 'maxcpus');
	_convert_to_s15_helper($new, 'maxtresperjob', 'node', 'maxnodes');
	#maxtresperuser
	_convert_to_s15_helper($new, 'maxtresperuser', 'cpu', 'maxcpusperuser');
	_convert_to_s15_helper($new, 'maxtresperuser', 'node', 'maxnodesperuser');
	#mintresperjob
	_convert_to_s15_helper($new, 'mintresperjob', 'cpu', 'mincpus');

	#Delete preTRES fields
	my @flds2del = qw(grpcpus grpnodes grpcpumins maxcpumins
		maxcpus maxnodes maxcpusperuser maxnodesperuser mincpus);
	foreach my $fld (@flds2del) { delete $new->{$fld}; }

	return $new;
}

#================================================================================
#		Test definitions, subroutines
#================================================================================

my %qos_args_by_name = map { $_->{name} => $_ } @fake_qos_data;

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

	my @names = sort ( keys %qos_args_by_name );
	foreach my $name (@names)
	{	my $data = $qos_args_by_name{$name};
		my $exp = $entity->new( %$data );
		if ( $slurm_version eq '14' )
		{	strip_all_tres_but_cpu_nodes_from_obj($exp);
		}

		my $inst = $entity->new( name=>$name);
		my $got = $inst->sacctmgr_list_me($sa);

		is_deeply($got, $exp, "list_me on $entname=$name, $setname");
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

	my @new_qos =
	(	{ 	name => 'gpu',
			id => 4,
			description => 'GPU qos',
			gracetime => '57',
			grpjobs => 200, grpsubmitjobs => 100,
			maxjobs => 300, maxsubmitjobs => 150,
			maxwall => 6000, 
			preempt => 'scavenger', preemptmode=>'cluster',
			priority => 25, usagefactor=>3,

			grptresmins => { cpu=>1000000 },
			grptres => { cpu=>1000, node=>50, },
			maxtresmins => { cpu=>60000, },
			maxtresperjob => { cpu=>2000, node=>100 },
			maxtresperuser => { cpu=>500, node=>25, },
			mintresperjob => { cpu=>10, node=>1 },
		},
	);

	foreach my $data (@new_qos)
	{	
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_add_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

		my $testname = $data->{$entname} || $data->{name};
		$testname = "add_me on $testname, $setname";

		if ( exists $data->{$entname} )
		{	$data->{name} = delete $data->{$entname};
		}
		my @exp = ( '-i', 'add', $entname );
		my $data2;
		if ( $slurm_version eq '14' )
		{	$data2 = convert_to_slurm14($data);
		} else
		{	$data2 = convert_to_slurm15($data);
		}
		push @exp, hash_to_arglist_lexical(%$data2);

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

	my @names = sort ( keys %qos_args_by_name );
	foreach my $name (@names)
	{	my $data = $qos_args_by_name{$name};
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_delete_me($sa);
		my $got = $entity->_ebadddel_last_raw_output;

		my $testname = "delete_me on $name, $setname";

		my @exp = ( '-i', 'delete', $entname, 'where' );
		push @exp, hash_to_arglist_lexical(name => $name);

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

	my @updates = ( organization=>'new org', description => 'new desc' );

	my @names = sort ( keys %qos_args_by_name );
	foreach my $name (@names)
	{	my $data = $qos_args_by_name{$name};
		my $inst = $entity->new(%$data);
		$inst->sacctmgr_modify_me($sa,@updates, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		my $testname = "modify_me on $name, $setname";

		my @exp = ( '-i', 'modify', $entname, 'where' );
		push @exp, hash_to_arglist_lexical(name => $name);
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
	my @new_qos =
	(	{ 	name => 'gpu',
			id => 4,
			description => 'GPU qos',
			gracetime => '57',
			grpjobs => 200, grpsubmitjobs => 100,
			maxjobs => 300, maxsubmitjobs => 150,
			maxwall => 6000, 
			preempt => 'scavenger', preemptmode=>'cluster',
			priority => 25, usagefactor=>3,

			grptresmins => [ cpu=>1000000 ],
			grptres => [ cpu=>1000, node=>50, ],
			maxtresmins => [ cpu=>60000, ],
			maxtresperjob => [ cpu=>2000, node=>100 ],
			maxtresperuser => [ cpu=>500, node=>25, ],
			mintresperjob => [ cpu=>10, node=>1 ],
		},
	);

	my ($data, $inst, $got, $exp, $testname);
	foreach $data (@new_qos)
	{	$inst = $entity->new(%$data);
		$inst->sacctmgr_save_me($sa, @extra);
		my $got = $entity->_ebadddel_last_raw_output;

		if ( exists $data->{$entname} )
		{	$data->{name} = delete $data->{$entname};
		}
		my $name = $data->{name};
		$testname = "save_me on new record $name, $setname";

		my @exp = ( '-i', 'add', $entname );
		my $data2;
		if ( $slurm_version eq '14' )
		{	$data2 = convert_to_slurm14($data);
		} else
		{	$data2 = convert_to_slurm15($data);
		}
		push @exp, hash_to_arglist_lexical(%$data2, @extra);

		my $exp = [ @exp ];

		if ( $dryrun )
		{	is_deeply($got,[], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got,$testname);
		}
	}
	

	my @names = sort ( keys %qos_args_by_name );
	my $i = -1;
	my $modulus = 3;
	foreach my $name (@names)
	{	$i++;
		my $mod = $i % $modulus;

		$testname = "save_me on existing record $name, $setname, with extra";
		#print STDERR "starting $testname, mod=$mod\n";

		my $data = $qos_args_by_name{$name};
		my $inst = $entity->new(%$data);

		my @tmpexp = @extra;
		if ( $mod == 1 )
		{	#Change priority
			#print STDERR "Changing priority for $name...\n";
			my $tmp = 201;
			push @tmpexp, priority => $tmp;
			$inst->priority($tmp);
		}
		if ( $mod == 2 )
		{	#Change desc
			#print STDERR "Changing desc for $name...\n";
			my $tmp = 'new desc';
			push @tmpexp, description => $tmp;
			$inst->description($tmp);
		}

		$inst->sacctmgr_save_me($sa,@extra, QUIET=>1);
		my $got = $entity->_ebmod_last_raw_output;

		my @exp = ( '-i', 'modify', $entname, 'where' );
		push @exp, hash_to_arglist_lexical(name => $name);
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

		$testname = "save_me on existing record $name, $setname, no updates";
		#print STDERR "starting $testname, mod=$mod\n";

		my $data = $qos_args_by_name{$name};
		my $inst = $entity->new(%$data);

		my @tmpexp = @extra;
		if ( $mod == 1 )
		{	#Change priority
			#print STDERR "Changing priority for $name...\n";
			my $tmp = 201;
			push @tmpexp, priority => $tmp;
			$inst->priority($tmp);
		}
		if ( $mod == 2 )
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
		push @exp, hash_to_arglist_lexical(name => $name);
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
		#do_save_me_tests($slurm_version, $dryrun);
	}
}


done_testing($num_tests_run);

