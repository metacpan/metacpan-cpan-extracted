
package SyslogScan::Daemon::SpamDetector::SpamSink;

use strict;
use warnings;
use SyslogScan::Daemon::SpamDetector::Plugin;
use Plugins::SimpleConfig;
our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::Plugin);

my %defaults = (
	rx_extra	=> '.',
	rx_month	=> '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
	rx_date		=> '',
	logfile		=> '/var/log/syslog',
	debug		=> 0,
);

sub config_prefix { 'sdspamsink_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new { simple_new(\%defaults, @_); }

our $Mon;
our $Date;
our $iprx;

sub preconfig
{
	my $self = shift;
	$self->{Mon} = qr/$self->{rx_month}/;
	$self->{Date} = $self->{rx_date} ? qr/$self->{rx_date}/ : qr/$self->{Mon} [ 1-3][0-9] \d\d:\d\d:\d\d/;
	$self->{Extra} = qr/$self->{rx_extra}/;
}

sub get_logs
{
	my $self = shift;
	my $Date = $self->{Date};
	return (
		$self->{logfile}	=> [
			# Oct 27 21:12:51 idiom spamsink: Message-ID: <000f01c6fa8a$2847c1e0$083fb0ec@office42c36499> 
			qr{^$Date (\S+) spamsink: Message-I[dD]: <(.*?)>},
		],
	);
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;
	my $debug = $self->{debug};
	my $logline = $_;
	my ($host, $id) = ($1, $2);
	print "SpamSink: $host $id\n" if $debug;
	return () if $self->{Extra} && ! /$self->{Extra}/;
	return (
		status	=> 'spam',
		id	=> $id,
		logline	=> $_,
		match	=> 'SpamSink',
		score	=> 'spamsink',
		hideid	=> 1,
		host	=> $host,
	);
}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::SpamSink - notice messages sent to a honeypot

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::SpamSink
	debug 0
	logfile /var/log/mail.info

=head1 DESCRIPTION

Watch the system log files for message sent to spam honeypots.

It looks for the following kind of message line:

 $Date \S+ spamsink: Message-I[dD]: <.*?>

Lines like this can be generate by forwarding mail to a program like:

 #!/bin/sh 
 perl -e '
        $x = <>; 
        while (<>) { 
                last if /^$/; 
                next unless /^(Message-I[dD]: .*)/; 
                $y = $1; 
        } 
        print "$y\n" 
                if      $x =~ /\@/ 
                        && $y =~ /\@/ 
                        && $x !~ /mailer-daemon/i 
                        && $x !~ /postmaster/ ; 
 ' | /usr/bin/logger -p mail.info -t spamsink

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging on (1) or off (0).

=item logfile

Which logfile to watch (default: C</var/log/syslog>).

=back

=head1 SEE ALSO

L<SyslogScan::Daemon::SpamDetector>

=head1 THANK THE AUTHOR

If you need high-speed internet services (T1, T3, OC3 etc), please 
send me your request-for-quote.  I have access to very good pricing:
you'll save money and get a great service.

=head1 LICENSE

Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

