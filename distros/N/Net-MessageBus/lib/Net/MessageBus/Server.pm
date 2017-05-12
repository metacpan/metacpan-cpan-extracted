package Net::MessageBus::Server;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::MessageBus::Server - Pure Perl message bus server

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

use base qw(Net::MessageBus::Base);

use JSON;
use IO::Select;
use IO::Socket::INET;

use Net::MessageBus::Message;

#handle gracefully the death of child ssh processes
use POSIX ":sys_wait_h";

$| = 1;

=head1 SYNOPSIS

This module creates a new Net::MessageBus server running on the specified address/port

Usage :

    use Net::MessageBus::Server;

    my $MBServer = Net::MessageBus::Server->new(
                        address => '127.0.0.1',
                        port    => '15000',
                        logger  => $logger,
                        authenticate => \&authenticate_method,
                    );
                    
    $MBServer->start();
    
    or
    
    $MBServer->daemon() || die "Fork to start Net::MessageBus::Server in background failed!"
    ...
    if ( $MBServer->is_running() ) {
        print "Server is alive";
    }
    ...
    $MBServer->stop(); #if started as a daemon.
    

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new server object.
It does not automatically start the server, you have to start it using the
start() method.
    
Arguments :
    
=over 4

=item * address = 
    The address on which the server should bind , 127.0.0.1 by dafault

=item * port =
    The port on which the server should listen , 4500 by default
            
=item * logger
    Any object that supports the fallowing methods : debug, info, warn,error
            
=item * authenticate = 
    A code ref to a method that returns true if the authentication is
    successfull and false otherwise

=back

B<Example>
    
    my $MBServer = Net::MessageBus::Server->new(
                        address => '127.0.0.1',
                        port    => '15000',
                        logger  => $logger,
                        authenticate => \&authenticate_method,
                    );
    

B<Example authentication method> :

    sub authenticate_method {
        my ($username, $password, $client_ip) = @_;
        
        return 1 if ($username eq "john" && $password eq "1234");
        return 0;
    }


=cut
sub new {
    my $class = shift;
    
    my %params;
    if ((ref($_[0]) || '') eq "HASH") {
        %params = %{$_[0]};
    }
    else {
        %params = @_;
    }
    
    my $self = {
                address => $params{address} || '127.0.0.1',
                port    => $params{port} || '4500',
                logger  => $params{logger} || Net::MessageBus::Base::create_default_logger(),
                authenticate => $params{autenticate} || sub {return 1},
                };
    
    $self->{subscriptions} = {
                              all => [],
                              groups => {},
                              senders => {},
                            };
    
    $self->{authenticated} = {};
    
    bless $self, $class;
    
    return $self;
}


=head2 start

    Starts the server

=cut
sub start {
    my $self = shift;
    
    $self->{server_socket} = $self->create_server_socket();
    
    my $server_sel = IO::Select->new($self->{server_socket});
    
    $self->{run} = 1;
    
    while ($self->{run} == 1) {

        my @exceptions = $server_sel->has_exception(0);
        foreach my $broken_socket (@exceptions) {
             eval {
                 $server_sel->remove($broken_socket);
                 close($broken_socket);
             };
        }
     
        my @ready = $server_sel->can_read();
 
        next unless scalar(@ready);
 
        foreach my $fh (@ready) {
            
            if( $fh == $self->{server_socket} ) {
                # Accept the incoming socket.
                my $new = $fh->accept;
                
                next unless $new; #in case the ssl connection failed
                
                my $straddr = $self->get_peer_address($new);
                
                $self->logger->info("Accepted from : $straddr\n");
                
                $server_sel->add($new);
                
            } else {
                # Process socket
                local $\ = "\n";
                local $/ = "\n";
                
                my $text = readline($fh);
                
                my $straddr = $self->get_peer_address($fh);

                if ($text) {
                    
                    chomp($text);
                    
                    $self->{client_socket} = $fh;

                    $self->logger->debug("Request from $straddr : '$text'");
                    
                    my $request;
                    eval {
                        $request = from_json($text);
                    };
                    
                    if ($@) {
                        print $fh to_json({status => 0, status_message => $@ });
                    }
                    elsif ($request->{type} eq "message") {
                        
                        print $fh to_json({status => 1});
                        
                        my $message = Net::MessageBus::Message->new($request->{payload});
                        
                        $self->send_message($message);
                    }
                    elsif ($request->{type} eq "authenticate") {
                        
                        my %data = %{$request->{payload}};
                        
                        my $auth = $self->{authenticate}->(
                                                @data{qw/username password/},
                                                $self->get_peer_address($fh)
                                                );
                        
                        $self->{authenticated}->{$fh} = $auth;
                        
                        print $fh to_json({status => $auth});
                    }
                    elsif ($request->{type} eq "subscribe") {
                        
                        $self->subscribe_client($request->{payload});

                        print $fh to_json({status => 1});
                    }
                    else {
                        print $fh to_json({status => 0, status_message => 'Invalid request!'});
                    }
            
                                    
                }
                else {
                   $self->logger->info("Peear $straddr closed connection\n");
                   
                   $self->unsubscribe_client($fh);
                   delete $self->{authenticated}->{$fh};
                   
                   $server_sel->remove($fh);
                   close ($fh);
                }
            }
        }
    }
}

=head2 daemon

Starts the server in background

=cut
sub daemon {
    my $self = shift;
    
    if ( defined $self->{pid} && kill(0,$self->{pid}) ) {
        $self->logger->error('An instance of the server is already running!');
    }
    
    $SIG{CHLD} = sub {
    
        # don't change $! and $? outside handler
        local ( $!, $? );
        
        while ( my $pid = waitpid( -1, WNOHANG ) > 0 ) {
           #Wait for the child processes to exit 
        }
        return 1;
    };
    
    my $pid;
    
    if ( $pid = fork() ) {
        $self->{pid} = $pid;
    }
    else {
        $SIG{INT} = $SIG{HUP} = sub {
                                    $self->{run} = 0;
                                    $self->{server_socket}->close();
                                };
        $self->start();
        exit(0);
    }
    
    return 1;
}

=head2 stop

Stops a previously started daemon
    
=cut
sub stop {
    my $self = shift;
    
    if (! defined $self->{pid} || ! kill(0,$self->{pid}) ) {
        $self->logger->error('No Net::MessageBus::Server is running (pid : '.$self->{pid}.')!');
        return 0;
    }
    
	if ($^O =~ /Win/i ) { 
		#signal 15 not delivered while in IO wait on Windows so we have to take drastic measures
		kill 9, $self->{pid};
	}
	else {
    	kill 15, $self->{pid};
	}
    
    sleep 1;
        
    if ( kill(0,$self->{pid}) ) {
        $self->logger->error('Failed to stop the Net::MessageBus::Server (pid : '.$self->{pid}.')! ');
        return 0;
    }
    
    delete $self->{pid};
    
    return 1;
}


=head2 is_running

Returns true if the server process is running
    
=cut
sub is_running {
    my $self = shift;
    
    if (! defined $self->{pid} || ! kill(0,$self->{pid}) ) {
        return 0;
    }
    
    return 1;
}

=head1 Private methods

=head2 create_server_socket

Starts the TCP socket that to which the clients will connect

=cut

sub create_server_socket {
    my $self = shift;
    
    my $server_sock= IO::Socket::INET->new(
                                LocalHost => $self->{address},
                                LocalPort => $self->{port},
                                Proto     => 'tcp',
                                Listen    => 10,
                                ReuseAddr => 1,
                                Blocking  => 1,
                    ) || die "Cannot listen on ".$self->{address}.
                              ":".$self->{port}.", Error: $!";
                              
    $self->logger->info("$0  server v$VERSION - Listening on ".
                  $self->{address}.":".$self->{port} );                              
    
    return $server_sock;
    
}


=head2 get_peer_address

Returns the ip address for the given connection
    
=cut    
sub get_peer_address {
    my ($self, $fh) = @_;

    my $straddr = 'unknown';
    
    eval {
        my $sockaddr = getpeername($fh);
        
        my ($port, $iaddr) = sockaddr_in($sockaddr);
        $straddr = inet_ntoa($iaddr);
    };
        
    return $straddr;
}

=head2 subscribe_client

Adds the client to the subscription list which he specified
    
=cut
sub subscribe_client {
    my $self = shift;
    my $data = shift;
    
    if (defined $data->{all}) {
        $self->{subscriptions}->{all} ||= [];
        push @{$self->{subscriptions}->{all}}, $self->{client_socket};
    }
    elsif (defined $data->{group}) {
        $self->{subscriptions}->{groups}->{$data->{group}} ||= [];
        push @{$self->{subscriptions}->{groups}->{$data->{group}}}, $self->{client_socket};
    }
    elsif (defined $data->{sender}) {
        $self->{subscriptions}->{senders}->{$data->{sender}} ||= [];
        push @{$self->{subscriptions}->{senders}->{$data->{sender}}}, $self->{client_socket};
    }
    elsif (defined $data->{type}) {
        $self->{subscriptions}->{types}->{$data->{type}} ||= [];
        push @{$self->{subscriptions}->{types}->{$data->{type}}}, $self->{client_socket};
    }
    elsif (defined $data->{unsubscribe}) {
        $self->unsubscribe_client($self->{client_socket});
    }
    else {
        return 0;
    }
    
    return 1;
}


=head2 unsubscribe_client

Removes the given socket from all subscription lists
    
=cut
sub unsubscribe_client {
    my $self = shift;
    my $fh = shift;
    
    $self->{subscriptions}->{all} = [ grep { $_ != $fh } @{$self->{subscriptions}->{all}} ];
    
    foreach my $group (keys %{$self->{subscriptions}->{groups}}) {
        $self->{subscriptions}->{groups}->{$group} = [ grep { $_ != $fh } @{$self->{subscriptions}->{groups}->{$group}} ];
    }
    foreach my $sender (keys %{$self->{subscriptions}->{senders}}) {
        $self->{subscriptions}->{senders}->{$sender} = [ grep { $_ != $fh } @{$self->{subscriptions}->{senders}->{$sender}} ];
    }
    foreach my $type (keys %{$self->{subscriptions}->{types}}) {
        $self->{subscriptions}->{types}->{$type} = [ grep { $_ != $fh } @{$self->{subscriptions}->{types}->{$type}} ];
    }
}

=head2 clients_registered_for_message 

Returns a list containing all the file handles registered to receive the given message

=cut
sub clients_registered_for_message {
    my $self = shift;
    my $message = shift;
    
    my @handles = ();
    push @handles, @{ $self->{subscriptions}->{all} || [] };
    push @handles, @{ $self->{subscriptions}->{groups}->{$message->group()} || [] };
    push @handles, @{ $self->{subscriptions}->{senders}->{$message->sender()} || [] };
    push @handles, @{ $self->{subscriptions}->{types}->{$message->type() || ''} || [] };
    
    my %seen = ();
    @handles = grep { $_ != $self->{client_socket} }
               grep { $self->{authenticated}->{$_} }
               grep { ! $seen{$_} ++ } @handles;
                   
    return @handles;
}

=head2 send_message

Sends the given message to the clients that subscribed to the group or sender of the messages

=cut
sub send_message {
    my $self = shift;
    my $message = shift;
    
    my @recipients = $self->clients_registered_for_message($message);
    
    local $\ = "\n";
    
    foreach my $client ( @recipients ) {
        eval {
            print $client to_json({ type => 'message' , payload => $message->serialize() });
        };
        if ($@) {
            $self->logger->error('Error sending message to client!');
        }
    }
}

=head1 AUTHOR

Horea Gligan, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-MessageBus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-MessageBus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::MessageBus::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-MessageBus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-MessageBus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-MessageBus>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-MessageBus/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Horea Gligan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::MessageBus::Server
