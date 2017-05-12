
package SyslogScan::Daemon::BlacklistDetector::Postfix;

use strict;
use warnings;
use SyslogScan::Daemon::BlacklistDetector::Plugin;
use Plugins::SimpleConfig;
our(@ISA) = qw(SyslogScan::Daemon::BlacklistDetector::Plugin);

my %defaults = (
	rx_month	=> '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
	rx_date		=> '',
	rx_ourIP	=> '',
	logpath		=> '/var/log/mail.log',
	debug		=> 0,
);

sub config_prefix { 'bldpostfix_' }

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
	if ($self->{rx_ourIP}) {
		$self->{iprx} = qr/$self->{rx_ourIP}/;
	} else {
		require Sys::Hostname;
		import Sys::Hostname;
		my $host = hostname();
		my $iaddr = gethostbyname($host);
		my $addr = join('.', unpack('C4', $iaddr));
		$self->{iprx} = qr/\b\Q$addr\E\b/;
	}
}

sub get_logs
{
	my $self = shift;
	my $Date = $self->{Date};
	return (
		$self->{logpath}	=> [
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(bounced)(.*\b(?i:blacklist(ed)?|spamming|spam list|removal|remove|block list|blocked for abuse|Spam source|rejected (by .* )?for policy reasons)\b.*)},
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(deferred)(.*Rejected: \S+ listed at http.*)},
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(deferred)(.* blocked using .* Please see http.*)},
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(deferred)(.*421-:\s*postmaster.info.aol.com/errors.*)},
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(deferred)(.*server refused to talk to me: 550 Access denied\.\.\.[0-9a-f]{65}.*)},
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(deferred|bounced)(.*http://postmaster.info.aol.com/errors/.*)},
			qr{^$Date \S+ postfix(?:-(\S+))?/smtp\[\d+\]: \w+: to=<([^@]+@([^>]+))>, .*, status=(deferred)(.*\b(?i:greylisted)\b.*)},
		],
	);
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;
	my $debug = $self->{debug};
	my $logline = $_;
	my ($prefix, $to_address, $destdomain, $status, $error) = ($1, $2, $3, $4, $5);
	my $sourceip = ($logline =~ m/($self->{iprx})/)
		? $1
		: 'unknown';
	print STDERR "FROM $sourceip TO $destdomain $status: $error\n" if $debug;
	my %info = (
		prefix		=> $prefix,
		sourceip 	=> $sourceip,
		to_address	=> $to_address,
		logline		=> $logline,
		mobj		=> $self,
		destdomain	=> $destdomain,
		status		=> $status,
		logfile		=> $logfile,
		rx		=> $rx,
		error		=> $error,
	);
	return %info;
}

1;

=head1 NAME

 SyslogScan::Daemon::BlacklistDetector::Postfix - recognize the postfix mailer's bounce lines

=head1 SYNOPSIS

 bld_plugin SyslogScan::Daemon::BlacklistDetector::Postfix
	debug		1
	rx_ourIP	216\.240\.47\.\d+
	logpath		/var/log/mail.log

=head1 DESCRIPTION

SyslogScan::Daemon::BlacklistDetector::Postfix
knows where to find the postfix MTAs log files and how
to parse them for bounce information.

SyslogScan::Daemon::BlacklistDetector::Postfix is a plugin for
L<SyslogScan::Daemon::BlacklistDetector>.  
The SYNOPSIS shows the configuration
lines you might use in C</etc/syslogscand.conf> to turn on
the postfix parsing.

=head1 CONFIGURATION PARAMETERS

SyslogScan::Daemon::BlacklistDetector::Postfix defines the following configuration
parameters which may be given in indented lines that follow
C<plugin SyslogScan::Daemon::BlacklistDetector::Postfix> or with the
confuration prefix (C<blden_>) anywhere in the configuration file after the 
C<plugin SyslogScan::Daemon::BlacklistDetector::Postfix> line.

=over 15

=item debug

(default 0) Turn on debugging.

=item rx_ourIP

(no default, optional) A regular expression to match the part of the log line that
would represent the sending IP address. 

=item logpath

(default C</var/log/mail.log>)

=back

=head1 parse_logs() INFO

In addition to the required return elements, parse_logs() also returns:

=over 15

=item prefix

If postfix is logging itself as C<postfix-somthing> instead of C<postfix>, then
C<prefix> will be the C<something>.

=item rx

The regular expression that matched.

=item mobj

The SyslogScan::Daemon::BlacklistDetector::Postfix object.

=back

=head1 SEE ALSO

The context for the blacklist detector:
L<SyslogScan::Daemon::BlacklistDetector>

=head1 LICENSE

Copyright (C) 2006, David Muir Sharnoff <muir@idiom.com>

This module may be used and copied on the same terms as Perl
itself.

