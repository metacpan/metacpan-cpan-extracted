#!/usr/bin/perl
#
# DESCRIPTION:
#	Test placing passive results via resultdir
#
# AUTHOR:
#	Ton Voon, Opsera Limited
#
# LICENCE:
#	GNU GPLv2

use lib 't';

use strict;
use NSCATest;
use Test::More;

plan 'no_plan';

my $mlh_output = <<ML_OUTPUT;
PING OK - Packet loss = 0%, RTA = 0.46 ms | rta=0.462000ms;3000.000000;5000.000000;0.000000 pl=0%;80;100;0
LINE 1
LINE 2
LINE 3
ML_OUTPUT

my $mls_output = <<ML_OUTPUT;
DISK OK - free space: / 3326 MB (56%); | /=2643MB;5948;5958;0;5968
/ 15272 MB (77%);
/boot 68 MB (69%);
/home 69357 MB (27%);
/var/log 819 MB (84%); | /boot=68MB;88;93;0;98
/home=69357MB;253404;253409;0;253414
/var/log=818MB;970;975;0;980
ML_OUTPUT

# All multiline output needs to have linefeeds substituted with \n
# This is done at Nagios' level
$mlh_output =~ s/\n/\\n/g;
$mls_output =~ s/\n/\\n/g;

my $data = [ 
	["multi_output", 0, $mlh_output ],
	["multi_output", "service1", 0, $mls_output ],
	];

my $check_result_dir="/tmp/testnrd";
if (! -e $check_result_dir) {
	mkdir $check_result_dir or die "Cannot mkdir $check_result_dir: $!";
}
foreach my $config ('resultdir') {
    foreach my $type ('--server_type=Single', '--server_type=Fork', '--server_type=PreFork') {
	my $nsca = NSCATest->new( config => $config );

	system("rm -f $check_result_dir/*");

	$nsca->start($type);

	$nsca->send($data);

	sleep 1;		# Need to wait for --daemon to finish processing

        my $dir = "/tmp/testnrd";
        opendir DIR, "$dir" or die "Cannot opendir $dir: $!";
        my @files = sort grep !/^\.\.?\z/, readdir DIR or die "Cannot readdir: $!";
        closedir DIR;

        is( scalar @files, 2, "Should have two files" );
        like( $files[0], qr/^c\w{6}$/, "1st file has pattern of cXXXXXX" );
        is( $files[0].".ok", $files[1], "With same filename with .ok added at end" );

	# Read contents of both files
	open F, "$dir/$files[0]" or die "Cannot open: $!";
	my $first;
	{ local $/ = undef; $first = <F>; };
	close F;

	like( $first, qr{### Passive Check Result File ###
file_time=\d+
### NRD Check ###
# Time: .*?

host_name=multi_output
check_type=1
scheduled_check=0
reschedule_check=0
latency=\d+\.\d+
start_time=\d+.0
finish_time=\d+.0
return_code=0
output=PING OK - Packet loss = 0%, RTA = 0.46 ms | rta=0.462000ms;3000.000000;5000.000000;0.000000 pl=0%;80;100;0\nLINE 1\nLINE 2\nLINE 3\n

host_name=multi_output
service_description=service1
check_type=1
scheduled_check=0
reschedule_check=0
latency=\d+\.\d+
start_time=\d+.0
finish_time=\d+.0
return_code=0
output=DISK OK - free space: / 3326 MB (56%); | /=2643MB;5948;5958;0;5968\n/ 15272 MB (77%);\n/boot 68 MB (69%);\n/home 69357 MB (27%);\n/var/log 819 MB (        84%); | /boot=68MB;88;93;0;98\n/home=69357MB;253404;253409;0;253414\n/var/log=818MB;970;975;0;980\n

}, "result file has the two results");

	$nsca->stop;
    }
}
