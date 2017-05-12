
package SyslogScan::Daemon::SpamDetector::BadAddr::Postfix;

use strict;
use warnings;
use SyslogScan::Daemon::SpamDetector::BadAddr::Plugin;
use Plugins::SimpleConfig;
use Tie::Cache::LRU;
our $msgcachesize = 3_000;
our $badnscachesize = 1_000;
our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::BadAddr::Plugin);

my %defaults = (
	rx_extra	=> '.',
	rx_month	=> '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
	rx_date		=> '',
	logfile		=> '/var/log/mail.log',
	debug		=> 0,
	msgcachesize	=> sub {
		my ($pkgself, $key, $value) = @_;
		if (ref($pkgself)) {
			$pkgself->{msgcachesize} = $value;
			if ($pkgself->{msgcache}) {
				my $t = tied(%{$pkgself->{msgcache}});
				$t->max_size($value);
			}
		} else {
			$msgcachesize = $value;
		}
	},
	badnscachesize	=> sub {
		my ($pkgself, $key, $value) = @_;
		if (ref($pkgself)) {
			$pkgself->{badnscachesize} = $value;
			if ($pkgself->{badnscache}) {
				my $t = tied(%{$pkgself->{badnscache}});
				$t->max_size($value);
			}
		} else {
			$badnscachesize = $value;
		}
	},
);

sub config_prefix { 'badpostfix_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{
	my $self = simple_new(\%defaults, @_); 
	$self->{msgcache} = {};
	die if ref($self->{msgcachesize});
	tie %{$self->{msgcache}}, 'Tie::Cache::LRU', $self->{msgcachesize} || $msgcachesize;
	$self->{badnscache} = {};
	die if ref($self->{badnscachesize});
	tie %{$self->{badnscache}}, 'Tie::Cache::LRU', $self->{badnscachesize} || $badnscachesize;
	return $self;
}

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
#			Oct 31 05:02:11 ravel postfix/smtpd[89130]: 14CF41DBEFB: client=customer.optindirectmail.74.sls-hosting.com[204.14.1.74]
			$self->rx_invoke(qr{^$Date (\S+) postfix\S*/smtpd\[\d+\]: ([A-Z0-9]{9,15}): client=(\S*)\[([\d\.]{8,20})\]}, sub {
				my ($self, $logfile, $rx) = @_;
				my ($host, $msg, $name, $ip) = ($1, $2, $3);
				my $qid = "$host/$msg";
				print "badaddr postfix $qid is from $ip\n" if $self->{debug} >= 2;
				$self->{msgcache}{$qid} = {
					ip		=> $ip,
					relayname	=> $name,
				};
				return ();
			}),
#			Oct 31 05:02:11 ravel postfix/cleanup[78647]: 14CF41DBEFB: message-id=<5889984462.20061031070153@baraskaka.com>
			$self->rx_invoke(qr{^$Date (\S+) postfix\S*/cleanup\[\d+\]: ([A-Z0-9]{9,15}): message-id=<(.*?)>}, sub {
				my ($self, $logfile, $rx) = @_;
				my ($host, $msg, $id) = ($1, $2, $3);
				my $qid = "$host/$msg";
				print "badaddr postfix $qid msgid is $id\n" if $self->{debug} >= 2;
				$self->{msgcache}{$qid}{id} = $id;
				return ();
			}),
#			Oct 31 05:02:11 ravel postfix/qmgr[84199]: 14CF41DBEFB: from=<shannon@baraskaka.com>, size=18688, nrcpt=1 (queue active)
			$self->rx_invoke(qr{^$Date (\S+) postfix\S*/\S+\[\d+\]: ([A-Z0-9]{9,15}): from=<(\S+?)>,}, sub {
				my ($self, $logfile, $rx) = @_;
				my ($host, $msg, $from) = ($1, $2, $3);
				my $qid = "$host/$msg";
				print "badaddr postfix $qid message from $from\n" if $self->{debug} >= 2;
				$self->{msgcache}{$qid}{from} = $from;
				return ();
			}),
#			Oct 31 05:02:11 ravel postfix/local[87055]: 14CF41DBEFB: to=<nosuchuser@n2.net>, orig_to=<lakas@n2.net>, relay=local, delay=1, status=bounced (unknown user: "nosuchuser")
			$self->rx_invoke(qr{^$Date (\S+) postfix\S*/\S+\[\d+\]: ([A-Z0-9]{9,15}): to=<\S+?>, orig_to=<(\S+?)>, .*?status=bounced \(unknown user: ".*?"\)}, sub {
				my ($self, $logfile, $rx) = @_;
				my ($host, $msg, $to) = ($1, $2, $3);
				my $qid = "$host/$msg";
				my $ip = $self->{msgcache}{$qid}{ip};
				if ($ip) {
					print "Postfix badaddr $to\n" if $self->{debug};
					return (
						%{$self->{msgcache}{$qid}},
						to	=> $to,
						host	=> $host,
						match	=> 'BadAddr::Postfix',
						DNSbad	=> $self->{badnscache}{$ip} || 0,
					);
				} else {
					print "No IP mapping for postfix bad addr $to\n" if $self->{debug};
					return ();
				}
			}),
# Or
#
#			Oct 31 06:27:43 internetmailservice postfix/smtpd[21369]: NOQUEUE: reject: RCPT from 189.Red-81-37-230.dynamicIP.rima-tde.net[81.37.230.189]: 550 <tonna@mindsync.com>: Recipient address rejected: User unknown in virtual mailbox table; from=<romellor@aol.com> to=<tonna@mindsync.com> proto=SMTP helo=<mail.mindsync.com>
			$self->rx_invoke(qr{^$Date (\S+) postfix\S*/smtpd\[\d+\]: NOQUEUE: reject: RCPT from \S+?\[([\d\.]+)\]: 550 <(\S+)>: Recipient address rejected: User unknown in virtual mailbox table}, sub {
				my ($self, $logfile, $rx) = @_;
				my ($host, $ip, $to) = ($1, $2, $3);
				print "Postfix NOQUEUE reject to $to from $ip\n" if $self->{debug};
				return (
					host	=> $host,
					ip	=> $ip,
					to	=> $to,
					DNSbad	=> $self->{badnscache}{$ip} || 0,
					match => 'BadAddr::Postfix(NOQUEUE)',
				);
			}),
#			Jan 24 14:47:56 eatspam2 postfix/smtpd[3425]: warning: 88.226.249.119: hostname dsl88-226-63863.ttnet.net.tr verification failed: Name or service not known 
			$self->rx_invoke(qr{^$Date (\S+) postfix\S*/smtpd\[\d+\]: warning: (\S+): hostname \S+ verification failed:}, sub {
				my ($self, $logfile, $rx) = @_;
				my ($host, $ip) = ($1, $2);
				$self->{badnscache}{$ip} = 1;
				return ();
			}),
		],
	);
}

sub rx_invoke
{
	my ($self, $rx, $code) = @_;
	$self->{rxmap}{$rx} = $code;
	return $rx;
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;
	my $code = $self->{rxmap}{$rx} || do { warn "map missing for $rx"; return() };
	&$code($self, $logfile, $rx);
}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::BadAddr::Postfix - notice bad email addresses in postfix log files

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::BadAddr as bad_

 bad_plugin SyslogScan::Daemon::SpamDetector::BadAddr::Postfix
	debug		1
	logfile		/var/log/mail.info
	msgcachesize	3000
	badnscachesize	1000

=head1 DESCRIPTION

Read Postfix logs and notice attempts to send to addresses that don't exist.

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging on (1) or off (0).

=item logfile

Which logfile to watch (default: C</var/log/mail.log>).

=item msgcachesize

To do this mapping, multiple log lines must be matched.  Partial
matches will be stored in a cache.  This parameter sets the
size of the cache (default: 3000).

=item badnscachesize

To keep track of which clients don't have correct DNS entries,
a cache is kept.  This configuration item sets the size of the
cache (default: 1000).

=back

=head1 SEE ALSO

L<SyslogScan::Daemon::SpamDetector>
L<SyslogScan::Daemon::SpamDetector::BadAddr>

=head1 THANK THE AUTHOR

If you need high-speed internet services (T1, T3, OC3 etc), please 
send me your request-for-quote.  I have access to very good pricing:
you'll save money and get a great service.

=head1 LICENSE

Copyright(C) 2006,2007 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

