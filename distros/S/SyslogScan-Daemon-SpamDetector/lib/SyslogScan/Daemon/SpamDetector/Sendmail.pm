
package SyslogScan::Daemon::SpamDetector::Sendmail;

use strict;
use warnings;
use SyslogScan::Daemon::SpamDetector::Plugin;
use Plugins::SimpleConfig;
our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::Plugin);

my %defaults = (
	rx_extra	=> '.',
	rx_month	=> '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
	rx_date		=> '',
	logfile		=> '/var/log/mail.log',
	debug		=> 0,
);

sub config_prefix { 'sdsendmail_' }

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
#			Oct 20 00:00:12 idiom sm-mta[16655]: k9K6xf1f016655: from=<declarator@embrace.org.uk>, size=771, class=0, nrcpts=1, msgid=<46600514770495.39A8A178A2@SLDS5JHS>, proto=ESMTP, daemon=Daemon0, relay=pool-151-205-120-16.ny325.east.verizon.net [151.205.120.16]
			qr{^$Date (\S+) sm-mta\[\d+\]: \w+: from=<(.*?)>, size=\d+, class=\d+, nrcpts=\d+, msgid=<(.*?)>, proto=\S+, daemon=\S+, relay=(?:(\S+) )?\[([\d\.]{8,40})\]},

		],
	);
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;
	my $debug = $self->{debug};
	my $logline = $_;
	my ($host, $from, $id, $relayname, $relayip) = ($1, $2, $3, $4, $5);
	return () if $self->{Extra} && ! /$self->{Extra}/;
	print "SPAMDETECT $id => $relayip\n" if $self->{debug};
	my %info = (
		id		=> $id,
		ip		=> $relayip,
		from		=> $from,
		relayname	=> $relayname,
		status		=> 'idmap',
		match		=> 'Sendmail',
		host		=> $host,
	);
	return %info;
}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::Sendmail - record incomming messages

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::Sendmail
	debug		0
	logfile		/var/log/mail.info
	rx_extra	'ingore_lines_without_this_string'

=head1 DESCRIPTION

SyslogScan::Daemon::SpamDetector::Sendmail watches the mail log file and
notices which Message-IDs came from which IP address.

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging on (1) or off (0).

=item logfile

Which logfile to watch (default: C</var/log/mail.log>).

=item rx_extra

Ignore log lines that don't match a regular expression.  

=back

=head1 SEE ALSO

L<SyslogScan::Daemon::SpamDetector>
L<SyslogScan::Daemon::SpamDetector::Sendmail>

=head1 THANK THE AUTHOR

If you need high-speed internet services (T1, T3, OC3 etc), please 
send me your request-for-quote.  I have access to very good pricing:
you'll save money and get a great service.

=head1 LICENSE

Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

