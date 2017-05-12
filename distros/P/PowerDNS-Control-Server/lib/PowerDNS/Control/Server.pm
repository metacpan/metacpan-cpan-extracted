# $Id: Server.pm 4430 2012-01-14 00:27:53Z augie $
# Provides an interface to create a server to control both the
# PowerDNS Authoritative and Recursive servers.

package PowerDNS::Control::Server;

use warnings;
use strict;

use IO::Socket;
use POSIX;
use Unix::Syslog qw(:subs :macros);
use Carp;
use English;
use Unix::PID;
use Net::CIDR;
use File::Temp  qw/ :mktemp /;

=head1 NAME

PowerDNS::Control::Server - Provides an interface to control the PowerDNS daemon.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	use PowerDNS::Control::Server;

	# Setting parameters and their default values.
	my $params = {	port		=>	988,
			listen_address	=>	'0.0.0.0',
			allowed_methods =>	['auth_retrieve' , 'rec_wipe_cache'],
			debug		=>	0,
			syslog_ident	=>	'pdns-control-server',
			syslog_option	=>	LOG_PID | LOG_PERROR,
			syslog_facility	=>	LOG_LOCAL3,
			syslog_priority	=>	LOG_INFO,
			pid_file 	=>	'/var/run/pdns-control-server.pid',
			auth_cred	=>	'pa55word',
			allowed_ips	=>	['127.0.0.1/23' , '192.168.0.1/32'],
			socket_path	=>	'/var/run/',
	};

	my $pdns = PowerDNS::Control::Server->new($params);

=head1 DESCRIPTION

	PowerDNS::Control::Server provides a way to create a server to control
	both the PowerDNS Authoritative and Recursive servers.

	PowerDNS::Control::Server was written in tandem with PowerDNS::Control::Client, 
	but there is no reason why you could not write your own client.

	The protocol PowerDNS::Control::Server implements is very simple and is based
	off of SMTP; after successful connection the client can expect a banner, then
	the client can execute commands agains the server; the server returns "+OK" if
	all is well and "-ERR <error_message>" if there was a problem. A sample session
	showing the protocol in use is below:

	[augie@augnix Control]$ telnet localhost 10988
	Trying 127.0.0.1...
	Connected to augnix.noc.sonic.net (127.0.0.1).
	Escape character is '^]'.
	+OK Welcome 127.0.0.1
	auth_retrieve schwer.us
	+OK
	quit
	+OK Bye

	The commands executed are based on the pdns_control and rec_control programs
	on the server. Documentation for these programs can be found at:

	http://docs.powerdns.com/

	Note: All the commands may not be supported in this module, but the list of
	supported commands is listed in the Methods section below. Methods that begin
	with 'auth' control the Authoritative PowerDNS Server and methods that begin
	with 'rec' control the Recursive PowerDNS Server.

=head1 METHODS

=head2 new(\%params)

	my $params = {	port		=>	988,
			listen_address	=>	'0.0.0.0',
			allowed_methods =>	['auth_retrieve' , 'rec_wipe_cache'],
			debug		=>	0,
			syslog_ident	=>	'pdns-control-server',
			syslog_option	=>	LOG_PID | LOG_PERROR,
			syslog_facility	=>	LOG_LOCAL3,
			syslog_priority	=>	LOG_INFO,
			pid_file 	=>	'/var/run/pdns-control-server.pid',
			auth_cred	=>	'pa55word',
			allowed_ips	=>	['127.0.0.1/23' , '192.168.0.1/32'],
			socket_path	=>	'/var/run/',
	};
	my $pdns = PowerDNS::Control::Server->new($params);

	Creates a PowerDNS::Control::Server object.

=over 4

=item port

Port to listen on. Default is 988.

=item listen_address

Address to listen on. Default is 0.0.0.0 .

=item allowed_methods

List of methods the server is allowed to run; if not specified, then none of the
control methods are allowed.

=item debug

Set to 1 to keep the server in the foreground for debugging. The default is 0.

=item syslog_ident

Use to set the Unix::Syslog::openlog($ident) variable. The default is 'pdns-control-server'.

=item syslog_option

Use to set the Unix::Syslog::openlog($option) variable. The default is LOG_PID | LOG_PERROR

=item syslog_facility

Use to set the Unix::Syslog::openlog($facility) variable. The default is LOG_LOCAL3

=item syslog_priority

Use to set the Unix::Syslog::syslog($priority) variable. The default is LOG_INFO

=item pid_file

Where to store the PID file; default is '/var/run/pdns-control-server.pid'.

=item auth_cred

Set if you want the server to require password authentication.
If set, then the client should expect to see

"+OK ready for authentication"

to which it should reply

"AUTH pa55word"

Valid authentication will move the server into the main request loop;
invalid authentication will disconnect the client.

=item allowed_ips

Set if you want the server to only accept connections from the IPs in this list.
The list elements are IPs in CIDR notation, this means if you want to specify a single
IP, then you must give it a '/32' this is an unfortunate bug in Net::CIDR .

=item socket_path

The path where the PowerDNS recursor and authoritative server control sockets are located.
The default is '/var/run/'; this is also where temporary sockets will be placed for 
communicating with the PowerDNS control sockets, so make sure it is accessible by this
program for reading and writing.

=item rec_control_socket

If the recursor's control socket is located someplace other then in socket_path, then 
you can set that location here.

=item pdns_control_socket

If the authoritative server's control socket is located someplace other then in socket_path, then 
you can set that location here.

=back

=cut

sub new
{
	my $class = shift;
	my $params= shift;
	my $self  = {};

	$SIG{CHLD} = 'IGNORE'; # auto. reap zombies.
	$OUTPUT_AUTOFLUSH = 1;

	bless $self , ref $class || $class;

	$self->{'port'} = defined $params->{'port'} ? $params->{'port'} : 988;
	$self->{'listen_address'} = defined $params->{'listen_address'} ? $params->{'listen_address'} : '0.0.0.0';
	$self->{'pdns_control'} = defined $params->{'pdns_control'} ? $params->{'pdns_control'} : '/usr/bin/pdns_control';
	$self->{'rec_control'} = defined $params->{'rec_control'} ? $params->{'rec_control'} : '/usr/bin/rec_control';
	$self->{'debug'} = defined $params->{'debug'} ? $params->{'debug'} : 0;
	$self->{'syslog_ident'} = defined $params->{'syslog_ident'} ? $params->{'syslog_ident'} : 'pdns-control-server';
	$self->{'syslog_option'} = defined $params->{'syslog_option'} ? $params->{'syslog_option'} : LOG_PID | LOG_PERROR;
	$self->{'syslog_facility'} = defined $params->{'syslog_facility'} ? $params->{'syslog_facility'} : LOG_LOCAL3;
	$self->{'syslog_priority'} = defined $params->{'syslog_priority'} ? $params->{'syslog_priority'} : LOG_INFO;
	$self->{'pid_file'} = defined $params->{'pid_file'} ? $params->{'pid_file'} : '/var/run/pdns-control-server.pid';
	$self->{'auth_cred'} = defined $params->{'auth_cred'} ? $params->{'auth_cred'} : '';
	$self->{'allowed_ips'} = defined $params->{'allowed_ips'} ? $params->{'allowed_ips'} : undef; 
	$self->{'socket_path'} = defined $params->{'socket_path'} ? $params->{'socket_path'} : '/var/run/';
	$self->{'pdns_control_socket'} = defined $params->{'pdns_control_socket'} ? $params->{'pdns_control_socket'} : $self->{'socket_path'} . '/pdns.controlsocket';
	$self->{'rec_control_socket'} = defined $params->{'rec_control_socket'} ? $params->{'rec_control_socket'} : $self->{'socket_path'} . '/pdns_recursor.controlsocket';

	$self->{'pid'} = Unix::PID->new();

	$self->{'sock'} = new IO::Socket::INET (
		LocalAddr => $self->{'listen_address'},
		LocalPort => $self->{'port'},
		Proto     => 'tcp',
		Reuse     => 1,
		Listen    => 20 ) or croak "Could not open socket : $!\n";

	# populate the allowed_methods list.
	# the default is to not allow any methods.
	if ( defined $params->{'allowed_methods'} )
	{
		for my $method ( @{$params->{'allowed_methods'}} )
		{
			$self->{'allowed_methods'}->{$method} = 1;
		}
	}

	return $self;
}

=head2 control_socket_comm($message , $socket)

Internal method.
Deal with the communication to and from the PowerDNS rec|auth. server.
Expects a message to send and a control socket to send to.
Returns the message received.

=cut

sub control_socket_comm
{
	my $self 	= shift;
	my $msg  	= shift;
	my $c_socket 	= shift;
	my $timeout	= 10;
	my $sock_type	= '';

	# rec_control uses a DGRAM socket and pdns_control uses a STREAM socket.
	if ( $c_socket eq $self->{'rec_control_socket'} )
	{ $sock_type = SOCK_DGRAM; }
	else
	{ $sock_type = SOCK_STREAM; }
	
	my $t_socket  = $self->{'socket_path'} . '/asockXXXXXX';
	my $sock_fh;

	eval
	{ ($sock_fh , $t_socket) = mkstemp($t_socket); };

	# if the eval above failed.
	if ( $@ )
	{
		carp "Could not create temporary socket $t_socket : $!";
		return "Could not create temporary socket $t_socket : $!";
	}

	local $SIG{INT} = $SIG{TERM} = sub { unlink($t_socket); croak "Caught SIG_INT or SIG_TERM." };

	socket($sock_fh , PF_UNIX , $sock_type , 0);

	unlink $t_socket;

	if ( ! bind($sock_fh , sockaddr_un($t_socket)) )
	{
		unlink($t_socket);
		carp "Cannont bind to temp. socket $t_socket : $!";
		return "Cannont bind to temp. socket $t_socket : $!";
	}

	chmod(0666 , $t_socket);

	if ( ! connect($sock_fh , sockaddr_un($c_socket)) )
	{
		unlink($t_socket);
		carp "Cannot connect to control socket $c_socket : $!";
		return "Cannot connect to control socket $c_socket : $!";
	}

	send($sock_fh , "$msg\n" , 0);

	$msg = '';

	eval 
	{
		local $SIG{ALRM} = sub { $msg = 'Timeout waiting to receive from server.'; carp 'Timeout waiting to receive from server.' };
		alarm($timeout);
		recv($sock_fh , $msg , 16384 , 0);
		alarm(0);
	};

	if ( $@ ) # if the eval above failed.
	{
		$msg = "Could not get response from server: $@";
		carp "Could not get response from server: $@";
	}

	chomp $msg;

	close($sock_fh);

	unlink($t_socket);

	return $msg;
}

=head2 auth_retrieve($domain)

Expects a scalar domain name to be retrieved.
Calls pdns_control retrieve domain .
Returns "+OK" if successful or "-ERR error message" otherwise.

=cut

sub auth_retrieve($)
{
	my $self   = shift;
        my $domain = shift;

	my $msg	= $self->control_socket_comm("retrieve $domain" , $self->{'pdns_control_socket'});

	if ( $msg =~ /^Added/ )
	{
		$self->logmsg('+OK');
		return "+OK\n";
	}
	else
	{
		$self->logmsg("Error: $msg");
		return "-ERR $msg\n";
	}
}

=head2 auth_wipe_cache($domain)

Expects a scalar domain name to be wiped out of cache.
Calls pdns_control purge domain$ .
Returns "+OK" if successful or "-ERR error message" otherwise.

=cut

sub auth_wipe_cache($)
{
	my $self   = shift;
        my $domain = shift;

	my $msg	= $self->control_socket_comm("purge $domain\$" , $self->{'pdns_control_socket'});

	if ( $msg =~ /^\d+/ )
	{
		$self->logmsg('+OK');
		return "+OK\n";
	}
	else
	{
		$self->logmsg("Error: $msg");
		return "-ERR $msg\n";
	}
}

=head2 rec_wipe_cache($domain)

Expects a scalar domain name to be wiped out of cache.
Calls rec_control wipe-cache domain .
Returns "+OK" if successful or "-ERR error message" otherwise.

=cut

sub rec_wipe_cache($)
{
	my $self   = shift;
        my $domain = shift;

	my $msg	= $self->control_socket_comm("wipe-cache $domain" , $self->{'rec_control_socket'});

	if ( $msg =~ /^wiped/ )
	{
		$self->logmsg('+OK');
		return "+OK\n";
	}
	else
	{
		$self->logmsg("Error: $msg");
		return "-ERR $msg\n";
	}
}

=head2 rec_ping

Does not expect anything.
Calls rec_control ping.
Returns "+OK" if the recursor is running and "-ERR error message" otherwise.

=cut

sub rec_ping
{
	my $self = shift;
	my $msg  = $self->control_socket_comm('ping' , $self->{'rec_control_socket'});
	
	if ( $msg =~ /^pong/ )
	{ 
		$self->logmsg("+OK");
		return "+OK\n";
	}
	else
	{
		$self->logmsg("Error: $msg");
		return "-ERR $msg\n";
	}
}

=head2 auth_ping

Does not expect anything.
Calls pdns_control ping.
Returns "+OK" if the auth. server is running and "-ERR error message" otherwise.

=cut

sub auth_ping
{
	my $self = shift;
	my $msg  = $self->control_socket_comm('ping' , $self->{'pdns_control_socket'});
	
	if ( $msg eq 'PONG' )
	{ 
		$self->logmsg("+OK");
		return "+OK\n";
	}
	else
	{
		$self->logmsg("Error: $msg");
		return "-ERR $msg\n";
	}
}

=head2 start

Does not expect anything.
Forks the server to the background unless "debug" was set.

=cut

sub start
{
	my $self = shift;
	my ($conn , $peer , $pid , $command , $action , $arg1 , $arg2);
	&daemonize unless $self->{'debug'};

	# Note the PID so we can kill it later and check if another server is already running.
	$self->{'pid'}->pid_file_no_unlink($self->{'pid_file'}) or croak "The server is already running: $!";

	$self->logmsg("Server startup complete, accepting connections on port $self->{'port'}");

	while ( $conn = $self->{'sock'}->accept() )
	{
		$peer = $conn->peerhost();

		$self->logmsg("Incoming connection from $peer");

		# Check to see if we should validate the client IP against our 
		# allowed_ips list.
		if ( defined $self->{'allowed_ips'} )
		{
			if ( ! Net::CIDR::cidrlookup( $peer , @{$self->{'allowed_ips'}} ) )
			{
				$self->logmsg("Unauthorized connection from $peer");
				$conn->shutdown(2);
				next;
			}
		}

		# Parent goes back up to wait for new connections.
		# Child continues on; handling this session.
		$pid = fork(); next if $pid;

		# Check if we should ask for auth. cred.
		if ( $self->{'auth_cred'} )
		{
			print $conn "+OK ready for authentication\n";
			my $auth = <$conn>;
			$auth =~ s/[\r]//g;

			chomp($auth);
			if ( $auth ne "AUTH $self->{'auth_cred'}" )
			{
				$self->logmsg("Invalid authentication from " . $conn->peerhost);
				print $conn "-ERR invalid authentication\n";
				$conn->shutdown(2);
				exit;
			}
			else
			{
				$self->logmsg("Auth succesful from " . $conn->peerhost);
				print $conn "+OK Auth sucessful\n";
			}
		}
		else
		{
			print $conn "+OK Welcome $peer\n";
		}

		# Main request loop; try to fulfill requests until the client is done.
		while(1)
		{
			$command = <$conn>;
			$command =~ s/[\r\n]//g;
			chomp($command);
			($action,$arg1,$arg2) = split(/ /,$command);

			my $method_is_allowed = $self->method_is_allowed($action);

			if (!$method_is_allowed && ($action ne 'quit'))
			{
				$self->logmsg("Recieved method ($action) that was not allowed\n");
				print $conn "-ERR method not allowed\n";
			}
			elsif ($action eq 'auth_retrieve')
			{
				unless ($arg1)
				{
					$self->logmsg("Recieved improper command syntax :: '$command'\n");
					print $conn "-ERR invalid command syntax\n";
					next;
				}
				my $result = $self->auth_retrieve($arg1);
				print $conn $result;

			}
			elsif ($action eq 'auth_wipe_cache')
			{
				unless ($arg1)
				{
					$self->logmsg("Recieved improper command syntax :: '$command'\n");
					print $conn "-ERR invalid command syntax\n";
					next;
				}
				my $result = $self->auth_wipe_cache($arg1);
				print $conn $result;
			}
			elsif ($action eq 'rec_wipe_cache')
			{
				unless ($arg1)
				{
					$self->logmsg("Recieved improper command syntax :: '$command'\n");
					print $conn "-ERR invalid command syntax\n";
					next;
				}
				my $result = $self->rec_wipe_cache($arg1);
				print $conn $result;
			}
			elsif ($action eq 'rec_ping')
			{
				my $result = $self->rec_ping;
				print $conn $result;
			}
			elsif ($action eq 'auth_ping')
			{
				my $result = $self->auth_ping;
				print $conn $result;
			}
			elsif ($action eq 'quit')
			{
				$self->logmsg("Shutting down.");
				print $conn "+OK Bye\n";
				$conn->shutdown(2);
				exit;
			}
			else
                	{
                        	print $conn "-ERR '$action' unknown command.\n";
	                        $self->logmsg("'$action' unknown command.");
        	        }
		}
	}
}

=head2 stop

Does not expect anything.
Kills the running server.

=cut

sub stop
{
	my $self = shift;

	$self->logmsg("Stopping parent server.");

	my $ret = $self->{'pid'}->kill_pid_file($self->{'pid_file'});
	
	# Check the return value for errors.
	if ( $ret == 0)
	{
		$self->logmsg("PID file ($self->{'pid_file'}) exists but could not be opened : $!");
		croak "PID file ($self->{'pid_file'}) exists but could not be opened : $!";
	}
	elsif ( ! defined $ret )
	{
		$self->logmsg("Server could not be killed from PID file ($self->{'pid_file'}) : $!");
		croak "Server could not be killed from PID file ($self->{'pid_file'}) : $!";
	}
	elsif ( $ret == -1 )
	{
		$self->logmsg("Could not clean up PID file ($self->{'pid_file'}) after successful termination of server : $!");
		carp "Could not clean up PID file ($self->{'pid_file'}) after successful termination of server : $!";
	}
	else
	{
		$self->logmsg("Abnormal termination: $!");
		croak "Abnormal termination: $!";
	}
	exit;
}

=head2 daemonize

Internal method.
Close all file handles and fork to the background.

=cut

sub daemonize
{
	# Redirect STDIN, STDOUT and STDERR.
	open STDIN , '/dev/null' or croak "Could not read /dev/null : $!";
	open STDOUT, '>/dev/null' or croak "Could not write to /dev/null : $!";
	my $pid = fork;
	croak "fork: $!" unless defined ($pid);
	if ($pid != 0) { exit; }
	open STDERR , '>&STDOUT' or croak "Could not dup STDOUT : $!";
}

=head2 logmsg($message)

Internal method.
Logs to syslog if debug is not turned on.
If debug is on, then log to STDOUT.

=cut

sub logmsg
{
	my $self = shift;
	my $msg  = shift;
	carp "logmsg: $msg\n" if $self->{'debug'};
	openlog($self->{'syslog_ident'} , $self->{'syslog_option'} , $self->{'syslog_facility'});
	eval { syslog($self->{'syslog_priority'} , '%s', $msg); };
	closelog;
	if ( $EVAL_ERROR )
	{ carp "syslog() failed ($msg) :: $@\n"; }
}

=head2 method_is_allowed($method)

Internal method.
Verify that the method is 'allowed'; i.e. that it is in the 
allowed_methods list.

=cut

sub method_is_allowed
{
	my $self   = shift;
	my $method = shift;

	return defined $self->{'allowed_methods'}->{$method};
}

=head1 AUTHOR

Augie Schwer, C<< <augie at cpan.org> >>

http://www.schwer.us

=head1 BUGS

Please report any bugs or feature requests to
C<bug-powerdns-control-server at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PowerDNS-Control-Server>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PowerDNS::Control::Server

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PowerDNS-Control-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PowerDNS-Control-Server>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PowerDNS-Control-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/PowerDNS-Control-Server>

=back

=head1 ACKNOWLEDGEMENTS

I would like to thank Sonic.net for allowing me to release this to the public.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Augie Schwer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 VERSION

	0.03
	$Id: Server.pm 4430 2012-01-14 00:27:53Z augie $

=cut

1; # End of PowerDNS::Control::Server
