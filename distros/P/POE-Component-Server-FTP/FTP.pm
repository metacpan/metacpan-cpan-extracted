package POE::Component::Server::FTP;

###########################################################################
### POE::Component::Server::FTP
### L.M.Orchard (deus_x@pobox.com)
### David Davis (xantus@cpan.org)
###
### TODO:
###  - Should the Limiting depend on the ip connected via PORT/PASV or
###		the control connection ip
###  - Change virus checking to postprocessing
###
### Copyright (c) 2001 Leslie Michael Orchard.  All Rights Reserved.
### This module is free software; you can redistribute it and/or
### modify it under the same terms as Perl itself.
###
### Changes Copyright (c) 2003-2004 David Davis and Teknikill Software
###########################################################################

use strict;
use warnings;

our @ISA = qw(Exporter);
our $VERSION = '0.08';

use Socket;
use Carp;
use POE qw(Session Wheel::ReadWrite Filter::Line
		   Driver::SysRW Wheel::SocketFactory
		   Wheel::Run Filter::Reference);
use POE::Component::Server::FTP::ControlSession;
use POE::Component::Server::FTP::ControlFilter;

sub spawn {
	my $package = shift;
	croak "$package requires an even number of parameters" if @_ % 2;
	my %params = @_;
	my $alias = $params{'Alias'};
	$alias = 'ftpd' unless defined($alias) and length($alias);
	$params{'Alias'} = $alias;
	$params{'ListenPort'} = $params{'ListenPort'} || 21;
	$params{'TimeOut'} = $params{'TimeOut'} || 0;
	$params{'DownloadLimit'} = $params{'DownloadLimit'} || 0;
	$params{'UploadLimit'} = $params{'UploadLimit'} || 0;
	$params{'LimitScheme'} = $params{'LimitSceme'};
	$params{'LimitScheme'} = $params{'LimitScheme'} || 'none';

	POE::Session->create(
		#options => {trace=>1},
		args => [ \%params ],
		package_states => [
			'POE::Component::Server::FTP' => {
				_start				=> '_start',
				_stop				=> '_stop',
				_write_log			=> '_write_log',
				register			=> 'register',
				unregister			=> 'unregister',
				notify				=> 'notify',
				accept				=> 'accept',
				accept_error		=> 'accept_error',
				signals				=> 'signals',
				_bw_limit			=> '_bw_limit',
				_dcon_cleanup		=> '_dcon_cleanup',
				virus_check_error	=> 'virus_check_error',
				virus_check_done	=> 'virus_check_done',
				virus_check_stdout	=> 'virus_check_stdout',
				virus_check_stderr	=> 'virus_check_stderr',
			}
		],
	);

	return 1;
}

sub _start {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	%{$heap->{params}} = %{ $_[ARG0] };

	$heap->{_main_pid} = $$;

	$session->option( @{$heap->{params}{'SessionOptions'}} ) if $heap->{params}{'SessionOptions'};
	$kernel->alias_set($heap->{params}{'Alias'});

	# watch for SIGINT
	$kernel->sig('INT', 'signals');

	# create a socket factory
	$heap->{wheel} = POE::Wheel::SocketFactory->new(
		BindPort       => $heap->{params}{ListenPort},          # on this port
		Reuse          => 'yes',          # and allow immediate port reuse
		SuccessEvent   => 'accept',       # generating this event on connection
		FailureEvent   => 'accept_error'  # generating this event on error
	);

	$kernel->call($session->ID => _write_log => { v => 2, msg => "Listening to port $heap->{params}{ListenPort} on all interfaces." });
}

sub _stop {
	my ($kernel, $session) = @_[KERNEL, SESSION];
	$kernel->call($session->ID => _write_log => { v => 2, msg => "Server stopped." });
}

sub register {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_increment($sender->ID, __PACKAGE__);
    $heap->{listeners}->{$sender->ID} = 1;
    $kernel->post($sender->ID => ftpd_registered => $_[SESSION]->ID);
}

sub unregister {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_decrement($sender->ID, __PACKAGE__);
    delete $heap->{listeners}->{$sender->ID};
}

sub notify {
    my($kernel, $heap, $sender, $name, $data) = @_[KERNEL, HEAP, SENDER, ARG0, ARG1];
    $data->{con_session} = $sender unless(exists($data->{con_session}));
	my $ret = 0;
	foreach (keys %{$heap->{listeners}}) {
    	my $tmp = $kernel->call($_ => $name => $data);
		if (defined($tmp)) {
			$ret += $tmp;
		}
#		print STDERR "ret is $ret for $name\n";
	}
	return ($ret > 0) ? 1 : 0;
}

# Accept a new connection

sub accept {
	my ($kernel, $heap, $session, $accept_handle, $peer_addr, $peer_port) = @_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];

	$peer_addr = inet_ntoa($peer_addr);
	my ($port, $ip) = (sockaddr_in(getsockname($accept_handle)));
	$ip = inet_ntoa($ip);
	my $report_ip = (defined $heap->{params}{FirewallIP}) ? $heap->{params}{FirewallIP} : $ip;

	$kernel->call($session->ID => _write_log => { v => 2, msg => "Server received connection on $report_ip ($ip:$port) from $peer_addr : $peer_port" });

	my $opt = { %{$heap->{params}} };
	$opt->{Handle} = $accept_handle;
	$opt->{ListenIP} = $report_ip;
	$opt->{PeerAddr} = $peer_addr;
	$opt->{PeerPort} = $peer_port;

	$opt->{LocalIP} = $ip;
	$opt->{LocalPort} = $port;
	$opt->{ReportIP} = $report_ip;

	unless ($kernel->call($session->ID, notify => ftpd_accept => {
			session => $session,
			handle => $accept_handle,
			report_ip => $report_ip,
			local_ip => $ip,
			local_port => $port,
			peer_addr => $peer_addr,
			peer_port => $peer_port,
		})) {
			close($accept_handle);
			return 0;
	}

	POE::Component::Server::FTP::ControlSession->new($opt);	
}

sub _bw_limit {
    my ($kernel, $heap, $session, $sender, $type, $ip, $bps) = @_[KERNEL, HEAP, SESSION, SENDER, ARG0, ARG1, ARG2];
	$heap->{$type}{$ip}{$sender->ID} = $bps;
	my $num = scalar(keys %{$heap->{$type}{$ip}});
	my $newlimit = ((($type eq 'dl') ? $heap->{params}{'DownloadLimit'} : $heap->{params}{'UploadLimit'}) / $num);
	return ($bps > $newlimit) ? 1 : 0;
}

sub _dcon_cleanup {
    my ($kernel, $heap, $session, $type, $ip, $sid) = @_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];
	$kernel->call($session->ID => _write_log => { v => 4, msg => "cleaing up $type limiter for $ip (session $sid)" });
	delete $heap->{$type}{$ip}{$sid};
}

# Handle an error in connection acceptance

sub accept_error {
	my ($kernel, $session, $operation, $errnum, $errstr) = @_[KERNEL, SESSION, ARG0, ARG1, ARG2];
	$kernel->call($session->ID => write_log => { v => 1, msg => "Server encountered $operation error $errnum: $errstr" });
	$kernel->call($session->ID, notify => accept_error => { session => $session, operation => $operation, error_num => $errnum, err_str => $errstr });
}

# Handle incoming signals (INT)

sub signals {
	my ($kernel, $session, $signal_name) = @_[KERNEL, SESSION, ARG0];

	$kernel->call($session->ID => _write_log => { v => 1, msg => "Server caught SIG$signal_name" });

	# to stop ctrl-c / INT
	if ($signal_name eq 'INT') {
		#$_[KERNEL]->sig_handled();
	}

	return 0;
}

sub _write_log {
	my ($kernel, $session, $heap, $sender, $o) = @_[KERNEL, SESSION, HEAP, SENDER, ARG0];
	if ($o->{v} <= $heap->{params}{'LogLevel'}) {
#		my $datetime = localtime();
		my $sender = (defined $o->{sid}) ? $o->{sid} : $sender->ID;
		my $type = (defined $o->{type}) ? $o->{type} : 'M';
#		print "[$datetime][$type$sender] $o->{msg}\n";
		$kernel->call($session->ID, notify => ftpd_write_log => {
			sender => $sender,
			type => $type,
			msg => $o->{msg},
			data => $o,
		});
	}
}

# TODO finish this, and change it to post processor

sub virus_check {
	my ($kernel, $session, $heap, $sender, $o) = @_[KERNEL, SESSION, HEAP, SENDER, ARG0];

	if (exists($heap->{viruscheck_wheel})) {
		# try again later, 1 at a time!
		$kernel->delay_set(virus_check => 15 => splice(@_,ARG0));
		return;
	}

	my $params = $heap->{params}{'VirusCheckerParams'} || [];

	$heap->{viruscheck_wheel} = POE::Wheel::Run->new(
		Program     => $heap->{params}{'VirusCheckerCmd'},
		ProgramArgs => $params,						# Parameters for $program.
		ErrorEvent  => 'virus_check_error',			# Event to emit on errors.
		CloseEvent  => 'virus_check_done',			# Child closed all output.
		StdoutEvent => 'virus_check_stdout',		# Event to emit with child stdout information.
		StderrEvent => 'virus_check_stderr',		# Event to emit with child stderr information.
		StdoutFilter => POE::Filter::Line->new(),	# Child output as lines.
		StderrFilter => POE::Filter::Line->new(),	# Child errors are lines.
	);

}

sub virus_check_error {
	print "error: $_[ARG0]";
}

sub virus_check_done {
	print "done: $_[ARG0]";
}

sub virus_check_stdout {
	print "stdout: $_[ARG0]";
}

sub virus_check_stderr {
	print "stderr: $_[ARG0]";
}

1;
__END__

=head1 NAME

POE::Component::Server::FTP - Event-based FTP server on a virtual filesystem

=head1 SYNOPSIS

	use POE qw(Component::Server::FTP);
	use Filesys::Virtual;

	POE::Component::Server::FTP->spawn(
		Alias           => 'ftpd',				# ftpd is default
		ListenPort      => 2112,				# port to listen on
		Domain			=> 'blah.net',			# domain shown on connection
		Version			=> 'ftpd v1.0',			# shown on connection, you can mimic...
		AnonymousLogin	=> 'deny',				# deny, allow
		FilesystemClass => 'Filesys::Virtual::Plain', # Currently the only one available
		FilesystemArgs  => {
			'root_path' => '/',					# This is actual root for all paths
			'cwd'       => '/',					# Initial current working dir
			'home_path' => '/home',				# Home directory for '~'
		},
		# use 0 to disable these Limits
		DownloadLimit	=> (50 * 1024),			# 50 kb/s per ip/connection (use LimitScheme to configure)
		UploadLimit		=> (100 * 1024),		# 100 kb/s per ip/connection (use LimitScheme to configure)
		LimitScheme		=> 'ip',				# ip or per (connection)

		LogLevel		=> 4,					# 4=debug, 3=less info, 2=quiet, 1=really quiet
		TimeOut			=> 120,					# Connection Timeout
	);

	$poe_kernel->run();

=head1 DESCRIPTION

POE::Component::Server::FTP is an event driven FTP server backed by a
virtual filesystem interface as implemented by Filesys::Virtual.

=head1 AUTHORS

L.M.Orchard, deus_x@pobox.com

David Davis, xantus@cpan.org

=head1 SEE ALSO

perl(1), Filesys::Virtual.

=cut
