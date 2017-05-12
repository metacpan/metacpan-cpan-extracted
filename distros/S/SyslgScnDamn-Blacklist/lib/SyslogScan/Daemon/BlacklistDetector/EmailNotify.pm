
package SyslogScan::Daemon::BlacklistDetector::EmailNotify;

use strict;
use warnings;
use SyslogScan::Daemon::BlacklistDetector::Plugin;
use Mail::SendVarious;
use Plugins::SimpleConfig;

our(@ISA) = qw(SyslogScan::Daemon::BlacklistDetector::Plugin);

my %defaults = (
	notify		=> 'root',
	renotify_time	=> 7200,
	forget_time	=> 3600,
	maxkeep		=> 100,
	sendfrom	=> 'root',
	clean_time	=> 1800,
	debug		=> 0,
);

sub config_prefix { return 'blden_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{ 	
	my $self = simple_new(\%defaults, @_); 
	$self->{last_clean} = 0;
	return $self;
}

my %notified;
my %found;

sub blacklisted
{
	my ($self, %info) = @_;

	my $sourceip	= $info{sourceip};
	my $destdomain	= $info{destdomain};

	my $renotify_time	= $self->{renotify_time};
	my $debug		= $self->{debug};
	my $notify		= $self->{notify};
	my $sendfrom		= $self->{sendfrom};

	push(@{$found{$sourceip}{$destdomain}}, {
		time	=> time(),
		source	=> $sourceip,
		dest	=> $destdomain,
		line	=> $info{logline},
	});

	if ($notified{$sourceip}{$destdomain} 
		&& (time - $notified{$sourceip}{$destdomain} < $renotify_time)) 
	{
		print STDERR "Not yet time to re-notify\n" if $debug;
		return;
	}

	$self->clean_found();

	my $body = '';

	$notified{$sourceip}{$destdomain} = time;
	$body .= "----------------- $sourceip to $destdomain -------------------\n";
	while (my $br = pop(@{$found{$sourceip}{$destdomain}})) {
		$body .= $br->{line};
	}
	delete $found{$sourceip}{$destdomain};
	delete $found{$sourceip} unless %{$found{$sourceip}};
	for my $source (keys %found) {
		for my $dest (keys %{$found{$source}}) {
			$notified{$source}{$dest} = time;
			$body .= "\n\n----------------- $source to $dest -------------------\n";
			while (my $br2 = pop(@{$found{$source}{$dest}})) {
				$body .= $br2->{line};
			}
		}
	}

	print STDERR "Sending notification to $notify: $destdomain\n$body\n" if $debug >= 2;
	sendmail(
		From	=> "\u$0",
		from	=> $sendfrom,
		to	=> $notify,
		subject	=> "We are blackholed by $destdomain\n",
		body	=> $body,
	);
}

sub clean_found
{
	my $self = shift;
	my $forget_time		= $self->{forget_time};
	my $debug		= $self->{debug};

	for my $source (keys %found) {
		for my $dest (keys %{$found{$source}}) {
			pop(@{$found{$source}{$dest}}) while 
				@{$found{$source}{$dest}}
				&& 
				(
					(time - $found{$source}{$dest}[0]{time} >= $forget_time)
					|| 
					@{$found{$source}{$dest}} > $self->{maxkeep}
				);
			delete $found{$source}{$dest}
				unless @{$found{$source}{$dest}};
		}
		delete $found{$source}
			unless %{$found{$source}};
	}
}

my $last_clean = 0;

sub periodic
{
	my $self = shift;
	my $debug = $self->{debug};
	if ($self->{last_clean} + $self->{clean_time} < time) {
		printf "%s periodic running\n", __PACKAGE__ if $debug;
		$self->clean_found();
		$self->{last_clean} = time;
	}
}

1;

=head1 NAME

 SyslogScan::Daemon::BlacklistDetector::EmailNotify - send email when blacklisted

=head1 SYNOPSIS

 bld_plugin SyslogScan::Daemon::BlacklistDetector::EmailNotify
	debug		0
	notify		your@email.here
	renotify_time	7200
	forget_time	3600
	sendfrom	root
	clean_time	1800
	maxkeep		100

=head1 DESCRIPTION

SyslogScan::Daemon::BlacklistDetector::EmailNotify 
sends email when SyslogScan::Daemon::BlacklistDetector
detects blacklisting.

SyslogScan::Daemon::BlacklistDetector is a plugin for
L<SyslogScan::Daemon::BlacklistDetector>.  
The SYNOPSIS shows the configuration
lines you might use in C</etc/syslogscand.conf> to turn on
the email notification.

=head1 CONFIGURATION PARAMETERS

SyslogScan::Daemon::BlacklistDetector::EmailNotify defines the following configuration
parameters which may be given in indented lines that follow
C<plugin SyslogScan::Daemon::BlacklistDetector::EmailNotify> or with the
confuration prefix (C<blden_>) anywhere in the configuration file after the 
C<plugin SyslogScan::Daemon::BlacklistDetector::EmailNotify> line.

=over 15

=item debug

(default 0) Turn on debugging.

=item notify

(default C<root>) Where should the notifications be sent?

=item sendfrom

(default C<root>) What email address should notifications be 
sent from?

=item renotify_time

(default 7200) Seconds.  How often should an additional email
be sent regarding the same destination.  Before the time is up,
extra notifications will be queued.

=item forget_time

(default 3600) Seconds.  How long should unsent notifications
be kept. 

=item maxkeep

(default 100) How many unsent notifcations can be queued regarding
the same destination?

=item clean_time

(default 1800) Seconds.  How often should the unsent notication 
queue be cleaned of extra entries?

=back

=head1 SEE ALSO

The context for the blacklist detector:
L<SyslogScan::Daemon::BlacklistDetector>

=head1 LICENSE

Copyright (C) 2006, David Muir Sharnoff <muir@idiom.com>

This module may be used and copied on the same terms as Perl
itself.

