
package SyslogScan::Daemon::SpamDetector::BadAddr::Sendmail;

use strict;
use warnings;
use SyslogScan::Daemon::SpamDetector::BadAddr::Plugin;
use Plugins::SimpleConfig;
use Tie::Cache::LRU;
our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::BadAddr::Plugin);

our $msgcachesize = 3_000;

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
);

sub config_prefix { 'badsendmail_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{
	my $self = simple_new(\%defaults, @_); 
	$self->{msgcache} = {};
	die if ref($self->{msgcachesize});
	tie %{$self->{msgcache}}, 'Tie::Cache::LRU', $self->{msgcachesize} || $msgcachesize;
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
#1st			Oct 31 09:44:04 idiom sm-mta[48031]: k9VHi04a048031: <reineant@design-universe.com>... User unknown
#2nd			Oct 20 00:00:12 idiom sm-mta[16655]: k9K6xf1f016655: from=<declarator@embrace.org.uk>, size=771, class=0, nrcpts=1, msgid=<46600514770495.39A8A178A2@SLDS5JHS>, proto=ESMTP, daemon=Daemon0, relay=pool-151-205-120-16.ny325.east.verizon.net [151.205.120.16]
			qr{^$Date (\S+) sm-mta\[\d+\]: (\w+): from=<(.*?)>, size=\d+, class=\d+, nrcpts=\d+, (msgid)=<(.*?)>, proto=\S+, daemon=\S+, relay=(\S+) \[([\d\.]{8,40})\]},
			qr{^$Date (\S+) sm-mta\[\d+\]: (\w+): <(\S+?)>\.\.\. User (unknown)},
		],
	);
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;
	my $debug = $self->{debug};
	my $logline = $_;
	my ($host, $qid, $fromto, $what, $id, $relayname, $relayip) = ($1, $2, $3, $4, $5, $6, $7);

	print "Matched $logline\n" if $debug >= 3;
	my $queueid = "$host/$qid";
	if ($self->{Extra} && ! /$self->{Extra}/) {
		# ignore
	} elsif ($what eq 'unknown') {
		push(@{$self->{msgcache}{$queueid}}, $fromto);
		print "Unknown user: $queueid: $fromto\n" if $debug >= 2;
	} elsif ($what eq 'msgid') {
		for my $to (@{$self->{msgcache}{$queueid}}) {
			print "Will report $queueid: $fromto -> $to from $relayip\n" if $debug;
			$self->process_badaddr_match(
				id		=> $id,
				ip		=> $relayip,
				from		=> $fromto,
				relayname	=> $relayname,
				match		=> 'BadAddr::Sendmail',
				to		=> $to,
				host		=> $host,
			);
		}
		delete $self->{msgcache}{$queueid};
	} else {
		warn "This should not happen";
	}
	return;
}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::BadAddr::Sendmail - notice bad email addresses in sendmail log files

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::BadAddr as bad_

 bad_plugin SyslogScan::Daemon::SpamDetector::BadAddr::Sendmail
	debug		1
	logfile		/var/log/mail.info
	msgcachesize	3000

=head1 DESCRIPTION

Read Sendmail logs and notice attempts to send to addresses that don't exist.

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

=back

=head1 SEE ALSO

L<SyslogScan::Daemon::SpamDetector>
L<SyslogScan::Daemon::SpamDetector::BadAddr>
L<SyslogScan::Daemon::SpamDetector::BadAddr::Postfix>

=head1 THANK THE AUTHOR

If you need high-speed internet services (T1, T3, OC3 etc), please 
send me your request-for-quote.  I have access to very good pricing:
you'll save money and get a great service.

=head1 LICENSE

Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

