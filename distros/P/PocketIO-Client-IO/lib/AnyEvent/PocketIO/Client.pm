package AnyEvent::PocketIO::Client;

use strict;
use warnings;
use Carp ();
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use PocketIO::Handle;
use PocketIO::Connection;

my %RESERVED_EVENT = map { $_ => 1 }
                        qw/message connect disconnect open close error retry reconnect/;

our $VERSION = '0.01';


sub new {
    my $this  = shift;
    my $class = ref $this || $this;
    bless {
        handshake_timeout => 10,
        open_timeout      => 10,
        @_,
    }, $class;
}

sub handle { $_[0]->{ handle }; }

sub conn { $_[0]->{ conn }; }

sub socket { $_[0]->conn->socket; }

sub _start_timer {
    my ( $self, $timer_name, $cb ) = @_;
    my $after = $self->{ "${timer_name}_timeout" } || 0;
    $self->{ "${timer_name}_timer" } = AnyEvent->timer( after => $after, cb => $cb );
}

sub _stop_timer {
    my ( $self, $timer_name ) = @_;
    delete $self->{ "${timer_name}_timer" };
}

sub handshake {
    my ( $self, $host, $port, $cb ) = @_;

    $cb ||= sub {};

    tcp_connect( $host, $port,
        sub {
            my ($fh) = @_ or return $cb->( { code => 500, message => $! }, $self );

            @{$self}{qw/host port/} = ( $host, $port );

            my $socket = AnyEvent::Handle->new(
                fh => $fh,
                on_error => sub {
                    $self->disconnect(join(',', "error!:", $_[1], $_[2] ));
                },
            );

            $socket->push_write("GET /socket.io/1/ HTTP/1.1\nHost: $host:$port\n\n");

            my $read = 0; # handshake is finished?

            $self->_start_timer( 'handshake', sub {
                $socket->fh->close;
                $read++;
                $self->_stop_timer( 'handshake' );
                $cb->( { code => 500, message => 'Handshake timeout.' }, $self );
            } );

            $socket->on_read( sub {
                return unless length $_[0]->rbuf;
                return if $read;

                my ( $status_line ) = $_[0]->rbuf =~ /^(.+)\015\012/;
                my ( $code ) = $status_line =~ m{^HTTP/[.01]+ (\d+) };
                my $error;

                if ( $code && $code != 200 ) {
                    $_[0]->rbuf =~ /\015\012\015\012(.*)/sm;
                    $error = { code => $code, message => $1 };
                    $read++;
                    $cb->( $error, $self );
                    return;
                }

                my ( $line ) = $_[0]->rbuf =~ /\015\012\015\012([^:]+:[^:]+:[^:]+:[^:]+)/sm;

                unless ( defined $line ) {
                    return;
                }

                $self->_stop_timer( 'handshake' );

                my ( $sid, $hb_timeout, $con_timeout, $transports ) = split/:/, $line;
                $transports = [split/,/, $transports];
                $self->{ acceptable_transports } = $transports;
                $self->{ session_id } = $sid;
                $socket->destroy;
                $read++;
                $cb->( $error, $self, $sid, $hb_timeout, $con_timeout, $transports );
            } );
    } );

}

sub is_opened {
    $_[0]->{ is_opened };
}

sub opened {
    $_[0]->{ is_opened } = 1;
    $_[0]->_stop_timer( 'open' );
}

sub reg_event {
    my ( $self, $name, $cb ) = @_;
    return Carp::carp('reg_event() must take a code reference.') if $cb && ref($cb) ne 'CODE';
    return Carp::carp("$name is reserved event.") if exists $RESERVED_EVENT{ $name }; 

    if ( $self->is_opened ) {
        $self->conn->socket->on( $name => $cb );
    }
    else {
        $self->{ not_yet_reg_event }->{ $name } = $cb;
    }
}

sub on {
    my ( $self, $event ) = @_;
    my $name = "on_$event";

    if ( @_ > 2 ) {
        $self->{ $name } = $_[2];
        return $self;
    }

    return $self->{ $name } ||= sub {};
}

sub disconnect {
    my ( $self ) = @_;

    return unless $self->is_opened;

    $self->{ is_opened } = 0;
    $self->on('disconnect')->();
    $self->conn->close;
    $self->conn->disconnected;
    delete $self->{ conn };
}

sub emit {
    my $self = shift;
    unless ( $self->is_opened ) {
        Carp::carp('Not yet connected.');
        return;
    }
    $self->conn->socket->emit( @_ );
}

sub send {
    my $self = shift;
    unless ( $self->is_opened ) {
        Carp::carp('Not yet connected.');
        return;
    }
    $self->conn->socket->send( @_ );
}

sub connect {
    my ( $self, $endpoint ) = @_;
    $self->conn->_stop_timer('close');
    my $message = PocketIO::Message->new(type => 'connect');
    $self->conn->write($message);
    $self->conn->_start_timer('close');
    #$self->conn->emit('connect');    
    $self->on('connect')->( $endpoint );
}

sub transport {
    $_[0]->{ transport } = $_[0] if @_ > 1;
    $_[0]->{ transport };
}

sub open {
    my ( $self, $trans, $cb ) = @_;
    my $host = $self->{ host };
    my $port = $self->{ port };
    my $sid  = $self->{ session_id };

    if ( $trans && ref $trans eq 'CODE' ) {
        $cb = $trans; $trans = undef;
    }

    unless ( $sid ) {
        my $message = "Tried open but no session id.";
        $cb ? return $cb->({ code => 500, message => $message }, $self)
            : Carp::croak($message)
    }

    $trans = 'websocket'; # TODO ||= $self->{ acceptable_transports }->[0];
    $self->{ transport } = $self->_build_transport( $trans );

    tcp_connect( $host, $port,
        sub {
            my ($fh) = @_
                or ($cb ? return $cb->({ code => 500, message => $! }, $self)
                        : Carp::croak( $! )
                   );

            $self->{ handle } = PocketIO::Handle->new(
               fh => $fh, heartbeat_timeout => $self->{ heartbeat_timeout }
            );

            $self->{ conn } = PocketIO::Connection->new();

            $self->_start_timer( 'open', sub {
                local $Carp::CarpLevel = 3;
                #$self->handle->fh->close; # cases "Out of memory"?
                $self->_stop_timer( 'open' );
                $cb ? $cb->( { code => 500, message => 'Open timeout.' }, $self )
                    : Carp::croak('Open timeout.');
            } );

            $self->on('open')->( $self );

            return $self->transport->open( $self, $fh, $host, $port, $sid, $cb );
        }
    );
}

sub _run_open_cb {
    my ( $self, $cb ) = @_;
    my $conn = $self->conn;

    $cb->( undef, $self );

    for my $name ( keys %{ $self->{ not_yet_reg_event } } ) {
        $conn->socket->on(
            $name => delete $self->{ not_yet_reg_event }->{ $name }
        );
    }

    # default setting
    for my $name ( qw/connect disconnect error/ ) {
        $conn->socket->on( $name => sub {} ) unless $conn->socket->on( $name );
    }
    #$conn->socket->on('connect')->( $conn->socket );
}


my %Transport = (
    websocket => 'WebSocket',
);

sub _build_transport {
    my ( $self, $transport_id ) = @_;
    my $class = 'AnyEvent::PocketIO::Client::Transport::' . $Transport{ lc $transport_id };  

    eval qq{ use $class };
    if ($@) { Carp::croak $@; }

    $class->new();
}

1;
__END__

=pod

=head1 NAME

AnyEvent::PocketIO::Client - Socket.IO client

=head1 SYNOPSIS

    # This APIs will be changed.

    use AnyEvent;
    use AnyEvent::PocketIO::Client;
    
    my $client = AnyEvent::PocketIO::Client->new;    

    $client->on('message' => sub {
        print STDERR "get message : $_[1]\n";
    });

    # first handshake, then open.
    
    my $cv = AnyEvent->condvar;

    $client->handshake( $server, $port, sub {
        my ( $error, $self, $sesid, $hb_timeout, $con_timeout, $trans ) = @_;

        $client->open( 'websocket' => sub {

            $self->reg_event('foo' => sub {
                # ...
            });

            $cv->send;
        } );

    } );
    
    $cv->wait;
    
    # ... loop, timer, etc.
    
    $client->disconnect;
    
    
    #
    # OR socket.io client interface
    #

    use PocketIO::Client::IO;
    my $socket = PocketIO::Client::IO->connect("http://localhost:3000/");

    my $cv = AnyEvent->condvar;
    my $w  = AnyEvent->timer( after => 5, cb => $cv );

    $socket->on( 'message', sub {
        say $_[1];
    } );

    $socket->on( 'connect', sub {
        $socket->send('Parumon!');
        $socket->emit('hello', "perl");
    } );

    $cv->wait;


=head1 DESCRIPTION

Socket.IO client using L<PocketIO> and L<AnyEvent>.

This is B<beta> version. APIs will be changed.

Currently acceptable transport id is B<websocket> only.

=head1 METHODS

=head2 new

    $client = AnyEvent::PocketIO::Client->new( %opts )

Returns a new object. it can take the follow options

=over

=item handshake_timeout

=item open_timeout

=back

=head2 handshake

    $client->handshake( $host, $port, $cb );

The handshake routine. it executes a call back C<$cb> that takes an
error (if any, otherwise C<undef>), client itself, the session id, heartbeat timeout, connection timeout
and list reference of transports.

    sub {
        my ( $error, $client, $sesid, $hb_timeout, $conn_timeout, $trans ) = @_;
        if ( $error ) {
            say "code:", $error->{ code };
            say "message:", $error->{ message };
        }
        # ...        
    }

=head2 open

    $client->open( $transport_id, $cb );

After C<handshake> success, makes a connection to the server.
Currently C<$transport_id> (case-insensitive) is C<websocket> only.

When the connection is made, $cb is executed.
$cb takes error object and client object.

    sub {
        my ( $error, $client ) = @_;

        if ( $error ) {
            say "code:", $error->{ code };
            say "message:", $error->{ message };
        }

        # ...        
    }

=head2 is_opened

    $boolean = $client->is_opend

=head2 connect

    $client->connect( $endpoint )

This method is for B<message type connect>.
If you want to make a connection to the server in real,
call C<open> method.

=head2 disconnect

    $client->disconnect( $endpoint )

Sends B<message type disconnect> to the server and close the socket handle.

=head2 reg_event

    $client->reg_event( 'name' => $subref )

Register an event triggered by server's emit.

You should call this method after C<open>ed.

=head2 emit

    $client->emit( 'event_name', @args )

=head2 send

    $client->send( 'message' )

=head2 conn

    $conn = $client->conn; # PocketIO::Connection

=head2 on

    $client->on( 'messsage_type' => $cb );

Acceptable types are 'open', 'connect', 'disconnect', 'heartbeat' and 'message'.

=head2 tranport

    my $transport = $client->transport();

=head1 WRAPPER CLASS

Simple client module L<PocketIO::Client::IO>.

    use PocketIO::Client::IO;
    my $socket = PocketIO::Client::IO->connect("http://localhost:3000/");

    my $cv = AnyEvent->condvar;
    my $w  = AnyEvent->timer( after => 5, cb => $cv );

    $socket->on( 'message', sub {
        say $_[1];
    } );

    $socket->on( 'connect', sub {
        $socket->send('Parumon!');
        $socket->emit('hello', "perl");
    } );

    $cv->wait;

=head1 TODO

Currently this module supports C<websocket> only. Patches welcome!

=head1 SEE ALSO

L<AnyEvent>, L<PocketIO>, L<PcketIO::Client::IO>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut




