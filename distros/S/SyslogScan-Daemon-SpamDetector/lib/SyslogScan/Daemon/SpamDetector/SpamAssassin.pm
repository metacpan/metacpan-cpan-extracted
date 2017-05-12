
package SyslogScan::Daemon::SpamDetector::SpamAssassin;

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

sub config_prefix { 'sdspamassassin_' }

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
#			Oct 24 06:53:43 eatspam1.idiom.com spamd[301]: spamd: result: Y 22 - DATE_IN_FUTURE_96_XX,DIGEST_MULTIPLE,DNS_FROM_RFC_ABUSE,DNS_FROM_RFC_POST,HELO_DYNAMIC_HOME_NL,PYZOR_CHECK,RAZOR2_CF_RANGE_51_100,RAZOR2_CF_RANGE_E8_51_100,RAZOR2_CHECK,RCVD_IN_NJABL_DUL,RCVD_IN_SORBS_DUL,URIBL_JP_SURBL,URIBL_SBL,URIBL_SC_SURBL scantime=5.7,size=1565,user=3djodel@mindsync.com,uid=103,required_score=5.0,rhost=internetmailservice.net,raddr=216.240.47.49,rport=55299,mid=<01c6f773$cf7e04c0$6c822ecf@delvynn>,autolearn=disabled  
#			Oct 24 06:53:38 outbound1.internet-mail-service.net spamd[410]: spamd: result: . 4 - MIME_BASE64_TEXT scantime=10.7,size=1085,user=ediekuik@mindsync.com,uid=110,required_score=5.0,rhost=internetmailservice.net,raddr=216.240.47.49,rport=56012,mid=<6B82E08B.734B402@yahoo.fr>,autolearn=disabled
			qr{^$Date \S+ spamd\[\d+\]: spamd: result: (\.|Y) ([\d\.]+) .*?mid=<(.*?)>},
		],
	);
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;
	my $debug = $self->{debug};
	my $logline = $_;
	my ($spammy, $score, $id) = ($1, $2, $3);
	return () if $self->{Extra} && ! /$self->{Extra}/;
	if ($spammy eq 'Y') {
		print "SPAMDETECT SPAM $id\n" if $self->{debug};
		return (
			status	=> 'spam',
			id	=> $id,
			logline	=> $_,
			match	=> 'SpamAssassin',
			score	=> $score,
		);
	} else {
		print "SPAMDETECT HAM $id\n" if $self->{debug};
		return (
			status	=> 'ham',
			id	=> $id,
			logline	=> $_,
			match	=> 'SpamAssassin',
			score	=> $score,
		);
	}
}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::SpamAssassin - notice messages deemed spam by SpamAsssassin

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::SpamAssassin
	debug 0
	logfile /var/log/mail.info

=head1 DESCRIPTION

Watch the system log files for output from spamd. 

Please note that legitimate mail servers send mail that will be 
caught by spamassassin.  The primary reason for this is forwarded
mail.  One way to work around this problem is to use the 
L<SyslogScan::Daemon::SpamDetector::Filter> module to only record
information from hosts with suspicious hostnames.

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

