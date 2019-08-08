#!/usr/bin/perl

package Net::BGP::Process;

use strict;
use vars qw( $VERSION );

## Inheritance and Versioning ##

$VERSION = '0.17';

## Module Imports ##

use Carp;
use IO::Select;
use IO::Socket;
use Net::BGP::Peer qw( BGP_PORT TRUE FALSE );

## Socket Constants ##

sub LISTEN_QUEUE_SIZE { 5 }

## Public Methods ##

sub new
{
    my $class = shift();
    my ($arg, $value);

    my $this = {
        _read_fh       => IO::Select->new(),
        _write_fh      => IO::Select->new(),
        _error_fh      => IO::Select->new(),
        _peer_list     => {},
        _peer_addr     => {},
        _trans_sock     => {},
        _trans_sock_fh  => {},
        _trans_sock_map=> {},
        _listen_socket => undef,
        _listen_port   => BGP_PORT,
        _listen_addr   => INADDR_ANY,
    };

    while ( defined($arg = shift()) ) {
        $value = shift();
        if ( $arg =~ /port/i ) {
            $this->{_listen_port} = $value;
        }
	elsif ( $arg =~ /listenaddr/i ) {
            $this->{_listen_addr} = inet_aton($value);
        }
	else {
	    croak "Unknown argument '$arg'";
	}
    }

    bless($this, $class);

    return ( $this );
}

sub add_peer
{
    my ($this, $peer) = @_;

    $this->{_peer_addr}->{$peer->this_id}->{$peer->peer_id} = $peer if $peer->is_listener;;
    $this->{_peer_list}->{$peer} = $peer;
}

sub remove_peer
{
    my ($this, $peer) = @_;
    if ( defined($this->{_peer_list}->{$peer}) ) {
        $peer->stop();
	foreach my $trans ($peer->transports)
         {
          $this->_update_select($trans);
         };
        delete $this->{_peer_addr}->{$peer->this_id}->{$peer->peer_id};
        delete $this->{_peer_list}->{$peer};
    }
}

sub event_loop
{
    my $this = shift();
    my ($time, $last_time, $delta, $min, $min_timer);
    my ($timer);

    my $sigorig = $SIG{'PIPE'};
    unless (defined $SIG{'PIPE'}) {
      $SIG{'PIPE'} = 'IGNORE';
    }

    # Poll each peer and create listen socket if any is a listener
    foreach my $peer ( values(%{$this->{_peer_list}}) ) {
        if ( $peer->is_listener() ) {
            $this->_init_listen_socket();
            last;
        }
    }

    while ( scalar(keys(%{$this->{_peer_list}})) ) {

        # Process timeouts, events, etc.
        $min_timer = 2147483647;
        $time = time();

        if ( ! defined($last_time) ) {
            $last_time = $time;
        }

        $delta = $time - $last_time;
        $last_time = $time;

        foreach my $peer ( values(%{$this->{_peer_list}}) ) {

	    foreach my $trans ($peer->transports) {
              $trans->_handle_pending_events();
            }

            $min = $peer->_update_timers($delta);
            if ( $min < $min_timer ) {
                $min_timer = $min;
            }

	    foreach my $trans ($peer->transports)
             {
              $this->_update_select($trans);
             };
        }

        last if scalar(keys(%{$this->{_peer_list}})) == 0;

	$! = 0;

        my @ready = IO::Select->select($this->{_read_fh}, $this->{_write_fh}, $this->{_error_fh}, $min_timer);

        if ( @ready ) {

            # dispatch ready to reads
            foreach my $ready ( @{$ready[0]} ) {
                if ( $ready == $this->{_listen_socket} ) {
                    $this->_handle_accept();
                }
                else {
                    my $trans = $this->{_trans_sock_map}->{$ready};
                    $trans->_handle_socket_read_ready();
                }
            }

            # dispatch ready to writes
            foreach my $ready ( @{$ready[1]} ) {
                my $trans = $this->{_trans_sock_map}->{$ready};
                $trans->_handle_socket_write_ready();
            }

            # dispatch exception conditions
            foreach my $ready ( @{$ready[2]} ) {
                my $trans = $this->{_trans_sock_map}->{$ready};
                $trans->_handle_socket_error_condition();
            }
        } else {
            if ($!{EBADF}) {
                # One of the sockets is bad
                foreach my $fh ( $this->{_error_fh}->handles ) {
                    if (!$fh->opened) {
                        my $trans = $this->{_trans_sock_map}->{$fh};
                        # We seem to have a transport with a dud socket
                        # Update the select statement - not sure if this
                        # is right though - Damian Ivereigh 29/09/2016
                        if ($trans) {
                            $this->_update_select($trans);
                        } else {
                            warn "Cannot find trans object\n";
                        }
                    }
                }
            }
        }
    }

    $this->_cleanup();

    delete $SIG{'PIPE'};
    $SIG{'PIPE'} = $sigorig if defined $sigorig;
}

## Private Methods ##

sub _add_trans_sock
{
    my ($this, $trans, $sock) = @_;

    $this->{_trans_sock}->{$trans} = $sock;
    $this->{_trans_sock_fh}->{$trans} = $sock->fileno();
    $this->{_trans_sock_map}->{$sock} = $trans;
}

sub _remove_trans_sock
{
    my ($this, $trans) = @_;

    delete $this->{_trans_sock_map}->{$this->{_trans_sock}->{$trans}};
    delete $this->{_trans_sock}->{$trans};
    delete $this->{_trans_sock_fh}->{$trans};
}

sub _init_listen_socket
{
    my $this = shift();
    my ($socket, $proto, $rv, $sock_addr);

    eval {
        $socket = IO::Socket->new( Domain => AF_INET );
        if ( ! defined($socket) ) {
            die("IO::Socket construction failed");
        }

        $rv = $socket->blocking(FALSE);
        if ( ! defined($rv) ) {
            die("set socket non-blocking failed");
        }

        $proto = getprotobyname('tcp');
        $rv = $socket->socket(PF_INET, SOCK_STREAM, $proto);
        if ( ! defined($rv) ) {
            die("socket() failed");
        }

        $socket->sockopt(SO_REUSEADDR, TRUE);

        $sock_addr = sockaddr_in($this->{_listen_port},
                                 $this->{_listen_addr});
        $rv = $socket->bind($sock_addr);
        if ( ! defined($rv) ) {
            die("bind() failed");
        }

        $rv = $socket->listen(LISTEN_QUEUE_SIZE);
        if ( ! defined($rv) ) {
            die("listen() failed");
        }

        $this->{_read_fh}->add($socket);
        $this->{_write_fh}->add($socket);
        $this->{_error_fh}->add($socket);
        $this->{_listen_socket} = $socket;
    };
  croak $@ if $@;
}

sub _cleanup
{
    my $this = shift();
    my $socket;

    if ( defined($this->{_listen_socket}) ) {
        $socket = $this->{_listen_socket};
        $this->{_read_fh}->remove($socket);
        $this->{_write_fh}->remove($socket);
        $this->{_error_fh}->remove($socket);

        $socket->close();
        $this->{_listen_socket} = undef;
    }
}

sub _handle_accept
{
    my $this = shift;

    my ($socket, $peer_addr) = $this->{_listen_socket}->accept();
    my ($port, $addr) = sockaddr_in($peer_addr);
    
    my $ip_addr = inet_ntoa($addr);
    my $ip_local = inet_ntoa($socket->sockaddr);

    my $peer = $this->{_peer_addr}->{$ip_local}->{$ip_addr};
    if ( ! defined($peer)) {
	warn "Ignored incoming connection from unknown peer ($ip_addr => $ip_local)\n";
        $socket->close();
    }
    elsif ( ! $peer->is_listener() ) {
	warn "Ignored incoming connection for non-listning peer\n";
        $socket->close();
    }
    else {
        my $trans = $peer->transport;

        # Can't reuse the existing Net::BGP::Peer object unless it is a passive session
        if (! $peer->is_passive() ) {

            # If there is a sibling, we need to kill it, assuming that there
            # is a collision here.
            #
            # This can happen in a BGP misconfiguration where no OPEN gets
            # sent by the other end (for instance, the other end is expecting
            # a smaller bigger TTL, but still listens for BGP and sends SYNACK
            # packets back - like Mikrotik)
            if (defined $trans->{_sibling}) {
                $trans->{_sibling}->_handle_collision_selfdestuct;
            }

            # Now we can clone
	    $trans = $trans->_clone;
        }

        $trans->_set_socket($socket);
    }
}

sub _update_select
{
    my ($this, $trans) = @_;

    my $trans_socket = $trans->_get_socket();
    my $this_socket = $this->{_trans_sock}->{$trans};

    if ( defined($trans_socket) && ! defined($this_socket) ) {
        $this->_add_trans_sock($trans, $trans_socket);
        $this->{_read_fh}->add($trans_socket);
        $this->{_write_fh}->add($trans_socket);
        $this->{_error_fh}->add($trans_socket);
    }
    elsif ( defined($this_socket) && ! defined($trans_socket) ) {
        $this->{_read_fh}->remove($this->{_trans_sock_fh}->{$trans});
        $this->{_write_fh}->remove($this->{_trans_sock_fh}->{$trans});
        $this->{_error_fh}->remove($this->{_trans_sock_fh}->{$trans});
        $this->_remove_trans_sock($trans);
    }
    elsif ( defined($this_socket) && defined($trans_socket) ) {
        if ( $trans->_is_connected() && $this->{_write_fh}->exists($this_socket) ) {
            $this->{_write_fh}->remove($this_socket);
        }
    }
}

## POD ##

=pod

=head1 NAME

Net::BGP::Process - Class encapsulating BGP session multiplexing functionality

=head1 SYNOPSIS

    use Net::BGP::Process;

    $bgp = Net::BGP::Process->new( Port => $port );

    $bgp->add_peer($peer);
    $bgp->remove_peer($peer);
    $bgp->event_loop();

=head1 DESCRIPTION

This module encapsulates the functionality necessary to multiplex multiple
BGP peering sessions. While individual B<Net::BGP::Peer> objects contain
the state of each peering session, it is the B<Net::BGP::Process> object
which monitors each peer's transport-layer connection and timers and signals
the peer whenever messages are available for processing or timers expire.
A B<Net::BGP::Process> object must be instantiated, even if a program only
intends to establish a session with a single peer.

=head1 METHODS

I<new()> - create a new Net::BGP::Process object

    $bgp = Net::BGP::Process->new( Port => $port, ListenAddr => '1.2.3.4' );

This is the constructor for Net::BGP::Process objects. It returns a
reference to the newly created object. The following named parameters may
be passed to the constructor.

=head2 Port

This parameter sets the TCP port the BGP process listens on. It may be
omitted, in which case it defaults to the well-known BGP port TCP/179.
If the program cannot run with root priviliges, it is necessary to set
this parameter to a value greater than or equal to 1024. Note that some
BGP implementations may not allow the specification of an alternate port
and may be unable to establish a connection to the B<Net::BGP::Process>.

=head2 ListenAddr

This parameter sets the IP address the BGP process listens on.  Defaults
to INADDR_ANY.

I<add_peer()> - add a new peer to the BGP process

    $bgp->add_peer($peer);

Each B<Net::BGP::Peer> object, which corresponds to a distinct peering
session, must be registered with the B<Net::BGP::Process> object via this
method. It is typically called immediately after a new peer object is created
to add the peer to the BGP process. The method accepts a single parameter,
which is a reference to a B<Net::BGP::Peer> object.

I<remove_peer()> - remove a peer from the BGP process

    $bgp->remove_peer($peer);

This method should be called if a peer should no longer be managed by the
BGP process, for example, if the session is broken or closed and will not
be re-established. The method accepts a single parameter, which is a
reference to a Net::BGP::Peer object which has previously been registered
with the process object with the add_peer() method.

I<event_loop()> - start the process event loop

    $bgp->event_loop();

This method must called after all peers are instantiated and added to the
BGP process and any other necessary initialization has occured. Once it
is called, it takes over program control flow, and control will
only return to user code when one of the event callback functions is
invoked upon receipt of a BGP protocol message or a user
established timer expires (see L<Net::BGP::Peer> for details
on how to establish timers and callback functions). The method takes
no parameters. It will only return when there are no Net::BGP::Peer
objects remaining under its management, which can only occur if they
are explicitly removed with the remove_peer() method (perhaps called
in one of the callback or timer functions).

=head1 SEE ALSO

Net::BGP, Net::BGP::Peer, Net::BGP::Update, Net::BGP::Notification

=head1 AUTHOR

Stephen J. Scheck <sscheck@cpan.org>

=cut

## End Package Net::BGP::Process ##

1;
