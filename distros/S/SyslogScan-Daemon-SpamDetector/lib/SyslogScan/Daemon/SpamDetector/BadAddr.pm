
package SyslogScan::Daemon::SpamDetector::BadAddr;

use strict;
use warnings;
use Carp;
use Plugins;
use Plugins::SimpleConfig;
use SyslogScan::Daemon::SpamDetector::Plugin;
use Tie::Cache::LRU;
use Net::Netmask;

our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::Plugin);

our $ipcachesize = 10_000;

my %defaults = (
	debug		=> 0,
	configfile	=> '',
	ipcachesize	=> sub {
		my ($pkgself, $key, $value) = @_;
		if (ref($pkgself)) {
			$pkgself->{ipcachesize} = $value;
			if ($pkgself->{ipcache}) {
				my $t = tied(%{$pkgself->{ipcache}});
				$t->max_size($value);
			}
		} else {
			$ipcachesize = $value;
		}
	},
	ignoreip	=> '',
	every		=> 3,
);

sub config_prefix { 'badaddr_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{
	my $self = simple_new(\%defaults, @_); 
	$self->{ipcache} = {};
	die if ref($self->{ipcachesize});
	tie %{$self->{ipcache}}, 'Tie::Cache::LRU', $self->{ipcachesize} || $ipcachesize;
	return $self;
}

sub preconfig
{
	my ($self, $ssd_configfile) = @_;

	$self->set_api($ssd_configfile, 
		process_badaddr_match	=> {},
		is_ourip		=> { first_defined => 1},
	);
		
	$self->{ourip} = {};
	if ($self->{ignoreip} && -s $self->{ignoreip}) {
		open(IGNORE, "<$self->{ignoreip}") || die "open $self->{ignoreip}: $!";
		while(<IGNORE>) {
			next if /^#/;
			next if /^$/;
			chomp;
			my $block = Net::Netmask->new2($_);
			unless ($block) {
				warn "could not parse network block $_ in $self->{ignoreip} line $.: $Net::Netmask::error\n";
				next;
			}
			$block->storeNetblock($self->{ourip});
		}
		close(IGNORE);
	}
}

sub parse_logs
{
	my ($self, $logfile, $rx) = @_;

	for my $plugin (@{$self->{logs}{$logfile}{$rx}}) {
		my %info = $plugin->invoke('parse_logs', $logfile, $rx);
		next unless %info;
		$self->process_badaddr_match(%info);

	}
	return ();
}

sub process_badaddr_match
{
	my ($self, %info) = @_;

	if ($self->{myapi}->is_ourip($info{ip})) {
		return;
	}

	my $filter = $self->{plugins}->invoke_until('filter', 
		sub { defined($_[0]) }, 
		%info, 
		status => 'badaddr');

	if (defined $filter and ! $filter) {
		print "BA FILTERED: $info{status} $info{match}\n" if $self->{debug} > 2;
		return;
	}

	if ((++$self->{ipcache}{$info{ip}} % $self->{every}) == 0) {
		print "Reporting as spam $self->{ipcache}{$info{ip}} unknown users from $info{ip}\n" if $self->{debug};
		$self->{api}->process_spam_match(
			%info,
			status	=> 'spam',
			score	=> "$self->{ipcache}{$info{ip}} unknown users",
		);
		return;
	} 
	print "Not yet time to report $info{ip} for unknown users ($self->{ipcache}{$info{ip}})\n" if $self->{debug};
	return;
}

sub is_ourip
{
	my ($self, $ip) = @_;
	if (findNetblock($ip, $self->{ourip})) {
		return 1;
	}
	return undef;
}


sub periodic
{
	my ($self) = @_;
	$self->{plugins}->invoke('periodic');
}

package SyslogScan::Daemon::SpamDetector::BadAddr::Plugin;

use Plugins::Plugin;
use strict;
use warnings;

our @ISA = qw(SyslogScan::Daemon::SpamDetector::Plugin);

sub periodic {}
sub spam_found {}
sub ham_found {}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::BadAddr - notice mail sent to non-existant addressess

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::BadAddr as bad_
	debug		0
	every		3
	ipcachesize	10000
	ignoreip	/etc/postfix/ourip

=head1 DESCRIPTION

Watch the system log files for messages that are addressed to non-existant addresses.

This plugin requires mailer-specific plugins to help it.

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging on (1) or off (0).

=item every

This module is being used in the context of noticing spam.  We will consider 
every Nth such mis-addressed message to be a spam.  This parameter says 
what N is.  (Default: 3)

=item ipcachesize

Since we wait for N (default 3) bad addresses from a host before we count it
as a spam, we must cache the IP addresses and message counts.  This parameter
sets the cache size.  (Default 10,000).

=item ignoreip

This parameter provides a filename to look in for a list of IP addresses or
blocks that should be ignored.  (No default)

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

