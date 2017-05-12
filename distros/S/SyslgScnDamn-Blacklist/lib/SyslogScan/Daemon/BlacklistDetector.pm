
package SyslogScan::Daemon::BlacklistDetector;

use strict;
use warnings;
use Carp;
use Plugins;
use Plugins::SimpleConfig;
use SyslogScan::Daemon::Plugin;

our(@ISA) = qw(SyslogScan::Daemon::Plugin);
our $VERSION = 0.44;

#
# These are hard-coded rather than configured because they're universal and
# should be shared by all users of this code.
#
# These are 2nd-level matches that explain away bounces.  The first-level
# match is currently done in BlacklistDetector/Postfix.pm
#
my $recipient_reject_rx = qr{Blacklist for this recipient|Recipient address rejected|mailbox \S+ is blacklisted|Email address unknown|This user doesn't have a \S+ account|This email receives too much spam, please remove it from the To: |to=<(.*?)>.*554 blacklisted \(\1\)|550 <\S+> is not a valid mailbox|sorry, that domain isn't in my list of allowed rcpthosts|550 \S+ unknown user account};

my $realtime_reject_rx = qr{Spamming not allowed|Stop Spamming\.\s*You are being monitored!|Remove lines beginning with|The EMail\s+is Blacklisted};

my $content_reject_rx = qr{(?:\b|\d\d\d-|\s)(in the content|out of your message and resend|A URL in the email is Blacklisted|[bB]lacklisted URL in (?:message|mail)|Message contains blacklisted domain|contains links to an IP address that is blacklisted|because its checksum is in|message content unacceptable|Mail contained a URL rejected by|No user with this name is found at|URL MATCH|The EMail \S+\@\S+ is Blacklisted|http://postmaster.info.aol.com/errors/554hvub1.html|user account is.*?blacklisted|Matched regular expression|\S+\@\S+ address is blacklisted|No such user|this domain doesn't accept mail|Blacklisted file extension detected|This message matches a blacklisted|message was identified as junk mail, score|Message body contains|http:\/\/lookup\.uribl\.com/\?domain=|Blocked by p licy: blacklisted URL in mail|Message rejected - blacklisted URLs|For security reasons we do not accept messages containing images|URL in message blacklisted)\b};

my $sender_reject_rx = qr{(The From Address\s+blacklisted or blank|Sender address rejected|Sender is on our global blacklist|The EMail \(from\)\s+is Blacklisted|550 Sender verify failed)};

my %defaults = (
	debug		=> 0,
	configfile	=> '',
);

sub config_prefix { 'bld_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new { simple_new(\%defaults, @_); }

sub preconfig
{
	my ($self, $ssd_configfile) = @_;

	$self->set_api($ssd_configfile,
		process_match		=> { optional => 1 },
		greylisted		=> { optional => 1 },
		realtime_reject		=> { optional => 1 },
		recipient_reject	=> { optional => 1 },
		sender_reject		=> { optional => 1 },
		content_reject		=> { optional => 1 },
		blacklisted		=> { optional => 1 },
	);
}

sub matched_line
{
	my ($self, $logfile, $rx) = @_;

	for my $plugin (@{$self->{logs}{$logfile}{$rx}}) {
		my %info = $plugin->invoke('parse_logs', $logfile, $rx);
		next unless %info;
		$self->process_match(%info);
	}
}

sub process_match
{
	my ($self, %info) = @_;

	my $status = $info{status};
	my $logline = $info{logline};
	my $error = $info{error} || $info{logline};
	if ($self->{debug} > 5) {
		print "PROCESS_MATCH:\n";
		for my $k (sort keys %info) {
			print "\t$k=\t$info{$k}\n";
		}
		if ($self->{debug} > 7) {
			Carp::longmess("debugging...");
		}
	}

	if ($status eq 'deferred') {
		if ($error =~ /\bgreylisted\b/i) {
			print STDERR "Greylisted $logline\n" if $self->{debug};
			$self->greylisted(%info);
			return;
		}
	}

	if ($status eq 'bounced') {
		if ($error =~ /$recipient_reject_rx/) {
			print STDERR "Bad recipient rejection $logline\n" if $self->{debug};
			$self->recipient_reject(%info);
			return;
		}
		if ($error =~ /$sender_reject_rx/) {
			print STDERR "Bad sender rejection $logline\n" if $self->{debug};
			$self->sender_reject(%info);
			return;
		}
		if ($error =~ /$content_reject_rx/) {
			print STDERR "Bad content: $1 - $logline\n" if $self->{debug};
			$self->content_reject(%info);
			return;
		}
		if ($error =~ /$realtime_reject_rx/) {
			print STDERR "Realtime spam rejection $logline\n" if $self->{debug};
			$self->realtime_reject(%info);
			return;
		}
	}

	print STDERR "Blacklisted $logline\n" if $self->{debug};
	$self->blacklisted(%info);
}

package SyslogScan::Daemon::BlacklistDetector::Plugin;

use SyslogScan::Daemon::Plugin;
use strict;
use warnings;

our @ISA = qw(SyslogScan::Daemon::Plugin);

1;
