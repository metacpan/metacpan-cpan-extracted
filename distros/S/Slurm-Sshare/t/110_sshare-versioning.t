#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 110_sshare-versioning.t

#Test hacks to support/identify which version of sshare we are talking to

use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sshare;

my $testDir = dirname(abs_path($0));

our $num_tests_run = 0;


require "${testDir}/helpers/echo-help.pl";

my $sa = 'Slurm::Sshare';
my $helpersDir = "${testDir}/helpers";
my $sshare_echo = "${helpersDir}/echo_cmdline";
my $sshare_fake = "${helpersDir}/fake_sshare";

my $sshare_opts_partitions = { can_display_partition => 1 };
my $sshare_opts_noparts = { can_display_partition => 0 };

my $got;
my $args;

#-----------------------------------------------------------------------------
#	Check that user setting of can_display_partition info takes and sshare_cmd_supports()
#-----------------------------------------------------------------------------

#Don't check that initially sshare_cmd_supports('can_display_partition') is undef, as sysadmin 
#might change that

#------		Set to true manually
$sa->sshare($sshare_echo, $sshare_opts_partitions);
$sa->_clear_sshare_last_raw_output;

$got = $sa->sshare_cmd_supports('can_display_partition', 1);
is($got, 1, "Manually setting can_display_partition: flag set (cached only)");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "cachedonly does not call sshare");
$num_tests_run++;

$sa->_clear_sshare_last_raw_output;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 1, "Manually setting can_display_partition: flag set");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "Manually setting can_display_partition: sshare not invoked to determine");
$num_tests_run++;

#------		Set to false manually
$sa->sshare($sshare_echo, $sshare_opts_noparts);
$sa->_clear_sshare_last_raw_output;

$got = $sa->sshare_cmd_supports('can_display_partition', 1);
is($got, 0, "Manually unsetting can_display_partition: flag unset (cached only)");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "cachedonly does not call sshare");
$num_tests_run++;

$sa->_clear_sshare_last_raw_output;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 0, "Manually unsetting can_display_partition: flag unset");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "Manually unsetting can_display_partition: sshare not invoked to determine");
$num_tests_run++;

#------		Set to unknown 
$sa->sshare($sshare_echo, { can_display_partition => undef } );
$sa->_clear_sshare_last_raw_output;

$got = $sa->sshare_cmd_supports('can_display_partition',1);
is($got, undef, "can_display_partition set to unknown: got unknown (cached only)");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "cachedonly does not call sshare");
$num_tests_run++;

$sa->_clear_sshare_last_raw_output;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 0, "echo sshare does not support --partition flag");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
$args = [ '--help' ];
check_results($args, $got, "Invoked sshare --help to determine --partition support");

#------		Set to capabilities to empty hash
$sa->sshare($sshare_echo, { } );
$sa->_clear_sshare_last_raw_output;

$got = $sa->sshare_cmd_supports('can_display_partition',1);
is($got, undef, "can_display_partition set to unknown: got unknown (cached only) [2]");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "cachedonly does not call sshare [2]");
$num_tests_run++;

$sa->_clear_sshare_last_raw_output;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 0, "echo sshare does not support --partition flag [2]");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
$args = [ '--help' ];
check_results($args, $got, "Invoked sshare --help to determine --partition support [2]");

#------		don't set capabilities
$sa->sshare($sshare_echo);
$sa->_clear_sshare_last_raw_output;

$got = $sa->sshare_cmd_supports('can_display_partition',1);
is($got, undef, "can_display_partition set to unknown: got unknown (cached only) [3]");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
is($got, undef, "cachedonly does not call sshare [3]");
$num_tests_run++;

$sa->_clear_sshare_last_raw_output;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 0, "echo sshare does not support --partition flag [3]");
$num_tests_run++;
$got = $sa->_sshare_last_raw_output;
$args = [ '--help' ];
check_results($args, $got, "Invoked sshare --help to determine --partition support [3]");

#-----------------------------------------------------------------------------
#	Check that user can set sshare capabilities by version number
#-----------------------------------------------------------------------------

my @version_test_data =
(	{	version=> '14.01.2',
		can_display_partition => 0,
	},
	{	version=> '14',
		can_display_partition => 0,
	},
	{	version=> '2',
		can_display_partition => 0,
	},
	{	version=> '15.1',
		can_display_partition => 1,
	},
	{	version=> '15.08.2',
		can_display_partition => 1,
	},
	{	version=> '16.117e4-rc17',
		can_display_partition => 1,
	},
);

foreach my $testrec (@version_test_data)
{	my $version = $testrec->{version};
	my $partinfo = $testrec->{can_display_partition};
	$sa->sshare($sshare_echo, $version);
	$got = $sa->sshare_cmd_supports('can_display_partition',1);
	is($got, $partinfo, "Setting can_display_partition by version number, version=$version");
	$num_tests_run++;
}



#-----------------------------------------------------------------------------
#	Check that can determine correct status from fake_sshare command
#-----------------------------------------------------------------------------

#----	Emulating version 14 and earlier
$ENV{FAKESSHARE_EMULATE_VERSION}='14';
$sa->sshare($sshare_fake);

$got = $sa->sshare_cmd_supports('can_display_partition',1);
is($got, undef, "capabilities reset when sshare reset");
$num_tests_run++;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 0, "fake_sshare emulating v14 cannot display partition info");
$num_tests_run++;

#----	Emulating version 15.08.2 
$ENV{FAKESSHARE_EMULATE_VERSION}='15.08.2';
$sa->sshare($sshare_fake);

$got = $sa->sshare_cmd_supports('can_display_partition',1);
is($got, undef, "capabilities reset when sshare reset");
$num_tests_run++;
$got = $sa->sshare_cmd_supports('can_display_partition');
is($got, 1, "fake_sshare emulating 15.08.2 can display partition info");
$num_tests_run++;

#-----------------------------------------------------------------------------
#	Test conversion between grpcpumins and grptresmins, etc in new_from_sshare_record
#	Also verify the setting of cached capabilities
#-----------------------------------------------------------------------------



#Records are list refs of
#	test name,
#	string to parse
#	expected parse results
#	expected can_display_partition cached value
my @new_from_sshare_record_test_data =
(	

#Old style format
#Account|User|Raw Shares|Norm Shares|Raw Usage|Norm Usage|Effectv Usage|FairShare|GrpCPUMins|CPURunMins|

   [ 	"Old version root record",
	"root|||1.000000|9990||1.000000|0.50000||21600|",
	{	account=>'root',
		normalized_shares=>'1.000000',
		raw_usage=>9990,
		effective_usage=>'1.000000',
		fairshare=> '0.50000',
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600 },
	},
	undef, #Doesn't change cached caps
   ],

   [ 	"Old version account record",
	" abc124||1|0.000534|1700|0.170000|0.100000|0.08888|9000|2300|",
	{	account=>'abc124',
		raw_shares=>1,
		normalized_shares=>0.000534,
		raw_usage=>1700,
		normalized_usage=>'0.170000',
		effective_usage=>'0.100000',
		fairshare=> 0.08888,
		grpcpumins => 9000,
		grptresmins => { cpu => 9000 },
		cpurunmins => 2300,
		tresrunmins => { cpu => 2300 },
	},
	undef, #Doesn't change cached caps
   ],

   [ 	"Old version user record",
	"  abc124|george|1|0.000534|1700|0.170000|0.100000|0.08888||2300|",
	{	account=>'abc124',
		user=>'george',
		raw_shares=>1,
		normalized_shares=>0.000534,
		raw_usage=>1700,
		normalized_usage=>'0.170000',
		effective_usage=>'0.100000',
		fairshare=> 0.08888,
		cpurunmins => 2300,
		tresrunmins => { cpu => 2300 },
	},
	undef, #Doesn't change cached caps
   ],

#New style format, sans partition info
#Account|User|RawShares|NormShares|RawUsage|NormUsage|EffectvUsage|FairShare|GrpTRESMins|TRESRunMins|

   [	"15.08.2 version, root record, no partinfo",
	"root|||1.000000|9990||0.50000|||cpu=21600,mem=19992000,energy=0,node=117,gres/gpu=6|",
	{	account=>'root',
		normalized_shares=>'1.000000',
		raw_usage=>9990,
		effective_usage=> '0.50000',
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600, mem=>19992000, energy=>0, node=>117, 'gres/gpu'=>6 },
	},
	1, #Sets to can_display_partition
   ],
	
   [	"15.08.2 version, account record, no partinfo",
	" abc124||1|0.033333|2990|0.0817417|0.077771|0.250000|cpu=50000,node=300|cpu=21600,mem=19992000,energy=0,node=117,gres/gpu=6|",
	{	account=>'abc124',
		raw_shares => 1,
		normalized_shares=>'0.033333',
		raw_usage=>2990,
		normalized_usage=>0.0817417,
		effective_usage=> 0.077771,
		fairshare => '0.250000',
		grpcpumins => 50000,
		grptresmins => { cpu => 50000, node=>300 },
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600, mem=>19992000, energy=>0, node=>117, 'gres/gpu'=>6 },
	},
	1, #Sets to can_display_partition
   ],
	
   [	"15.08.2 version, user record, no partinfo",
	" abc124|george|1|0.033333|2990|0.0817417|0.077771|0.250000||cpu=21600,mem=19992000,energy=0,node=117,gres/gpu=6|",
	{	account=>'abc124',
		user => 'george',
		raw_shares => 1,
		normalized_shares=>'0.033333',
		raw_usage=>2990,
		normalized_usage=>0.0817417,
		effective_usage=> 0.077771,
		fairshare => '0.250000',
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600, mem=>19992000, energy=>0, node=>117, 'gres/gpu'=>6 },
	},
	1, #Sets to can_display_partition
   ],
	
#New style format, with partition info
#Account|User|Partition|RawShares|NormShares|RawUsage|NormUsage|EffectvUsage|FairShare|GrpTRESMins|TRESRunMins|
   [	"15.08.2 version, root record, w partinfo",
	"root||||1.000000|9990||0.50000|||cpu=21600,mem=19992000,energy=0,node=117,gres/gpu=6|",
	{	account=>'root',
		normalized_shares=>'1.000000',
		raw_usage=>9990,
		effective_usage=> '0.50000',
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600, mem=>19992000, energy=>0, node=>117, 'gres/gpu'=>6 },
	},
	1, #Sets to can_display_partition
   ],
	
   [	"15.08.2 version, account record, w partinfo",
	" abc124|||1|0.033333|2990|0.0817417|0.077771|0.250000|cpu=50000,node=300|cpu=21600,mem=19992000,energy=0,node=117,gres/gpu=6|",
	{	account=>'abc124',
		raw_shares => 1,
		normalized_shares=>'0.033333',
		raw_usage=>2990,
		normalized_usage=>0.0817417,
		effective_usage=> 0.077771,
		fairshare => '0.250000',
		grpcpumins => 50000,
		grptresmins => { cpu => 50000, node=>300 },
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600, mem=>19992000, energy=>0, node=>117, 'gres/gpu'=>6 },
	},
	1, #Sets to can_display_partition
   ],
	
   [	"15.08.2 version, user record, w partinfo",
	" abc124|george|standard|1|0.033333|2990|0.0817417|0.077771|0.250000||cpu=21600,mem=19992000,energy=0,node=117,gres/gpu=6|",
	{	account=>'abc124',
		user => 'george',
		partition => 'standard',
		raw_shares => 1,
		normalized_shares=>'0.033333',
		raw_usage=>2990,
		normalized_usage=>0.0817417,
		effective_usage=> 0.077771,
		fairshare => '0.250000',
		cpurunmins => 21600,
		tresrunmins => { cpu => 21600, mem=>19992000, energy=>0, node=>117, 'gres/gpu'=>6 },
	},
	1, #Sets to can_display_partition
   ],
	
);

foreach my $testrec (@new_from_sshare_record_test_data)
{	my ( $name, $string, $expected, $expcap ) = @$testrec;
	my $record = [ split '\|', $string ];

	$sa->sshare($sshare_fake); #Clear cached capabilities
	$got = $sa->new_from_sshare_record($record);
	is_deeply($got, $expected, "${name}: parsed value");
	$num_tests_run++;

	$got = $sa->sshare_cmd_supports('can_display_partition',1);
	is($got, $expcap, "${name}: cached capabilities");
	$num_tests_run++;
}


#-----------------------------------------------------------------------------
#	Finished
#-----------------------------------------------------------------------------

done_testing($num_tests_run);

