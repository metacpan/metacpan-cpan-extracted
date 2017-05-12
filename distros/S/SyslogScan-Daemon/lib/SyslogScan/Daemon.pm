# Copyright (C) 2006, David Muir Sharnoff <muir@idiom.com>

package SyslogScan::Daemon;

use strict;
use warnings;
use Daemon::Generic::Event;
use Plugins::Style1;
use Plugins::SimpleConfig;
use Plugins::API;
use FileHandle;
use Carp;
require Exporter;
our @ISA = qw(Daemon::Generic::Event);
our @EXPORT = qw(newdaemon);

our $VERSION = 0.41;

our $sighup = 0;
our $sigint = 0;

my %loghandles;
our $sleep_time = 1;
our $debug = 0;

my %config_items = (
	logpriority	=> '',
	sleeptime	=> \$sleep_time,
	debug		=> \$debug,
);

sub config_prefix { return '' };

sub parse_config_line { simple_config_line(\%config_items, @_); }

sub new { simple_new(\%config_items, @_); }

sub gd_preconfig
{
	my $self = shift;
	print "START  ssd preconfig\n" if $debug;

	$self->{api} = new Plugins::API { autoregister => $self },
		log_rolled	=> { optional => 1 },
		;

	delete $self->{plugins};
	$self->{plugins} = Plugins::Style1->new(api => $self->{api});
	$self->{plugins}->readconfig($self->{configfile}, self => $self);
	$self->{plugins}->initialize();
	$self->{plugins}->invoke('preconfig', $self->{configfile});

	print "END  ssd preconfig\n" if $debug;
	return ();
}

my %logs;
my %merged;
sub gd_postconfig
{
	my ($self) = @_;
	print "START  ssd postconfig\n" if $debug;
	closelogfiles();
	%logs = ();
	$self->{plugins}->invoke('postconfig');

	for my $plugin ($self->{plugins}->plugins) {
		my (@newlogs) = $plugin->invoke('get_logs');
		while (@newlogs) {
			my ($log, $rxlist) = splice(@newlogs, 0, 2);
			for my $rx (@$rxlist) {
print "Search for $rx in $log for $plugin\n" if $debug;
				push(@{$logs{$log}{$rx}}, $plugin);
			}
		}
	}
	for my $log (keys %logs) {
		my @rx = keys %{$logs{$log}};
		$merged{$log} = shift(@rx);
		for my $rx (@rx) {
			$merged{$log} = qr/(?:$merged{$log}|$rx)/;
		}
	}
	openlogfiles();
	print "END  ssd postconfig\n" if $debug;
	if ($self->{logpriority}) {
		$self->{gd_logpriority} = $self->{logpriority};
		$self->gd_redirect_output;
	}
}

sub gd_setup_signals
{
	my $self = shift;
	$SIG{USR2} = sub {
		$debug++;
		print STDERR "Debugging level: $debug\n";
	};
	$SIG{USR1} = sub {
		print STDERR "Debugging off\n";
		$debug = 0;
	};
	$self->SUPER::gd_setup_signals();
}

sub gd_run_body
{
	my $self = shift;
	for my $file (keys %logs) {
		$self->checklog($file);
	}
	$self->{plugins}->invoke('periodic');
	print "sleeping $sleep_time...\n" 
		if $debug >= 3;
}

sub gd_interval
{
	my $self = shift;
	return $sleep_time;
}

sub checklog
{
	my ($self, $file) = @_;
	print "checking for new stuff in $file\n"
		if $debug;
	my $fh = $loghandles{$file};
	while (<$fh>) {
		unless (/$merged{$file}/) {
			print STDERR "not found: $_" if $debug >= 5;
		}
		print STDERR "gross found: $_" if $debug >= 4;
		for my $rx (keys %{$logs{$file}}) {
			print STDERR "trying $rx...\n" if $debug >= 3;
			next unless /$rx/;
			print STDERR "FOUND $rx\n" if $debug;
			for my $plugin (@{$logs{$file}{$rx}}) {
				$plugin->invoke('matched_line', $file, $rx);
			}
		}
	}
	if ((stat($fh))[1] != (stat($file))[1]) {
		print "log file $file must have rolled, re-opening!\n" if $debug;
		$loghandles{$file} = new FileHandle "<$file" || confess "cannot open $file: $!";
		$self->{api}->log_rolled($file);
		$self->checklog($file);
	}
}

sub openlogfiles
{
	for my $file (keys %logs) {
		my $fh;
		$loghandles{$file} = $fh = new FileHandle "<$file" 
			|| confess "cannot open $file: $!";
		open($fh, "<$file")
			|| confess "cannot open $file: $!";
		seek($fh, 0, 2)
			|| confess "cannot seek end of $file: $!";
	}
}

sub closelogfiles
{
	for my $file (keys %loghandles) {
		my $fh = $loghandles{$file};
		$fh->close();
		delete $loghandles{$file};
	}
}

package SyslogScan::Daemon::Plugin;

use Plugins::Style1::Plugin;
use strict;
use warnings;
use Plugins::API;

our @ISA = qw(Plugins::Style1::Plugin);

sub set_api
{
	my ($self, $ssd_configfile, @api) = @_;

	my $config = $self->{configfile} || $ssd_configfile;

	$self->{myapi} = Plugins::API->new;
	$self->{myapi}->api(@api);
	$self->{myapi}->autoregister($self);
	$self->{myapi}->register(undef, parentapi => sub { return $self->{api} });

	$self->{plugins} = new Plugins context => $self->{context};
	$self->{plugins}->readconfig($config, self => $self);

	$self->{plugins}->api($self->{myapi});
	$self->{myapi}->plugins($self->{plugins});

	$self->{plugins}->initialize();
	$self->{plugins}->invoke('preconfig', $config);
}

sub postconfig {}
sub matched_line {}
sub preconfig {}
sub log_rolled {}

sub get_logs
{
	my ($self) = @_;
	return () unless $self->{plugins};
	my %logs;
	my @r;
	for my $plugin ($self->{plugins}->plugins) {
		my (@newlogs) = $plugin->invoke('get_logs');
		push(@r, @newlogs);
		while (@newlogs) {
			my ($log, $rxlist) = splice(@newlogs, 0, 2);
			for my $rx (@$rxlist) {
				push(@{$logs{$log}{$rx}}, $plugin);
			}
		}
	}
	$self->{logs} = \%logs;
	return @r;
}

sub periodic
{
	my ($self) = @_;
	return () unless $self->{plugins};
	$self->{plugins}->invoke('periodic');
}

1;

