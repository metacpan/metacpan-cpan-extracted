# Copyright (C) 2006, David Muir Sharnoff

package SyslogScan::Daemon::SpamDetector;

use strict;
use warnings;
use Carp;
use Plugins;
use Plugins::SimpleConfig;
use SyslogScan::Daemon::Plugin;
use Tie::Cache::LRU;
use Net::Netmask;

our $VERSION = 0.56;

our(@ISA) = qw(SyslogScan::Daemon::Plugin);

our $idcachesize = 10_000;

my %defaults = (
	debug		=> 0,
	configfile	=> '',
	idcachesize	=> sub {
		my ($pkgself, $key, $value) = @_;
		if (ref($pkgself)) {
			$pkgself->{idcachesize} = $value;
			if ($pkgself->{idcache}) {
				my $t = tied(%{$pkgself->{idcache}});
				$t->max_size($value);
			}
		} else {
			$idcachesize = $value;
		}
	},
	spam_command	=> 'echo found spam from $ip',
	ham_command	=> 'echo found ham from $ip',
	ignoreip	=> '',
);

sub config_prefix { 'sd_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{
	my $self = simple_new(\%defaults, @_); 
	$self->{idcache} = {};
	die if ref($self->{idcachesize});
	tie %{$self->{idcache}}, 'Tie::Cache::LRU', $self->{idcachesize} || $idcachesize;
	return $self;
}

sub preconfig
{
	my ($self, $ssd_configfile) = @_;

	$self->set_api($ssd_configfile,
		process_spam_match	=> {},
		is_ourip		=> { first_defined => 1 },
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

sub matched_line
{
	my ($self, $logfile, $rx) = @_;

	for my $plugin (@{$self->{logs}{$logfile}{$rx}}) {
		my %info = $plugin->invoke('parse_logs', $logfile, $rx);
		next unless %info;
		$self->process_spam_match(%info);
	}
}

sub process_spam_match
{
	my ($self, %info) = @_;
	my $status = $info{status};

	if (my $c = $self->{idcache}{$info{id}}) {
		for my $k (keys %$c) {
			$info{$k} = $c->{$k} unless exists $info{$k};
		}
	}
	my $ip = $info{ip};

	my $filter = $self->{plugins}->invoke_until('filter', sub { defined($_[0]) }, %info);
	if (defined $filter and ! $filter) {
		print "FILTERED: $info{status} $info{match}\n" if $self->{debug} > 2;
		return;
	}

	if (! $ip) {
		print "SPAMDETECTOR: ignoring $status for <$info{id}> ... no ip mapping\n" if $self->{debug};
	} elsif ($self->{myapi}->is_ourip($ip)) {
		print "SPAMDETECTOR: ignoring $status for <$info{id}> ... ip is internal\n" if $self->{debug};
	} elsif ($status eq 'spam') {
		$self->spam_found(%info, ip => $ip);
		print "SPAMDETECTOR: SPAM FROM $ip SCORE=$info{score}\n" if $self->{debug};
		if ($self->{spam_command} && $ip) {
			system(substitute($self->{spam_command}, %info, ip => $ip));
		}
	} elsif ($status eq 'ham') {
		$self->ham_found(%info, ip => $ip);
		print "SPAMDETECTOR: HAM FROM $ip SCORE=$info{score}\n" if $self->{debug};
		if ($self->{ham_command} && $ip) {
			system(substitute($self->{ham_command}, %info, ip => $ip));
		}
	} elsif ($status eq 'idmap') {
		print "SPAMDETECTOR: IDMAP $info{match} $info{id} => $ip to $info{host}\n" if $self->{debug} >= 2;
		$self->{idcache}{$info{id}} = \%info;
	} else {
		die;
	}
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

sub substitute
{
	my ($string, %info) = @_;
	for my $i (keys %info) {
		$string =~ s/\$$i\b/$info{$i}/g;
	}
	return $string;
}

package SyslogScan::Daemon::SpamDetector::Plugin;

use strict;
use warnings;

our @ISA = qw(SyslogScan::Daemon::Plugin);

sub parse_logs {}
sub spam_found {}
sub ham_found {}
sub filter { return undef };

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector - Notice spammers in the log files

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_
	debug		0
	ignoreip	/etc/postfix/ourip

=head1 DESCRIPTION

SyslogScan::Daemon::SpamDetector is a plugin for L<SyslogScan::Daemon> 
that watches log files for indications of Spam.  

To do it's job it uses additional plugins.

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging on (1) or off (0).

=item configfile

Usually defaulted to the config file for SyslogScan::Daemon.

=item idcachesize

How big should the message id cache be?  This is used by some of the
plugins to match up what happens to a message.  For example, we need
to remember the IP address of that a message came from
(L<SyslogScan::Daemon::SpamDetector::Sendmail> or L<SyslogScan::Daemon::SpamDetector::Postfix>)
and then later decide if it's spam (L<SyslogScan::Daemon::SpamDetector::SpamAssassin>).
Default is 10,000.

=item spam_command

A shell command to run when spam is found.
In the command, C<$ip> will be substituted for the
IP address the message came from.  All of the other
keys to the C<%info> array (documented blow) are 
also available as substitutions.

=item ham_command

A shell command to run when a non-spam message is found.

=item ignoreip

A filename that contains a list of IP blocks (one per line)
that should be ignored.  The blocks are in the format 
A.B.C.D/bits

=back

=head1 WRITING PLUGINS

Plugins for SyslogScan::Daemon::SpamDetector will either
help recognize spam or do something with recognized spam.

Either way, they create or use an <%info> hash that describes
an event:

=over 4

=item status

What is being reported?   Values are:

=over 7

=item spam

A spammy message has been found.

=item ham

A non-spam message has been found.  

=item idmap

A message has come in, establish a mapping from
the C<id> to the C<ip>.

=back

=item id

The message id.  Usually required.

=item ip

The IP address.  This is required unless an C<idmap>
established an C<id> -E<gt> C<ip> mapping previously
in which case an C<id> may be used instead.

=item score

The spam score from SpamAssassin.  If not reporting
SpamAssassin, make something else up.

=item match

What kind of match was made.   Example values are: C<spamassassin>,
C<spamsink>, C<badaddrs>, etc.

=item host

Hostname of the system receiving the message.

=item hideid

If you report message ids to outsiders (like, for example if you're using
this information to block mail) then don't report the message id I<this time>
because it is sensitive information.  Optional.

=back

SyslogScan::Daemon::SpamDetector invokes the following methods on
it's plugins:

=over 4

=item @logs = get_logs()

Inherited from L<SyslogScan::Daemon>.

=item %info = parse_logs($logfile, $regex_matched)

When this is called, C<$_> will be set to the logfile line
that matched.  Please leave C<$_> alone so that other plugins
that matched the same line can also use it.

Return C<()> if not providing an C<%info>.

=item preconfig($configfile)

Inherited from L<SyslogScan::Daemon>.

=item periodic()

Inherited from L<SyslogScan::Daemon>.

=item spam_found(%info)

Called when spam is found.   Called though L<Plugins::API>.

=item ham_found(%info)

Called when non-spam is found.   Called though L<Plugins::API>.

=back

SyslogScan::Daemon::SpamDetector provides some L<Plugins::API>
callbacks:

=over 4

=item process_spam_match(%info)

Calling this is the same as returning C<%info> from C<parse_logs()>.

=item is_ourip($ip_address)

Is this one of our own IP addresses and thus should be ignored?
A return of C<undef> doesn't answer but a return of C<0> says that
the item is I<not> our IP address.

=back

=head1 SEE ALSO

The context for this: 
L<SyslogScan::Daemon>, 
L<Plugins>, 
L<Plugins::API>, 
L<Daemon::Generic>.

Plugins for this module:
L<SyslogScan::Daemon::SpamDetector::BlockList>.
L<SyslogScan::Daemon::SpamDetector::Sendmail>,
L<SyslogScan::Daemon::SpamDetector::Postfix>,
L<SyslogScan::Daemon::SpamDetector::SpamSink>,
L<SyslogScan::Daemon::SpamDetector::SpamAssassin>.
L<SyslogScan::Daemon::SpamDetector::Bogofilter>.
L<SyslogScan::Daemon::SpamDetector::BadAddr>.

=head1 THANK THE AUTHOR

If you need high-speed internet services (T1, T3, OC3 etc), please 
send me your request-for-quote.  I have access to very good pricing:
you'll save money and get a great service.

=head1 LICENSE

Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

