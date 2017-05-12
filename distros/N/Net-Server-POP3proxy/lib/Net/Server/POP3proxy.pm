package Net::Server::POP3proxy;

use strict;
use vars qw($VERSION);
$VERSION = '0.1';

use POSIX;
use IO::Socket;
use IO::Select;

# Constructor
# Parameters: Port, Error, Debug, Action
sub new {
    # no need to check subclassing ... not public
    my $proto = shift;

    # generate a clear hash for holding data
    my $self = {
        # default parameters
        Port    =>          110,
        Error   =>          sub { die ($_[0]); },
        Debug   =>          sub { print gmtime() . ": " . $_[0] . "\n"; },
        Action  =>          sub { },
        MaxSize =>          0,
        @_,

        # interal structures
        write_buffer        => {},
        read_buffer         => {},
        write_sockets       => new IO::Select,
        read_sockets        => new IO::Select,
        listening_socket    => undef,
        client_peers        => {},
        server_peers        => {},
        waiting_user        => {},
        reading_multiline   => {},
        snarfing            => {},
        command_queue       => {},
        write_disconnect    => {},       
    };

    # initialize class
    my $class = ref($proto) || $proto;
    $self = bless( $self, $class );

    # init the listening socket
    $self->init();

    $self;
}

# init the listening socket
sub init {
    my ($self) = shift;
    # create listening socket     
    $self->{listening_socket} = IO::Socket::INET->new(LocalPort => $self->{Port}, Listen => 5, Reuse => 1, Timeout => 5);
    $self->error("Cannot create socket: $!") unless $self->{listening_socket};
    
    $self->debug("Created listening socket on port " . $self->{Port});
    
    # add it to readable sockets
    $self->{read_sockets}->add($self->{listening_socket});    
}

sub canrecycle {
    my $self = shift;
    
    if ($self->{read_sockets}->count() <= 1 && $self->{write_sockets}->count() == 0) {
        return 1;
    } else {
        return 0;
    }
}

# this should be called in a while (1) loop to work through sockets
# main dispatcher
sub looper {
    my $self = shift;

    return 0 unless ($self->{read_sockets}->count() || $self->{write_sockets}->count());    
        
    # find out sockets to read and to write to
    my ($toread, $towrite) = IO::Select->select($self->{read_sockets}, $self->{write_sockets},undef, 5);    
    
    # first work on read sockets
    foreach my $socket ( @$toread ) {
        # check which type of socket we are working on:
        if ($socket == $self->{listening_socket}) {
            # initial communication
            $self->minipop3_connect($socket);
        } else {
            # followup connection
            if (defined $self->{client_peers}->{$socket}) {
                # its a client which already has a server assotiated
                $self->proxypop3_client2server($socket);
            } elsif (defined $self->{server_peers}->{$socket}) {
                # its a server communicating with the client              
                $self->proxypop3_server2client($socket);
            } else {
                # its a client communicating with minipop3
                $self->minipop3_client2server($socket);
            }
        }
        
        # cleanup        
        unless ($socket && $socket->connected()) {
            undef $socket;
        }
    }
    
    # next work on write sockets
    foreach my $socket ( @$towrite ) {
        # check if write buffer waits for something
        if ($self->{write_buffer}->{$socket}) {
            $self->write2socket($socket);
        }

        # cleanup        
        unless ($socket && $socket->connected()) {
            undef $socket;
        }
    }

    # cleanup
    undef $toread; undef $towrite;

    1;
}

# Basic write to socket function. Writes waiting data to a writing socket. 
sub write2socket {
    my ($self, $socket) = @_;
    
    return unless $self->{write_buffer}->{$socket};
    
    # write to socket
    my $wrote = syswrite($socket, $self->{write_buffer}->{$socket}, length($self->{write_buffer}->{$socket})) or do {
        # write failed
        $self->debug("write to " . $socket->peerhost() . " failed");
        
        # clear writing buffer on socket
        $self->{write_buffer}->{$socket} = "";
        
        # disconnect all assotiated stuff
        if (defined $self->{client_peers}->{$socket}) {
            # its a port of a client - so the client disconnects        
            $self->client_disconnect($socket);
        } elsif (defined $self->{server_peers}->{$socket}) {
            # its a port of a server - so a server is not reachable any more
            $self->server_disconnect($socket);
        } else {
            # no assosiated port so only mini disconnect
            $self->minipop3_quit($socket);
        }
    };
    
    # after a write - we have to flush the buffer (only if writte is buffer size)
    substr($self->{write_buffer}->{$socket},0,$wrote,"");    
    if (length ($self->{write_buffer}->{$socket}) == 0) {
        $self->{write_sockets}->remove($socket);

        undef $self->{write_buffer}->{$socket};

        # implicit disconnect after last write    
        if ($self->{write_disconnect}->{$socket}) {
            $self->debug("executing pending disconnect for " . $socket->peerhost() . ".");
            
            if (defined $self->{client_peers}->{$socket}) {
                # a client port - client disconnect                
                $self->client_disconnect($socket);
            } elsif (defined $self->{server_peers}->{$socket}) {
                # a server port - so server disconnect
                $self->server_disconnect($socket);
            } else {
                $self->minipop3_quit($socket);
            }
        }
        
    }
}

# Connection from a client to our proxy
sub minipop3_connect {
    my ($self, $socket) = @_;
    
    # accept socket
    my $new_sock = $socket->accept;
    $self->{read_sockets}->add($new_sock) if $new_sock;
    $self->error("Cannot accept new connection from client") unless $new_sock;

    $self->debug("Connection accepted from " . $new_sock->peerhost() . ".");

    # fill data
    $self->{write_buffer}->{$new_sock} = undef; $self->{read_buffer}->{$new_sock} = undef;
    $self->{write_disconnect}->{$new_sock} = 0;
    
    # write mini pop3 welcome
    $self->preparewrite($new_sock,"+OK welcome to maxbounce pop3 proxy\x0D\x0A");
}

sub minipop3_client2server {
    my ($self, $socket) = @_;
    
    $self->debug("Receiving data from client -> proxy server");
    
    # get read data    
    $self->doread($socket) or $self->minipop3_quit($socket);

    # check if buffer is enough to run action
    $self->minipop3_action($socket);  
}

sub minipop3_action {
    my ($self, $socket) = @_;
    
    return unless $self->{read_buffer}->{$socket};    
    
    if ($self->{read_buffer}->{$socket} =~ /\x0D\x0A?$/s) {
        my @workbuffer = split (/\x0D\x0A?/,$self->{read_buffer}->{$socket});
        undef $self->{read_buffer}->{$socket};

        # only an "enter"
        if (@workbuffer == 0) {
            $self->debug("client sent only empty line");
            $self->preparewrite($socket,"-ERR empty command\x0D\x0A");
        }
        
        # work the lines
        foreach my $line ( @workbuffer ) {
            # hanging x0A
            $line =~ s/^\x0A//;

            if ($line =~ /^USER\s+([^\%]+)\%(.+)$/i) {
                my ($remoteuser, $remotehost) = ($1,$2);
                $self->debug("Got USER command from client: pop3 host $remotehost, username $remoteuser");            
        
                # append port 110 if not included
                if ($remotehost !~ /:\d+$/) {
                    $remotehost .= ":110";
                }
        
                # open up a new socket to a pop server
                my $remote = IO::Socket::INET->new(PeerAddr => $remotehost);
                unless ($remote) {
                    # no connection possible
                    $self->debug("No connection to $remotehost");
                    $self->preparewrite($socket,"-ERR $remotehost is not reachable\x0D\x0A");
                } else {
                    $self->debug("Connection to $remotehost ok");
                    
                     
                    # fill up datas
                    $self->{read_sockets}->add($remote);
                    $self->{client_peers}->{$socket} = $remote;
                    $self->{server_peers}->{$remote} = $socket;
                    $self->{waiting_user}->{$remote} = $remoteuser;
                    $self->{write_buffer}->{$remote} = undef; $self->{read_buffer}->{$remote} = undef;
                    $self->{reading_multiline}->{$remote} = 0; $self->{snarfing}->{$remote} = 0;
                    $self->{command_queue}->{$socket} = [];
                    $self->{write_disconnect}->{$remote} = 0;
                }
            } elsif ($line =~ /^QUIT/i) {
                # quit request
                $self->debug("Proxy client issues QUIT");                
                $self->minipop3_quit($socket);
            } elsif ($line =~ /^SHUTDOWN/i) {
                # shutdown all
                $self->cleanup();
            } else {
                # wrong command
                $self->debug("Proxy client issues wrong command");
                $self->preparewrite($socket,"-ERR waiting for USER\x0D\x0A");
            }
        }
        
        undef @workbuffer;
    } else {
        $self->debug('... waiting for EOL');
    }
}

# close connection in minipop3 mode (not so ugly)
sub minipop3_quit {
    my ($self,$socket) = @_;
    
    $self->debug("Connection to " . $socket->peerhost() . " closed (minipop3).");
    $self->socketclose($socket);
}

# communication from a client to a server / Command checkup and catcher
sub proxypop3_client2server {
    my ($self,$socket) = @_;

    $self->debug("Receiving data from client -> pop server");
  
    $self->doread($socket) or $self->client_disconnect($socket);
    
    $self->proxypop3_client_action($socket);
}

# a client socket dies or needs to be disconnected
sub client_disconnect {
    my ($self,$socket) = @_;

    # is a server port assosiated ?    
    if (defined $self->{client_peers}->{$socket}) {
        # is data pending ?
        if ($self->{write_buffer}->{$self->{client_peers}->{$socket}}) {
            $self->debug("Initiating clients assosiated server disconnect after next write");
            $self->{write_disconnect}->{$self->{client_peers}->{$socket}} = 1;
        } else {
            $self->debug("Initiating clients assosiated server disconnect immediate");          

            $self->socketclose($self->{client_peers}->{$socket});
        }
    }
    
    $self->debug("Disconnecting client connection to " . $socket->peerhost() . ".");
    $self->socketclose($socket);
}

# handle read data from client and make command checkup
sub proxypop3_client_action {
    my ($self, $socket) = @_;
    
    # no action needed
    return unless $self->{read_buffer}->{$socket};
    
    # check if empty line
    if ($self->{read_buffer}->{$socket} =~ /\x0D\x0A?$/s) {
        my @workbuffer = split (/\x0D\x0A?/,$self->{read_buffer}->{$socket});
        $self->{read_buffer}->{$socket} = "";

        # empty line
        if (@workbuffer == 0) {
            $self->debug("Empty client command");            
            $self->preparewrite($socket,"-ERR empty command");
        } else {
            # only interested in one line command            
            my $line = $workbuffer[0];
            
            # hanging x0A
            $line =~ s/^\x0A//;
 
            # the plain command
            my ($command) = $line =~ /^(\S+)/;
            
            # disable AUTH requests
            if ($command and $command =~ /^AUTH$/i) {
                $self->preparewrite($socket,"-ERR Auth disabled\x0D\x0A");
                return;        
            }

            # we are in proxy mode already, do not retry authentication!
            if ($command and $command =~ /^USER/i) {
                $self->preparewrite($socket,"-ERR Only one authentication can be done. Please restart\x0D\x0A");
                return;            
            }
            
            # push command to stack
            push (@{$self->{command_queue}->{$self->{client_peers}->{$socket}}}, $command) if $command;
            
            $self->debug("Client issues command '$command'.");
            $self->preparewrite($self->{client_peers}->{$socket},"$line\x0D\x0A");
        }
    } else {
        # new line missing     
        $self->debug('Client communication needs a newline to finish');
    }
}

# a server is communicating with the client
sub proxypop3_server2client {
    my ($self,$socket) = @_;
    
    $self->debug("Receiving data from pop server -> client");
    
    $self->doread($socket) or $self->server_disconnect($socket);
    
    $self->proxypop3_server_action($socket); 
}

# all stuff if a server port disconnects
sub server_disconnect {
    my ($self,$socket) = @_;
    
    # is a client assosiated with this communication
    if (defined $self->{server_peers}->{$socket}) {
        if ($self->{write_buffer}->{$self->{server_peers}->{$socket}}) {
            $self->debug("Initiating server assosiated client disconnect after next write");
            $self->{write_disconnect}->{$self->{server_peers}->{$socket}}=1;
        } else {
            $self->debug("Initiating server assosiated client disconnect immediate");          

            $self->socketclose($self->{server_peers}->{$socket});
        }
    }
    
    $self->debug("Disconnecting server connection to " . $socket->peerhost() . ".");
    $self->socketclose($socket);
}

# work the server answers to see whats up in the mailbox and to catch mails
sub proxypop3_server_action {
    my ($self, $socket) = @_;

    return unless ($self->{read_buffer}->{$socket});

    # is it a full answer?    
    if ($self->{read_buffer}->{$socket} =~ /\x0D\x0A?$/s) {
        # split buffer
        my @workbuffer = split (/\x0D\x0A?/,$self->{read_buffer}->{$socket});
        # discard buffer        
        undef $self->{read_buffer}->{$socket};
            
        foreach my $line ( @workbuffer ) {
            # hanging x0A
            $line =~ s/^\x0A//;
            
            # response is a status reply and no multiline response            
            if (($line =~ /^(\+OK|-ERR)/i) && (! $self->{reading_multiline}->{$socket})) {
                $self->debug("command response");

                # do we need to make a silent connect to the server?            
                if ($self->{waiting_user}->{$socket}) {
                    # first hello
                    $self->debug("Remote server alive, trying authenticate with user " . $self->{waiting_user}->{$socket} . ".");
                    $self->preparewrite($socket,"USER " . $self->{waiting_user}->{$socket} . "\x0D\x0A");

                    undef $self->{waiting_user}->{$socket}; delete $self->{waiting_user}->{$socket};

                    # no interest in going on server replies 
                    last; 
                }
                
                 # Response to a command (hopefully!)
                my $command = shift @{$self->{command_queue}->{$socket}};
            
                # santity check
                if ($self->{snarfing}->{$socket}) {
                    $self->error("Sanity: multiline not ready - error in snarfing");
                }

                # positiv answer                
                if ((substr ($line, 0, 1) eq '+') && (defined $command)) {
                    # command TOP                    
                    if ($command =~ /^TOP$/i) {
                        $self->{snarfing}->{$socket} = 1;
                        next;
                    }
	  
                    # Command RETR (reply with original Status)
                    if ($command =~ /RETR/i) {
                        $self->{snarfing}->{$socket} = 2;
                        $self->preparewrite($self->{server_peers}->{$socket}, "+OK filtered message follows\x0D\x0A");
                        next;
                    }

                    # Command CAPA (reply with original Status=
                    if ($command =~ /CAPA/i) {
                        $self->{snarfing}->{$socket} = 3;
                        $self->preparewrite($self->{server_peers}->{$socket}, "$line\x0D\x0A");
                        next;
                    }
                 }
            } elsif ($line =~ /^\.$/) {
                $self->debug("end ML");
                # End of a multiline response

                $self->{reading_multiline}->{$socket} = 0;

                # we just catch a message
                if ($self->{snarfing}->{$socket}) {
                
                    # a RETR Request                    
                    if ($self->{snarfing}->{$socket} == 2) {
                        if (! defined ($self->{message}->{$socket})) {
                            $self->{message}->{$socket} = '';
                        }
                         
                        if (($self->{MaxSize} == 0) || (length ($self->{message}->{$socket}) < $self->{MaxSize})) {
                            $self->{message}->{$socket} = $self->{Action}($self->{message}->{$socket});
                        } else {
                            $self->debug("Message not filtered - too big");
                        }
                        
                        $self->debug("Returning RETR command / applying filter");
            
                        $self->preparewrite($self->{server_peers}->{$socket},$self->{message}->{$socket});
                    # TOP Command will be dropped ( problem because we modify messages )                    
                    } elsif ($self->{snarfing}->{$socket} == 1) {
                        $self->{message}->{$socket} = ''; $self->{snarfing}->{$socket} = 0;
                        
                        $self->debug("Discard TOP command reply");                        
                        $self->preparewrite($self->{server_peers}->{$socket},"-ERR no TOP allowed\x0D\x0A");
                        next;
                    # CAPA Reply
                    } elsif ($self->{snarfing}->{$socket} == 3) {
                        # Strips out the TOP response, if any.
                        $self->{message}->{$socket} =~ s/TOP\x0D\x0A//sig;
                        # Strips out the SASL response, if any.
                        $self->{message}->{$socket} =~ s/SASL\x0D\x0A//sig;
                        
                        $self->debug("Return modified CAPA reply");
                        $self->preparewrite($self->{server_peers}->{$socket},$self->{message}->{$socket});
                    } else {
                        $self->error("Sanity: Another Snarfing Action code");
                    }                
                    
                    # discard snarfing and message
                    undef $self->{message}->{$socket}; delete $self->{message}->{$socket};
                    $self->{snarfing}->{$socket} = 0;
                }
            } else {
                # $self->debug("ML");

                # it must be a multiline
                $self->{reading_multiline}->{$socket} = 1;
            }
    
            # if in multiline snarfing - store message
            if ($self->{snarfing}->{$socket}) {
                $self->{message}->{$socket} .= $line . "\x0D\x0A";
            } else {
                # pipeline it to the client
                $self->preparewrite($self->{server_peers}->{$socket}, "$line\x0D\x0A");
            }        
        }
        # free workbuffer
        undef @workbuffer;
    } else {
        # new line missing     
        $self->debug('Server communication needs a newline to finish');
    }
}

# Cleanup means to kill all existing ports
sub cleanup {
    my ($self, $force) = shift;
    
    if ($force) {
        $self->debug("Forced shutdown");
    }
    
    # gather all sockets    
    my @allwrite = $self->{write_sockets}->handles;
        
    # begin with the writing ones
    foreach my $socket ( @allwrite ) {
        unless ($force) {
            if (defined $self->{client_peers}->{$socket}) {
                $self->client_disconnect($socket);
            } elsif (defined $self->{server_peers}->{$socket}) {
                $self->server_disconnect($socket);
            } else {
                $self->minipop3_quit($socket);
            }
        } else {
            $self->socketclose($socket);            
        }
    }        

    # Read sockets
    my @allread = $self->{read_sockets}->handles;

    # now go to the reading ones
    foreach my $socket ( @allread ) {
        unless ($force) {        
            if (defined $self->{client_peers}->{$socket}) {
                $self->client_disconnect($socket);
            } elsif (defined $self->{server_peers}->{$socket}) {
                $self->server_disconnect($socket);
            } elsif ($socket == $self->{listening_socket}) {
                $self->debug("Closing listening socket");            
                $self->socketclose($socket);            
            } else {
                $self->minipop3_quit($socket);
            }
        } else {
            $self->socketclose($socket);            
        }
    }        
}

# put a write in the queue and enable writing
sub preparewrite {
    my ($self,$socket,$message) = @_;
    
    if (ref($message) eq "SCALAR") {
        $self->{write_buffer}->{$socket} .= $$message;
    } else {
        $self->{write_buffer}->{$socket} .= $message;
    }
    $self->{write_sockets}->add($socket) unless $self->{write_sockets}->exists($socket);
}

# get a block for reading 
sub doread {
    my ($self, $socket) = @_;
    
    $self->{read_buffer}->{$socket} = '' unless ($self->{read_buffer}->{$socket});
    return sysread($socket, $self->{read_buffer}->{$socket}, 4096, length($self->{read_buffer}->{$socket}));
}

# debugging
sub debug {
    my ($self, $msg) = @_;
    $self->{Debug}($msg);
}

# error
sub error {
    my ($self, $msg) = @_;
    
    $self->cleanup();
    $self->{Error}($msg);
}

# Sub will clean all data assosiated with a socket
sub socketclose {
    my ($self, $socket) = @_;

    return unless $socket;

    $self->{read_sockets}->remove($socket); $self->{write_sockets}->remove($socket);
    
    # clean all assosiated hashes
    do { undef $self->{server_peers}->{$socket}; delete $self->{server_peers}->{$socket} } if (exists $self->{server_peers}->{$socket});
    do { undef $self->{client_peers}->{$socket}; delete $self->{client_peers}->{$socket} } if (exists $self->{client_peers}->{$socket});
    do { undef $self->{read_buffer}->{$socket}; delete $self->{read_buffer}->{$socket} } if (exists $self->{read_buffer}->{$socket});
    do { undef $self->{write_buffer}->{$socket}; delete $self->{write_buffer}->{$socket} } if (exists $self->{write_buffer}->{$socket});
    do { undef $self->{reading_multiline}->{$socket}; delete $self->{reading_multiline}->{$socket} }  if (exists $self->{reading_multiline}->{$socket});
    do { undef $self->{command_queue}->{$socket}; delete $self->{command_queue}->{$socket} } if (exists $self->{command_queue}->{$socket});
    do { undef $self->{write_disconnect}->{$socket}; delete $self->{write_disconnect}->{$socket} } if (exists $self->{write_disconnect}->{$socket});
    do { undef $self->{snarfing}->{$socket}; delete $self->{snarfing}->{$socket}} if (exists $self->{snarfing}->{$socket});
    do { undef $self->{message}->{$socket}; delete $self->{message}->{$socket} } if (exists $self->{message}->{$socket});
    
    # close socket
    $socket->shutdown(2);
    $socket->close() if ($socket);
}

sub DESTROY {
    my $self = shift;
    
    $self->debug("Destroy");
    $self->cleanup(1);
}

# a positiv result - we are polite!
1;

__END__

=head1 NAME

Net::Server::POP3proxy - POP3 Proxy class for working with virus scanners and anti-spam software

=head1 SYNOPSIS

    use Net::Server::POP3proxy;

    # Constructors
    $popproxy = new Net::Server::POP3proxy(
        Action => sub { filterAction ($_[0]); },
        Error  => sub { die ($_[0]); },
        Debug  => sub { print STDERR ($_[0]); }
    ) or die ("Cannot init POP3 proxy server");
        
    while ($popproxy->looper()) {
        # noop
    }

=head1 DESCRIPTION

This module implements a POP3 proxy server to enable you to call user
defined actions uppon fetching a mail from the POP3 Server.

The destination server is taken from the username, the client connects
to the pop3 proxy in the way remoteuser%remote.host:port.

Multiple clients can connect to the POP proxy at a time.

=head1 CONSTRUCTOR

=over 4

=item new ( [ Port => [port] ], [ Action => [sub] ], [ Error => [sub] ],
            [ Debug => [sub] ], [ MaxSize => [maximumsize] ] )

This is the constructor for a new Net::POP3proxy object. No paramater
is required.

C<Port> is the TCP port the proxy listens on the local machine interface.
The default port is 110.

C<MaxSize> is the maximum message size im bytes, the action is called. E.g.
no junk can be greater than 512k or much less! The default is 0 which means
all messages are filtered.

C<Action> is an anonymous function which is called, if a message arrives. It
must return the message or the modified message. We use a normal scalar value
for this, though we had problems with memory leaks using references under
Windows. The default is to do nothing.

C<Error> is an anonymous function which is called, if an error occures.
It is assumed, that this function does stop the execution immediate. So use
a die or so here. The parameter is the error message. The default is to do
a die.

C<Debug> is an anonymous function which is called, if a debug message occures.
It is assumed, that this function does NOT stop the execution immediate. The
default is to print the message.

=back

=head1 METHODS

The concept is to do a loop. So we only descript the looping function and the
cleanup functions.

=over 4

=item looper ( )

Waits for connections and handles actions and errors.

=item cleanup ( [ FORCE ] )

Closes all sockets. If C<FORCE> is ommitted or 0 only sockets containing with no
waiting data are closed. If C<FORCE> is 1 then all is closed. For example in
case of no fatal error you can end by doing this:
    
        $popproxy->cleanup();

        # run last buffers - with a grace of 50
        # communications for the rest buffer
        
        my $gracecounter = 50;
        while ($popproxy->looper() && $gracecounter ) { $gracecounter--; }

        $popproxy->cleanup(1);    

=back

=head1 POP3 commands

For you to understand, we try to give an example of a POP3 communication with
the proxy:
    
    telnet localhost 110
    +OK welcome to perl pop3 proxy
    USER test@mail.test.it
    
    ... connection is created to mail.test.it port 110
    
    +OK
    
    ... now communication is done with mail.test.it
    
Using other ports:

    telnet localhost 110
    +OK welcome to perl pop3 proxy
    USER test@mail.test.it:1110
    
    ... connection is created to mail.test.it port 1110
    
    +OK
    
    ... now communication is done with mail.test.it
    
Special C<shutdown> command

    telnet localhost 110
    +OK welcome to perl pop3 proxy
    shutdown
    
    ... looper returns false and all sockets are closed
      
=back

=head1 NOTES

We work a lot with destroys and try to undefine a lot of data. This is because this
was designed to work as a Windows Service using PerlSVC from ActiveState. So dont be
confused if you read the code.

POP3 connections are done by socket communication.

This was only tested on Windows till now.

=head1 AUTHOR

Martin Boeck <martin.boeck@comnex.net>

=head1 COPYRIGHT

Copyright (c) 2005 Martin Boeck. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
