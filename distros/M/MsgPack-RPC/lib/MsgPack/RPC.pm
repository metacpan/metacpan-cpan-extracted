package MsgPack::RPC;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: MessagePack RPC client
$MsgPack::RPC::VERSION = '2.0.3';

use strict;
use warnings;

use Moose;

use IO::Async::Loop;
use Promises qw/ deferred /, backend => [  'IO::Async' ];

use MsgPack::Decoder;
use MsgPack::Encoder;
use MsgPack::RPC::Message;
use MsgPack::RPC::Message::Request;
use MsgPack::RPC::Event::Write;
use MsgPack::RPC::Message::Response;
use MsgPack::RPC::Message::Notification;
use MsgPack::RPC::Event::Receive;

use Scalar::Util qw/ blessed /;

use experimental 'signatures', 'switch';

with 'Beam::Emitter';

has io => (
    is       => 'ro',
    trigger  => \&_set_io_accessors,
);

has stream => (
    is => 'rw',
    handles => [ 'write' ],
);

has loop => (
    is => 'ro',
    lazy => 1,
    default => sub { IO::Async::Loop->new },
    handles => [ 'run' ],
);

sub bin_2_hex {
    join '', map { sprintf "%#x", ord } split '', shift;
}

has log => (
    is => 'ro',
    lazy => 1,
    default => sub {
        require Log::Any;
        Log::Any->get_logger;
    },
);

sub _buffer_read ( $rpc, $stream, $buffref, $eof ) {
    $rpc->log->tracef( 'reading %s', bin_2_hex($$buffref) );

    $rpc->read( $$buffref );

    $$buffref = '';

    return 0;
}

sub _set_inet_io ( $self, $host, $port ) {

    $self->loop->connect(
        host      => $host,
        port      => $port,
        socktype  => 'stream',
        on_stream => sub {
            my $stream = shift;
            $stream->configure(
                on_read => sub { $self->_buffer_read(@_) },
            );
            $self->loop->add($stream);
            $self->on( 'write', sub {
                    my $event = shift;
                    $stream->write( $event->encoded );
            });
        },
        on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
        on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
    );
}

sub _set_socket_io ( $self, $socket ) {

    $self->loop->connect(
        addr => {
            family   => 'unix',
            socktype => 'stream',
            path     => $socket,
        },
        on_stream => sub {
            my $stream = shift;
            $self->stream($stream);
            $stream->configure(
                on_read => sub { $self->_buffer_read(@_) },
            );
            $self->loop->add($stream);
            $self->on( 'write', sub {
                    my $event = shift;
                    $stream->write( $event->encoded );
            });
        },
        on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
        on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
    );
}

sub _set_fh_io ( $self, $in_fh, $out_fh ) {

    $out_fh->autoflush(1);

    require IO::Async::Stream;
    my $stream = IO::Async::Stream->new(
        read_handle => $in_fh,
        on_read  => sub { $self->_buffer_read(@_) },
    );

    $self->loop->add($stream);
    $self->on( 'write', sub {
        $self->log->debugf( 'uh? %s', $_[0] );
        my $event = shift;
        $out_fh->syswrite( $event->encoded );
    });
}

sub _set_io_accessors($self,$io,@) {

    return $self->_set_fh_io( @$io ) if ref $io eq 'ARRAY';

    return $self->_set_inet_io(split ':', $io)
        if $io =~ /:/;

    return $self->_set_socket_io($io);

}

has decoder => (
    isa => 'MsgPack::Decoder',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $decoder = MsgPack::Decoder->new( emitter => 1 );

        $decoder->on( decoded => sub {
            my $event = shift;
            $self->receive($_) for $event->payload_list;
        });

        return $decoder;
    },
    handles => [ 'read' ],
);

sub receive ( $self, $message ) {
    my @message = @$message;

    my $m;
    given ( $message[0] ) {
        $m = MsgPack::RPC::Message::Request->new( id => $message[1], method => $message[2], params => $message[3] ) when 0;
        $m = MsgPack::RPC::Message::Response->new( id => $message[1], error => $message[2], result => $message[3] ) when 1;
        $m = MsgPack::RPC::Message::Notification->new( method => $message[1], params => $message[2] ) when 2;
    }

    $self->emit( 'receive', class => 'MsgPack::RPC::Event::Receive', message => $m );

    # if a response, trigger the callback
    if( $m->is_response ) {
        if ( my $callback = delete $self->response_callbacks->{$m->id} ) {
            if( $m->is_error ) {
                $callback->{deferred}->reject($m->error);
            }
            else {
                $callback->{deferred}->resolve($m->result);
            }
        }
    }
    else {
        $self->emit( $m->method, class => 'MsgPack::RPC::Event::Receive', message => $m );
    }
}


has "response_callbacks" => (
    is => 'ro',
    lazy => 1,
    default => sub {
        {};
    },
);

has timeout => (
    is => 'ro',
    default => 300,
);

sub add_response_callback {
    my( $self, $id ) = @_;
    my $deferred = deferred;
    $self->response_callbacks->{$id} = {
        timestamp => time,
        deferred => $deferred,
    };

    require IO::Async::Timer::Countdown;
    my $timeout = IO::Async::Timer::Countdown->new(
        delay => $self->timeout,
        on_expire => sub {
            delete $self->response_callbacks->{$id};
            $deferred->reject('timeout');
        }
    );

    $self->loop->add($timeout->start);

    $deferred->finally(sub{ $self->loop->remove($timeout) });
}

sub send_request($self,$method,$args=[],$id=++$MsgPack::RPC::MSG_ID) {
    my $request = MsgPack::RPC::Message::Request->new(
        method => $method,
        params => $args,
    );

    my $callback = $self->add_response_callback($request->id);

    $self->send($request);

    return $callback->{deferred};
}

sub send_response($self,$id,$args) {
    $self->send(
        MsgPack::RPC::Message::Response->new(
            id => $id,
            result => $args,
        )
    );
}

sub send_response_error($self,$id,$args) {
    $self->send(
        MsgPack::RPC::Message::Response->new(
            id => $id,
            error => $args,
        )
    );
}

sub send_notification ($self,$method,$args=[]) {
    $self->send( MsgPack::RPC::Message::Notification->new(
        method => $method, params => $args,
    ));
}


sub send($self,$struct) {
    my $type = blessed $struct ? 'message' : 'payload';
    $self->emit( 'write', class => 'MsgPack::RPC::Event::Write', $type => $struct );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::RPC - MessagePack RPC client

=head1 VERSION

version 2.0.3

=head1 SYNOPSIS

    use MsgPack::RPC;

    my $rpc = MsgPack::RPC->new( io => '127.0.0.1:6666' );

    $rpc->notify( 'something' => [ 'with', 'args' ] );

    $rpc->request(
        request_method => [ 'some', 'args' ]
    )->on_done(sub{
        print "replied with: ", @_;
    });

    $rpc->loop;

=head1 DESCRIPTION

C<MsgPack::RPC> implements a MessagePack RPC client following
the protocol described at L<https://github.com/msgpack-rpc/msgpack-rpc/blob/master/spec.md>.

=head1 METHODS

=head2 new( %args )

=over

=item io( $socket )

=item io( [ $in_fh, $out_fh ] )

Required. Defines which IO on which the MessagePack messages will be received and sent.

The IO can be a local socket (e.g., C</tmp/rpc.socket> ), a network socket (e.g., C<127.0.0.1:6543>),
or a pair of filehandles.

=back

=head2 io()

Returns the IO descriptor(s) used by the object.

=head2 request( $method, $args, $id )

Sends the request. The C<$id> is optional, and will be automatically
assigned from an internal self-incrementing list if not given.

Returns a promise that will be fulfilled once a response is received. The response can be either a success
or a failure, and in both case the fulfilled promise will be given whatever values are passed in the response.

    $rpc->request( 'ls', [ '/home', '/tmp' ] )
        ->on_done(sub{ say for @_ })
        ->on_fail(sub{ die "couldn't read directories: ", @_ });

=head2 notify( $method, $args )

Sends a notification.

=head2 subscribe( $event_name, \&callback )

    # 'ping' is a request
    $rpc->subscribe( ping => sub($msg) {
        $msg->response->done('pong');
    });

    # 'log' is a notification
    $rpc->subscribe( log => sub($msg) {
        print {$fh} @{$msg->args};
    });

Register a callback for the given event. If a notification or a request matching the
event
is received, the callback will be called. The callback will be passed either a L<MsgPack::RPC::Message> (if triggered by
a notification) or
L<MsgPack::RPC::Message::Request> object.

Events can have any number of callbacks assigned to them.

The subscription system is implemented using the L<Beam::Emitter> role.

=head2 loop( $end_condition )

Reads and process messages from the incoming stream, endlessly if not be given an optional C<$end_condition>.
The end condition can be given a number of messages to read, or a promise that will end the loop once
fulfilled.

    # loop until we get a response from our request

    my $response = $rpc->request('add', [1,2] );

    $response->on_done(sub{ print "sum is ", @_ });

    $rpc->loop($response);


    # loop 100 times
    $rpc->loop(100);

=head1 SEE ALSO

=over

=item L<MsgPack::RPC::Message>

=item L<MsgPack::RPC::Message::Request>

=item L<MsgPack::Encoder>

=item L<MsgPack::Decoder>

=item L<Data::MessagePack> (alternative to C<MsgPack::Encoder> and C<MsgPack::Decoder>.

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
