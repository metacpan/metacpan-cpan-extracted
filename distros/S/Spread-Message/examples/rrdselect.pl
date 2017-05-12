#!/usr/bin/perl -w

=head1 NAME

rrdselect.pl - select data from RRDs

=head1 SYNOPSIS

rrdselect.pl -c config

=head1 DESCRIPTION

Do a selection over a set of RRD's and send the results back over spread.

It is an example OK!

=head1 SEE ALSO
        
Spread
 
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

my $name = $Settings::state{'Name'} || "rrdsel$$";
my $spread = $Settings::state{'Spread'} || '4803@localhost';

my $mbox = Spread::Message->new(
    spread_name => $spread,
    name  => $name,
    group => ['selecting-rrd'],
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
    $mbox->logit("waiting for RRD select command\n");
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

    return unless grep(/^selecting-rrd/,$mbox->grps);
	rrdselect($mbox);
}

sub rrdselect
{
    my($mbox) = shift;
	my $sender = $mbox->sender;

	for my $line (split(/\n/,$mbox->msg) )
	{
		my $tm = time;

		# host:ping:MAX: -s -5443200
		my($host,$typ,@args) = split(/:/,$line);
		$host = uc($host);

		my $rrdbase = rrddir($host);
		my $rrd = "$rrdbase-$typ.rrd";
		unless( -e $rrd)
		{
			$mbox->send($sender,"ERROR: $host doesn't have an RRD($rrd)\n");
			$mbox->logit("ERROR: $host doesn't have an RRD($rrd)\n");
			next;
		}

		 my ($start,$step,$names,$data) = RRDs::fetch($rrd,@args);
		 my $error = '';
		 if( $error = RRDs::error)
		 {
		 	my $txt = "Select on $host of $line failed: $error\n";
			$mbox->logit($txt);
			warn $txt;
			$mbox->send($sender,$txt);
			next;
		 }

		 $mbox->logit("Start      : ", scalar localtime($start), " ($start)\n");
		 $mbox->logit("Step size  : $step seconds\n");
		 my $header = join (" ", @$names);
		 $mbox->logit("DS names   : $header\n");
		 $mbox->logit("Data points: ", $#$data + 1, "\n");
		 my $d = "$line\n$header\n";
		 foreach my $l (@$data)
		 {
		 	$d .= "$start:";
			$start += $step;
			foreach my $val (@$l)
			{
				if($val)
				{
					#$d .= sprintf '%f ', $val;
					$d .= " $val";
				}
				else
				{
					$d .= " nan";
				}
			}
			$d .= "\n";
		 }
		 $mbox->sends($sender,$d);
		 my $delay = time - $tm;
		 $mbox->logit("Select time: $delay sec\n");
	}
}

# Compute a directory for holding RRDs
sub rrddir
{
	my $host = shift;

	my $pre = substr($host,0,1);
	return $Settings::state{'rrddir'}."/$pre/$host";
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


