#!/usr/bin/perl -wT
##
##########################################################################################
##											##
## Net::FileShare.pm             1-07-03						##
## Gene Gallistel                <gravalo@uwm.edu>					##
## Copyright (c) 1-07-03 	All rights reserved.					##
##											##
## This program is free software. You can redistribute and/or modify this bundle 	##
## under the same terms as Perl itself.							##
##											##
##########################################################################################
##
##
##
package Net::FileShare;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use Carp;
use Fcntl qw( O_WRONLY O_RDONLY O_CREAT O_APPEND );
use strict;
use vars qw( $VERSION @ISA @EXPORT );
require Exporter;

$VERSION = '0.18';
@ISA = qw(Exporter);
@EXPORT = qw();

## Command codes for server and client
use vars qw( $HELO $GET $LIST $QUIT $PERM_DENY $FILE_NOT_FOUND $INVAL_NAME $UNRECOG_CMD $PATH_EQ_DIR $ACK_CMD);
## Server Greeting
$HELO		= 	'1';
## Client Commands
$GET		=	'101';
$LIST		=	'102';
$QUIT		=	'103';
## Server Responses
$PERM_DENY	=	'201';
$FILE_NOT_FOUND	=	'202';
$INVAL_NAME	=	'203';
$UNRECOG_CMD	=	'204';
$PATH_EQ_DIR	=	'205';
$ACK_CMD	=	'301';	# acknowledge a command 

## all commands from the server should also contain a message.
## below are a series of stock messages, for the server to send.
## look at the handle_request sub to find their usage.
use vars qw( $helo_msg  $perm_deny_msg $file_not_found_msg $inval_name_msg $unrecog_cmd_msg $path_eq_dir_msg);
$helo_msg = "Welcome...this server uses Net::FileShare";
$perm_deny_msg = "Permission denied";
$file_not_found_msg = "File requested was not found";
$inval_name_msg = "Invalid file name, name supplied may contain invalid characters";
$unrecog_cmd_msg = "Client commands are as follows: list, get, and quit";
$path_eq_dir_msg = "Path supplied is a directory, not a file";


	sub new 
	{
		my ($class, %args) = @_;
		bless {
			_send_only	=>	$args{_send_only} 	|| '0',
			_socket		=>	$args{_socket}		|| '1',
			_directory	=>	$args{_directory}	|| '???',
			_debug		=>	$args{_debug}		|| '0',
		}, $class;
	}

	## self explanitory
	sub version { $VERSION; }

	sub DESTROY 
	{ 
		my ($self) = shift;
		undef %$self;
		sleep 1;
	}
	
	sub REAPER { 1 until (waitpid(-1, WNOHANG) == -1) }


	## will test if an object can become a server
	sub server_run_once
	{
	 	my ($self, $port) = ($_[0], $_[1] || "3000");

                croak "Variable _send_only must be set to 1" if ($self->{_send_only} eq 0);

                ## Create a socket
                my ($socket) = new IO::Socket::INET(
                                Listen          => SOMAXCONN,
                                LocalPort       => $port,
                                Reuse           => 1,
                                Proto           => 'tcp',
                                Timeout         => 120)
                                        or croak "Unable to create server socket: $!";
	}

	sub server_connection
	{
		my ($self, $port) = ($_[0], $_[1] || "3000");
		my ($hostinfo, $remote);

		croak "Variable _send_only must be set to 1" if ($self->{_send_only} eq 0);

		## Create a socket
		my ($socket) = new IO::Socket::INET(
				Listen		=> SOMAXCONN,
				LocalPort	=> $port,
				Reuse		=> 1,
				Proto		=> 'tcp',
				Timeout 	=> 120)
					or croak "Unable to create server socket: $!";
	

		while (1) 
		{
			$SIG{CHLD} = \&REAPER;

			last if (!defined($remote = $socket->accept())); 
			$hostinfo = gethostbyaddr($remote->peeraddr, AF_INET);

			## assign remote to _socket, so all protocol negotiations
			## can be done by handle_request
			$self->{_socket} = $remote;
			
			## fork the child so the parent can go back to listening
			my ($pid) = fork();

			## signal trouble
			unless (defined ($pid)) {
				## add logging and debugging info here
				$self->debug("Server process $$ fork failed!") if ($self->{_debug} eq 1);
				sleep (5);
				return;
			}
				## parent...should include a recording for child, then next to 
				## listen for more inbound children 
				if ( $pid ) {
					next;	
				} 
				$self->debug("Server process $$ forked successfully") if ($self->{_debug} eq 1); 
				$self->handle_request();
				exit;

		}

	}

	sub client_automated
	{
		if(@_ < 4) 
		{
			croak  "Usage: <server> <port> <cmd> <file if cmd eq \"get\">";
		}
		my($self, $server, $port, $cmd, $file) = @_;
		my ($serv_cmd, $serv_msg, $clie_cmd, $clie_msg);
		my ($buffer, $packet, $bytes_read) = (8,0,0); ## set buffer to 8 bytes
                my ($written, $read) = (0,0);
		my ($loc);
                my ($directory) = $self->{_directory};
		local *FD;
                my $localfd = ref($file) || ref(\$file) eq "GLOB";

		## check cmd...if invalid, why go on...
		if (($cmd =~ m/[Gg][Ee][Tt]/) || ($cmd =~ m/[Ll][Ii][Ss][Tt]|[Ll][Ss]|[Dd][Ii][Rr]/)) 
		{

		my ($socket) = IO::Socket::INET->new(
                                PeerAddr => $server,
                                PeerPort => $port,
                                Proto    => "tcp",
                                Type     => SOCK_STREAM)
                        or croak "Cannot establish client socket: $!";

		$self->debug("Client connected to host: $server port: $port") if ($self->{_debug} eq 1);
		$self->{_socket} = $socket;
			
			## wait for a helo
			($serv_cmd, $serv_msg) = $self->recv_cmd();
                	if ($serv_cmd eq $HELO) 
			{
				$self->debug("\n$serv_cmd\t$serv_msg\n") if ($self->{_debug} eq 1);			

				## if $cmd eq get, a file name should be supplied, else error on usage
				if ($cmd =~ m/[Gg][Ee][Tt]/)
				{			
					## quick check length of filename
					if (length($file) eq 0) 
					{
						croak "Invalid file name supplied: $!";
					} else {
					## the situation where a filename does exist 	
					$self->send_cmd($GET,$file);
						($serv_cmd, $serv_msg) = $self->recv_cmd;
                                       
                                        if ($serv_cmd eq $ACK_CMD) {
                                        syswrite(STDOUT, "$serv_cmd\tFile Size: $serv_msg\n");
                                                ## prereq: clients get request has been acknowledged by server
                                                ## thus, the $serv_msg supplied contains the requested files size
                                                my $file_size = $serv_msg;

                                                ## opening the file
                                                if($localfd) {
                                                        $loc = $file;
                                                } else {
                                                        $loc = \*FD;

                                                        unless(sysopen($loc, "$directory/$file", O_CREAT | O_WRONLY))
                                                        {
                                                                carp "Cannot open $directory/$file\n";
                                                                return undef;
                                                        }
                                                }

                                                ## file transfer section
                                                do {
                                                last if ($bytes_read eq $file_size);

                                                        $read = sysread($socket, $packet, $buffer);
                                                                unless (defined($read) && ($read eq length($packet))) {
                                                                        croak "Error reading socket in client connection";
                                                                }
                                                        $written = syswrite($loc, $packet, length($packet));
                                                                unless (defined($written) && ($written eq length($packet))) {
                                                                        croak "Unable to write to new file";
                                                                }
                                                        $bytes_read += $written;
                                                syswrite(STDOUT, "*");
                                                } while ($bytes_read != $file_size);


                                                syswrite (STDOUT, "\nClosing FH\n");
                                                close $loc
                                                        or carp $! ? "Error closing file: $!"
                                                                   : "Exit status $? from close";
	
						}	
					}
				} elsif ($cmd =~ m/[Ll][Ii][Ss][Tt]|[Ll][Ss]|[Dd][Ii][Rr]/) {
					$self->send_cmd($LIST);
					($serv_cmd, $serv_msg) = $self->recv_cmd; #should be ack_cmd + files
					if($serv_cmd eq $ACK_CMD) 
					{		
						my @files = split(/\*/, $serv_msg);
                                                my $files_msg = shift @files;
                                                syswrite(STDOUT, "$serv_cmd\t$files_msg\n");
                                                for (my $i=0; $i < $#files; ++$i) {
                                                        syswrite(STDOUT, ">\t$files[$i]\n");
                                                }									
					}
				} else {
					croak "Invalid Command: commands are get or list";
				}
			} else {
				croak "Server $server:$port not responding";
			}
		} else {
			croak "Invalid Command: commands are get or list";
		}
	}
	
	sub client_interactive
	{
		my ($self,$server,$port) = @_;
		my ($directory) = $self->{_directory};
		my ($serv_cmd, $serv_msg, $clie_cmd, $clie_msg);
		my ($file_size, $loc, $local_file, $tmp); 
                my ($buffer, $packet, $bytes_read) = (8,0,0); ## set buffer to 8 bytes
                my ($written, $read) = (0,0);
		local *FD;
		my $localfd = ref($local_file) || ref(\$local_file) eq "GLOB";
		
		my ($socket) = IO::Socket::INET->new(
				PeerAddr => $server,
				PeerPort => $port,
				Proto	 => "tcp",
				Type	 => SOCK_STREAM)
			or croak "Cannot establish client socket: $!";

		$self->debug("Client connected to host: $server port: $port") if ($self->{_debug} eq 1); 

		$self->{_socket} = $socket;	

		($serv_cmd, $serv_msg) = $self->recv_cmd();
		if ($serv_cmd eq $HELO) {
			## prereq: client has connected to server, 
			## server has forked client properly and passed
			## onto the handle_request sub. client has now
			## received a $HELO + $helo_msg from handle_request
	
			## display cmd and msg from server 
			syswrite(STDOUT, "\n$serv_cmd\t$serv_msg\n");

			## client enters cmd loop. to exist, client will have to type 'quit'
			## minus the quotes of course 
			while (1) {
				syswrite(STDOUT, "> Enter Command (list, get, or quit): ");

				## read and chomp clients cmd from STDIN. this can be tricky, if
				## client specifies 'get filename' instead of get, then filename
				sysread(STDIN, $clie_cmd, 50);
				chomp($clie_cmd);
	
				## handle list cmd, client can type list, ls, or dir, as i often
				## get confused when accessing various ftp servs, etc. so i thought
				## i would build in support for all 
				if ($clie_cmd =~ m/^[Ll][Ii][Ss][Tt]|^[Ll][Ss]|^[Dd][Ii][Rr]/) {
					$self->send_cmd($LIST);
					($serv_cmd, $serv_msg) = $self->recv_cmd; #should be ack_cmd + files
						## if server acknowledges command
						if($serv_cmd eq $ACK_CMD) {
						## $serv_msg is * delimited. The first element is a string
						## followed by a *, then every file after is followed by a 
						## * save the last
							my @files = split(/\*/, $serv_msg);
							my $files_msg = shift @files;
							printf "%d\t%s\n", $serv_cmd, $files_msg;
							for (my $i=0; $i < $#files; ++$i) {
								print ">\t$files[$i]\n";
							}						
						}
					next;
				} elsif ($clie_cmd =~ m/^[Gg][Ee][Tt]/) {
					## initial check...see if client supplied filename in original line
					## its quite possible a user might add a space to the end of get, so
					## check to see if $clie_cmd is larger  4 chars and contains 
					## space. if this is the case their should be a file name attached, else
					## supply one on the next line.
					if (($clie_cmd =~ m/^[Gg][Ee][Tt]\s/) && (length($clie_cmd) > 4)) {
						## assign filename to $local_file and chomp 
						($tmp, $local_file) = split(/ /, $clie_cmd);
						chomp($local_file); 
					} else {
						syswrite(STDOUT, "> Enter the name of the file you wish to download: ");
						sysread(STDIN, $local_file, 25); 
						chomp($local_file);
					}
	
					$self->send_cmd($GET,$local_file);
					($serv_cmd, $serv_msg) = $self->recv_cmd;
					
					if ($serv_cmd eq $ACK_CMD) {
					syswrite(STDOUT, "$serv_cmd\tFile Size: $serv_msg\n");
						## prereq: clients get request has been acknowledged by server
						## thus, the $serv_msg supplied contains the requested files size
						my $file_size = $serv_msg; 

						## opening the file 
						if($localfd) { 
							$loc = $local_file;
						} else {
							$loc = \*FD;

							unless(sysopen($loc, "$directory/$local_file", O_CREAT | O_WRONLY))
							{
								carp "Cannot open $directory/$local_file\n";
								return undef;
							}
						}

						## file transfer section
						do {
						last if ($bytes_read eq $file_size);

						 	$read = sysread($socket, $packet, $buffer);
								unless (defined($read) && ($read eq length($packet))) {
									croak "Error reading socket in client connection";
								}	
							$written = syswrite($loc, $packet, length($packet));
								unless (defined($written) && ($written eq length($packet))) {
									croak "Unable to write to new file";
								}
							$bytes_read += $written;
						syswrite(STDOUT, "*");
						} while ($bytes_read != $file_size);

						## reset used variables...
						($read, $written, $bytes_read, $file_size) = (0,0,0,0);
						syswrite (STDOUT, "\nClosing FH\n");
						close $loc
							or carp $! ? "Error closing file: $!"
								   : "Exit status $? from close";
						next;
					} else {
					## the case where a get request has not been successful
					syswrite(STDOUT, "$serv_cmd\t$serv_msg\n");
					next;
					}
				} elsif ($clie_cmd =~ m/[Qq][Uu][Ii][Tt]/) {
					$self->send_cmd($QUIT);
					print "Goodbye!\n";
					exit 0;	
				} else {
					print "The only commands are: list, get, & quit\n";
					next;
				}
 
			}
		}
	}

	sub send_cmd
	{
	## first off, @_ can either have two or three variables passed 
	## here. if two, (ie. self and cmd) those are command is being sent
	## to the other side, if three, (ie self, cmd, msg) cmd and msg are 
	## sent
		if (@_ > 2) {
			my ($self, $cmd, $data) = @_;
			my ($buf) = "$cmd,$data";
			$self->_send_packet($buf);
		} else {
			my ($self, $cmd) = @_;
			my ($buf) = "$cmd,";
			$self->_send_packet($buf);
		}
	}

	sub recv_cmd
	{
		my ($self) = shift;
		my ($msg);

		## read the awaiting message
		if (eval { $msg = $self->_recv_packet() }) {
			
			if (!defined($msg)) {

			} else {
				my ($type, $buf) = split(/,/, $msg);
				## add in check to confirm type is valid
				## this should not be a problem on server 
				## server side, but kill client side...

				## return cmd type and buffer
				return($type, $buf);
			}
		}
	}

	sub debug 
	{
		my ($self, $msg) = @_;
		syswrite(STDOUT, "$msg\n");
	}	

	sub handle_request
	{
	## purpose: interface with the client on the behalf 
	## of the server. provide the client lists of available files
	## to download as well as providing the actual file transfer 
	## piece
	## prereq: client has connected to the server, and server has
	## successfully forked the client. 
	my ($self) = @_;
	my ($socket) = $self->{_socket};
	my ($directory) = $self->{_directory};
	my ($clie_cmd, $clie_msg, $file_size);
	my ($buffer, $data) = (8, 0); 

	## begin with sending a $HELO to client
	$self->send_cmd($HELO,$helo_msg);

	do  {
	## 
	my ($loc, $local_file);

	($clie_cmd, $clie_msg) = $self->recv_cmd;
		
		exit if ($clie_cmd eq $QUIT);
	
			if (($clie_cmd ne $GET) && ($clie_cmd ne $LIST)) {
				$self->send_cmd($UNRECOG_CMD,$unrecog_cmd_msg);
			} else {
				## the instance where a client command is equal to either $GET or $LIST
				if ($clie_cmd eq $GET) {
				$local_file = $clie_msg;
				$self->debug("Client has requested $directory/$local_file") if ($self->{_debug} eq 1);
				
					## first check...file name contains more than 0 chars
					$self->debug("Checking length of filename!") if ($self->{_debug} eq 1);
					if (length($local_file) > 0) {
					$self->debug("Check Successful") if ($self->{_debug} eq 1);

						## second check...first character is a '/' or presence of a '..'
						$self->debug("Checking for control characters\n") if ($self->{_debug} eq 1);
						if (($local_file =~ m/^\//)||($local_file =~ m/^\.\.?$/)) {
							$self->debug("Check Failed") if ($self->{_debug} eq 1); 
							$self->send_cmd($INVAL_NAME,$inval_name_msg);
							next;
						}
						$self->debug("Check Successful") if ($self->{_debug} eq 1);
						
						
							## third check...is a file
							$self->debug("Checking to see if $local_file is a file") if ($self->{_debug} eq 1);
							if (-f "$directory/$local_file") {
							$self->debug("Check Successful") if ($self->{_debug} eq 1); 
								
								## fourth check...exists and is readable
								if ((-e "$directory/$local_file") && (-r "$directory/$local_file")) {
									## determine size now
									$file_size = (stat("$directory/$local_file"))[7];
									## if here, all checks are successful
									$self->send_cmd($ACK_CMD, $file_size);
									## begin transfer process here...
							
									$self->debug("Preparing to transfer file...") if ($self->{_debug} eq 1);


									#my ($loc, $local_file);
        								local *FH;
        								my $localfd = ref($local_file) || ref(\$local_file) eq "GLOB";


									if($localfd) {
										$loc = $local_file;
									} else {
									  $loc = \*FH;
									  unless(sysopen($loc,"$directory/$local_file", O_RDONLY))
									  { 
										carp "Cannot open file";
									 	return undef;	
									  }
	
									}
	
									my ($bytes_wrote, $read, $wrote) = (0,0,0);
									while (1) {
										last if ($bytes_wrote eq $file_size);
										$read = sysread($loc,$data,$buffer);
										$wrote = syswrite($socket,$data,$buffer);
										unless ((defined($read)) && (defined($wrote))) {
											croak "Unable to read from file or write to client";
										}
										$bytes_wrote += $wrote;
									syswrite(STDOUT, "*");
									}
									$self->debug("\nWrote $bytes_wrote bytes of data to client\n") if ($self->{_debug} eq 1);
									close $loc
										or carp $! ? "Cannot close file: $!"
											   : "Exit status $? from close";
									#next;
									## reset file_size to be zero	
									($file_size) = (0);
	
								} else {
									$self->debug("Check Failed") if ($self->{_debug} eq 1); 
									$self->send_cmd($PERM_DENY,$perm_deny_msg);
									next;
								}
							} else {
								$self->debug("Check Failed") if ($self->{_debug} eq 1); 
								$self->send_cmd($FILE_NOT_FOUND,$file_not_found_msg);
								next;
							}
					} else {
						$self->debug("Check Failed") if ($self->{_debug} eq 1); 
						$self->send_cmd($INVAL_NAME,$inval_name_msg);
						next;
					}
				## end of if $GET
				} elsif ($clie_cmd eq $LIST) {
					## handle list command
					$self->debug("Client has requested a list: ") if ($self->{_debug} eq 1);
					my ($directory) = $self->{_directory};
					my ($str,$file);
					$str = "The files available for download are as follows:";
					opendir(DIR, $directory) or croak "Cannot open directory $directory: $!";		
					while (defined ($file = readdir(DIR))) {
						if(($file =~ m/^\./) or (-d "$directory/$file")) {
							next;
						} else {
							$str .= "*$file";
						}
					}
					$self->send_cmd($ACK_CMD,$str);
					$self->debug("Done") if ($self->{_debug} eq 1);
				} ## end of elsif $LIST 
			} ## end of inner else loop

		} while ($clie_cmd ne $QUIT);
	}

	sub _send_packet 
	{
		my ($self, $packet) = @_;
		my ($socket) = $self->{_socket};
	
		my ($plen) = length($packet);
			## current packet length
	
		croak "Error sending packet: packet > 255 bytes" if ($plen > 255);
	
		## add terminating null to packet
		$packet .= "\0";
		$plen++; ## for addition of null.

		## add the packet length 
		$packet = chr($plen).$packet;
		$plen++; ## for addition of chr($plen)

		my $wrote_length = syswrite($socket, $packet, $plen);
		
			## checking for errors w/ syswrite
			if (!defined($wrote_length)) {
				croak "Error sending packet: $!";
			} elsif ($wrote_length != $plen) {
				croak "Error sending packet: wrote $wrote_length of $plen: $!";
			} else {
				return 'ok';
			}
		
	}

	sub _recv_packet
	{
		my ($self) = @_;
		my ($socket) = $self->{_socket};
		my ($slen, $buffer, $ret);

		## this is a two step process
		## first, read in one byte of data
		## this will be the length of the packet data
		## then read only the amount of data as 
		## specified by the first byte
		
		$ret = sysread($socket,$slen,1,0);

		## troubleshooting sysread
		if(!defined($ret)) {
			croak "Error Receiving first byte: $!";
		} elsif (length($slen) != 1) {
			croak "Error Receiving first byte not eq 1: $!";
		} else {
			## convert char to integer
			$slen = ord($slen);

			while ($slen) {
				my ($pbuf);
				$ret = sysread($socket,$pbuf,$slen,0);
				if (!defined($ret)) {
					croak "Error Receiving, return not define: $!"
				} else {
					$slen -= length($pbuf);
					$buffer .= $pbuf;
				}
				## remove trailing null
				chop($buffer);
				return($buffer);
			}
		} # end of above else	
	}
1;

__END__

=head1 NAME

Net::FileShare - Object oriented interface for the creation of file sharing clients and servers.

=head1 EXAMPLES 

        ## example file sharing server
        #!/usr/bin/perl -w
        use strict;
        use Net::FileShare;
        my ($fh) = Net::FileShare->new(
                        _send_only => 1,
                        _directory => '/path/to/files/to/serve', ## avoid using a trailing / on path
                        _debug     => 1);
        $fh->server_connection;

        ## example interactive client
	#!/usr/bin/perl -w
        use strict;
        use Net::FileShare;
        my ($fh) = Net::FileShare->new(
                        _send_only => 0,
                        _directory => '/home/usr_id', ## avoid using a trailing / here as well
                        _debug     => 1);
        $fh->client_interactive("x.x.x.x","port");

	## example of automated client
	#!/usr/bin/perl -w
	use strict;
	use Net::FileShare;
	my ($fh) = Net::FileShare->new(
			_directory => '/home/usr_id'  ## again...avoid trailing /
				      );
	$fh->client_automated("x.x.x.x","port","get","some_file");


=head1 SYNOPSIS 

C<Net::FileShare> provides an object interface for creating file sharing servers and clients.

=head1 DESCRIPTION

This distribution represents a complete rewrite of the C<Net::FileShare> code base. Every aspect has been rewritten to improve upon methodology. If you're currently running the 1.X code base its serously suggested that you download this new 0.1X code and install. See the changes file contained within this distribution for the specifics on how the C<Net::FileShare> code has been changed/improved in the 0.1X distribution.  

=item new()

The C<Net::FileShare> new() method creates an object, which can then be used to construct either a server or client. There are three has values which can be used to construct the object. They are as follows: _send_only (1 for on, 0 for off), _directory (path to files to share or download directory), and _debug (1 for on, 0 for off). 
 For the construction of servers, _send_only and _directory are required values to set. Clients are only required to supply the _directory value.
 Note: avoid the use of a trailing slash when listing your path for the _directory option:
	/home/my_login_name	## good
	/home/my_login_name/	## bad
 The next version of this code will fix this problem. 

=item server_connection()

The server_connection sub impliments a forking filesharing server. Its first action is to establish a socket, then begin the process of accepting clients. Once a client connection is accepted, the connection is forked. If this is successful the server then initiates the handle_request sub, which interfaces with client.

=item client_automated()

This is an automated version of the interactive client session. It is a run once session. The user must supply either three or four parameters here. They are IP of server, port of server, command (either list or get), and an optional file name (if command = get). 
 See EXAMPLES above.

=item client_interactive()

This is the interactive client connection. It begins with a client connection to a server running the C<Net::FileShare> module. Once the client connection has been established, the client process will be forked. Once this occurs, the client the begins and interactive session where it can request either a list of files the server is offering, or a specific file. 
 The user must supply two variables here. Those are the IP of server and port of server. See EXAMPLES above.

=head1 COPYRIGHT

Copyright 2003, Gene Gallistel. All rights reserved.

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=head1 AUTHOR

Gene Gallistel, gravalo@uwm.edu, http://www.uwm.edu/~gravalo

=cut
