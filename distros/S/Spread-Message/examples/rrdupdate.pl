#!/usr/bin/perl -w

=head1 NAME

rrdupdate.pl - update/create RRDs on the fly using Spread

=head1 SYNOPSIS

rrdupdate -c `pwd`/rrdupdate.cfg

=head1 DESCRIPTION

It is a example OK!

You send it lines of input via the 'polling-rrd' group/mbox

Each line looks like

hostname:epochtime:state:pl:rtta:rttm

where:
	hostname is the name of a host
	epochtime is the oupit of time()
	state is some number from 0 -> 15
	pl is a packet loss 0 -> 100
	rtta is a round-trip ping time
	rttm is the max round-trip time

Like this:

	zz-2468-OP-0805-02:1145857074:15:0:158:160
	zz-2640-OP-0805-05:1145857074:15:0:153:185
	zz-2556-GG-2924-01:1145857074:15:0:53.4:86.6
	zz-2191-GG-2924-01:1145857074:15:0:14.7:47.5
	zz-48GE-02-2924-01:1145857074:15:0:8.45:37.2
	zz-6519-GG-2924-01:1145857074:15:0:89.0:124
	zz-2247O-GG-2924-01:1145857074:15:0:20.2:57.7
	zz-3627-GG-2924-01:1145857074:15:0:38.0:72.3
	zz-3262-GG-2924-01:1145857074:15:0:37.3:42.7
	zz-4114-GG-2924-01:1145857074:15:0:29.2:51.8


=head1 SEE ALSO
        
Spread and Spread::Message
 
cheers  
markp   
 
Mon Jul 14 15:20:47 EST 2003

=cut

require 5.0;              # To make sure we only run under perl 5.0
use strict;               # To generate all manner of warning's about poor code
use Utils;                # Utility subs
use RRDs;
use Spread::Message;

$|=1;

# Variables we're going to use
my(
    $Program_Name,     # The name of the program running
    $Version,          # What version we are upto
);
@_ = split(/\/+/, $0);
$Program_Name = pop(@_);
$Version = '1.0';

###########################################################################
# Usage
#
#    We need it here to get config file
#       
my $Usage = <<ENDUSAGE;
Usage:
    $Program_Name -c configfile
    -c Configuration file
    -d go into debug mode (ie dont do anything)
ENDUSAGE

use vars qw/ $opt_c $opt_d/;
use Getopt::Std;
unless (getopts('dc:'))
{
    print $Usage;
    exit 1;
}
unless ($opt_c)
{
    print $Usage;
    exit 1;
}

###########################################################################
# Ok now read in user config variables. They go into package Settings
# just for saftey ;-)

my $configfile = $opt_c;
my $debug = 0;
$debug++ if $opt_d;
read_config_file($configfile) || die;
$debug++ if defined $Settings::state{'Debug'} && $Settings::state{'Debug'} > 0;

# for when we re-exec ourselves
$Settings::state{'ConfigFile'} = $configfile;
chomp($Settings::state{'StartTime'} = `date`);

forkit() unless $opt_d;

my $name = "rrd$$";

my $mbox = Spread::Message->new(
    spread_name => '4803@localhost',
    name  => $name,
    group => ['polling-rrd'],
    logto => ['nms-log'],
    debug => 0,
    member_sub  => \&process_control,
    message_sub => \&process_data,
    timeout_sub => \&heartbeat,
);
$mbox->connect || die "Can't connect to spread daemon";

while(1)
{
	$mbox->rx(20);
}

$mbox->disconnect();

exit;

sub heartbeat
{
    my $mbox = shift;

    # We don't see this but others do
    $mbox->logit("waited 20s for RRD data\n");
}

sub process_control
{
    my $mbox = shift;
}


sub process_data
{
    my $mbox = shift;
    my $loop = shift;

    return unless $mbox->new_msg;

    return unless grep(/^polling-rrd/,$mbox->grps);
	rrdupdate($mbox);
}

sub rrdupdate
{
    my($mbox) = shift;

	my $count = 0;
	my $tm = time;
	for my $line (split(/\n/,$mbox->msg) )
	{
		my($host,$tm,$state,$pl,$rta,$rtm) = split(/:/,$line);

		# my $rrdbase = $Settings::state{'rrddir'}."/$host";
		my $rrdbase = rrddir($host);
		rrdcreate($mbox,$host,$tm-1) unless -e "$rrdbase-state.rrd";
		return unless -e "$rrdbase-state.rrd";

		# First the Packet Loss, RTA stuff
		my $rrd = $rrdbase."-ping.rrd";
		RRDs::update ($rrd,"$tm:$tm:$pl:$rta:$rtm");
		my $ERR=RRDs::error;
		$mbox->logit("ERROR while updating $rrd: $ERR\n") if $ERR;

		# Now the state information
		$rrd = $rrdbase."-state.rrd";
		RRDs::update ($rrd,"$tm:$tm:$state");
		$ERR=RRDs::error;
		$mbox->logit("ERROR while updating $rrd: $ERR\n") if $ERR;
		$count += 2;
	}
	my $delay = time - $tm;
	my $txt = "Updated $count RRD files in $delay seconds\n";
	print $txt;
	$mbox->logit($txt);
}

# Compute a directory for holding RRDs
sub rrddir
{
	my $host = shift;

	my $pre = substr($host,0,1);
	return $Settings::state{'rrddir'}."/$pre/$host";
}

sub rrdcreate
{
    my $mbox = shift;
    my $host = shift;
    my $start = shift;

    #my $rrdbase = $Settings::state{'rrddir'}."/$host";
	my $rrdbase = rrddir($host);
	my $dir = $rrdbase;
	$dir =~ s%/[^/]+$%%;   # remove filename
	mkdir $dir unless -d $dir;

    # 25hrs @ 60s
    # 1month   @ 10min
    # 1 year @ 1hrs
    # About 583k per DB equals about 3G for 5000 devices
    # Note: STATE is special. A hack in rrdtool-1.0.33.tar.gz by yours
    # trully :-)
    my $rrd = $rrdbase."-ping.rrd";
    RRDs::create ($rrd, "--start", $start, "--step", 60,
                'DS:time:GUAGE:600:0:U',
                'DS:pl:GUAGE:600:0:U',
                'DS:arta:GUAGE:600:U:U',
                'DS:mrtt:GUAGE:600:U:U',
                'RRA:GUAGE:0.999:1:9000',
                'RRA:MAX:0.999:10:5040',   # Want MAX values in CF
                'RRA:MAX:0.999:60:9000',   # Want MAX values in CF
    );
    my $ERROR = RRDs::error;
    $mbox->logit("ERROR unable to create '$rrd': $ERROR\n") if $ERROR;

    $rrd = $rrdbase."-state.rrd";
    RRDs::create ($rrd, "--start", $start, "--step", 60,
                'DS:time:GUAGE:600:0:U',
                'DS:state:GUAGE:600:U:U',
                'RRA:STATE:0.999:1:9000',
                'RRA:STATE:0.999:10:5040', # Want last state in CF
                'RRA:STATE:0.999:60:9000', # Want last state in CF
    );
    $ERROR = RRDs::error;
    $mbox->logit("ERROR unable to create '$rrd': $ERROR\n") if $ERROR;

}



=head1 Copyright

Copyright 2003-2006, Mark Pfeiffer

This code may be copied only under the terms of the Artistic License
which may be found in the Perl 5 source kit.

Use 'perldoc perlartistic' to see the Artistic License.

Complete documentation for Perl, including FAQ lists, should be found on
this system using `man perl' or `perldoc perl'.  If you have access to the
Internet, point your browser at http://www.perl.org/, the Perl Home Page.

=cut


