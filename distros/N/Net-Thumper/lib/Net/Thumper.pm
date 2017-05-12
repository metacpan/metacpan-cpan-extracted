package Net::Thumper;
{
  $Net::Thumper::VERSION = '0.03';
}

=head1 NAME

Net::Thumper - a rudimentary Pure Perl AMQP client

=head1 SYNOPSIS

 my $amqp = Net::Thumper->new(
    debug => 0,
    server => 'rabbitmq-host',
    amqp_definition => 'amqp0-8.xml',
 );

 # Connect
 $amqp->connect();
 $amqp->open_channel();
 $amqp->declare_queue('foo');

 # Publish
 $amqp->publish('', 'foo', $payload, {}, { reply_to => 'foo', correlation_id => '1' });

 # Get
 my $msg = $amqp->get('foo');

 # Consume
 my $consumer_tag = $amqp->consume('foo');
 my $msg = $amqp->get('foo');
 $amqp->cancel($consumer_tag);

 # Disconnect
 $amqp->disconnect();
 
=head1 DESCRIPTION

This class is a rudimentary AMQP client written in Pure Perl. It has been tested
with recent versions of RabbitMQ.

There are a few limitations:

* No concept of 'channels' is exposed, so only one logical channel is possible

* Some parts of the AMQP spec not exposed

* API isn't the cleanest is some places - could be tidied up

While this module mostly works for my purpose, it might be restrictive in some
places. Still, the fundamentals are reasonably solid (the low-level communication)
so it could probably be fairly easily modified for other purposes. 

Patches welcome :)

=cut

use Moose;
use Data::Dumper;

use Net::AMQP;
use IO::Socket::INET;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Socket qw(IPPROTO_TCP TCP_NODELAY);

$SIG{PIPE} = "IGNORE";

# Class variable to indicate whether the AMQP spec has been loaded.
#  (Only needs to be done once)
my $spec_loaded = 0;

=head1 CONSTRUCTOR

=head2 new(debug => $bool, server => $host, port => $port, amqp_definition => $path_to_amqp_xml, debug_hook => \&_debug_hook)

Creates a new Net::Thumper instance. Parameters are:

* server (required) - the server to connect to

* port - server port, defaults to 5672

* amqp_definition (required) - path to the AMQP XML definition (as available from the amqp.org website)

* debug - boolean to indicate whether debugging information should be output. Defaults to false

* debug_hook - optional subroutine reference to call when outputting debug info. If not supplied, output will go to STDERR  

=cut

has 'socket' => (
    is => 'rw',
    init_arg => undef,
    lazy_build => 1,
);

has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'debug_hook' => (
    is => 'rw',
);

has 'server' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
);

has 'port' => (
    is => 'ro',
    isa => 'Int',
    default => 5672
);

has 'amqp_definition' => (
    is => 'ro',
    isa => 'Str',
);

has 'receive_cache' => (
    is => 'rw',
    isa => 'ArrayRef',
    init_arg => undef,
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        'receive_cache_is_empty' => 'is_empty',
        'receive_cache_shift'    => 'shift',
        'receive_cache_push'     => 'push',
    },
);

sub _build_socket {
    my $self = shift;   
    
    my $socket;
    
    {
        $socket = IO::Socket::INET->new(
            PeerAddr => $self->server,
            PeerPort => $self->port,
            Proto    => 'tcp',
            Timeout  => 1,
        );
        
        if (! defined $socket) {
            my $error = $!;
            if ($error eq 'Interrupted system call') {
                redo;
            }
    
            die "Could not open socket: $error\n" unless $socket;
        }
    }
    
    $socket->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1);
        
    return $socket;
}

sub BUILD {
    my $self = shift;
    
    if ($self->amqp_definition && ! $spec_loaded) {
        Net::AMQP::Protocol->load_xml_spec($self->amqp_definition);
        $spec_loaded = 1;
    }
       
}

=head1 METHODS

=head2 connect( login => 'login', password => 'password' )

Connects to the server. Additionally sends all handshake frames necessary to 
start a connection.

Accepts two optional parameters, 'login' and 'password', which both default
to 'guest'.

=cut

sub connect {
    my $self = shift;
    my %params = @_;

    my $greeting = Net::AMQP::Protocol->header;
    $self->_write_data($greeting);
    
    my ($start) = $self->_read_frames(); 
    
    try {
        $self->_assert_frame_is($start, 'Net::AMQP::Protocol::Connection::Start');        
    }
    catch {
        die "Failed opening connection: " . $_;
    };     
    
    # TODO: set params properly
    my $start_frame = Net::AMQP::Protocol::Connection::StartOk->new(
        client_properties => {
            platform    => 'Perl',
            product     => 'Net-Thumper',
            version     => 0.0.1,
        },
        mechanism => 'AMQPLAIN',
        response => {
            LOGIN    => $params{login}    // 'guest',
            PASSWORD => $params{password} // 'guest',
        },
        locale => 'en_US',
    );
    
    $self->_write_frame($start_frame, 0);
    
    my ($tune_info) = $self->_read_frames();
    
    try {
        $self->_assert_frame_is($tune_info, 'Net::AMQP::Protocol::Connection::Tune');        
    }
    catch {
        die "Failed opening connection: " . $_;
    };    
        
    my $tune_ok = Net::AMQP::Protocol::Connection::TuneOk->new(
        channel_max => $tune_info->method_frame->channel_max,
        frame_max   => $tune_info->method_frame->frame_max,
        heartbeat   => $tune_info->method_frame->heartbeat,
    );
    
    $self->_write_frame($tune_ok, 0);
        
    my $connection_open = Net::AMQP::Protocol::Connection::Open->new(
        virtual_host => '/',
        capabilities => '',
        insist       => 1,
    );
    $self->_write_frame($connection_open, 0);
    
    my ($open_ok) = $self->_read_frames();    
    
    try {
        $self->_assert_frame_is($open_ok, 'Net::AMQP::Protocol::Connection::OpenOk');        
    }
    catch {
        die "Failed opening connection: " . $_;
    };
}

=head2 open_channel()

Open a channel. This is hard-coded to channel 1.

=cut

sub open_channel {
    my $self = shift;
    
    my $channel_open = Net::AMQP::Protocol::Channel::Open->new(
        channel => 1,
    );
    
    $self->_write_frame($channel_open);
    
    my ($open_ok) = $self->_read_frames();
    
    try {
        $self->_assert_frame_is($open_ok, 'Net::AMQP::Protocol::Channel::OpenOk');        
    }
    catch {
        die "Failed opening channel: " . $_;
    };
}

=head2 declare_queue($queue, %params)

Declare a queue. The optional %params contains options for the queue declaration.

=cut

sub declare_queue {
    my $self = shift;
    my $queue = shift;
    my %args = @_;
    
    my $declare_queue = Net::AMQP::Protocol::Queue::Declare->new(
        passive     => 0,
        durable     => 0,
        exclusive   => 0,
        auto_delete => 0,
        no_ack      => 1,
        %args,
        queue       => $queue,
        ticket      => 0,
        nowait      => 0,
    );
    
    $self->_write_frame($declare_queue);
    
    my ($declare_ok) = $self->_read_frames();    
        
    try {
        $self->_assert_frame_is($declare_ok, 'Net::AMQP::Protocol::Queue::DeclareOk');        
    }
    catch {
        die "Failed declaring queue: " . $_;
    };   
}

=head2 bind_queue($queue, $exchange, $routing_key, %params)

Bind a queue to an exchange using the routing key. 
The optional %params contains options for the bind

=cut

sub bind_queue {
    my $self = shift;
    my $queue = shift;
    my $exchange = shift;
    my $routing_key = shift;
    my %args = @_;
    
    my $declare_queue = Net::AMQP::Protocol::Queue::Bind->new(
        %args,
        queue       => $queue,
        exchange    => $exchange,
        routing_key => $routing_key,
        ticket      => 0,
        nowait      => 0,
    );
    
    $self->_write_frame($declare_queue);
    
    my ($declare_ok) = $self->_read_frames();    
        
    try {
        $self->_assert_frame_is($declare_ok, 'Net::AMQP::Protocol::Queue::BindOk');        
    }
    catch {
        die "Failed binding queue: " . $_;
    };   
}

=head2 declare_exchange($exchange, $type, %params)

Declare an exchange

=cut

sub declare_exchange {
    my $self = shift;
    my $exchange = shift;
    my $type = shift;
    my %args = @_;
    
    my $declare_queue = Net::AMQP::Protocol::Exchange::Declare->new(
        exchange => $exchange,
        type => $type,        
        passive     => 0,
        durable     => 0,
        auto_delete => 0,
        internal    => 0,
        %args,        
        ticket      => 0,
        nowait      => 0,
    );
    
    $self->_write_frame($declare_queue);
    
    my ($declare_ok) = $self->_read_frames();    
        
    try {
        $self->_assert_frame_is($declare_ok, 'Net::AMQP::Protocol::Exchange::DeclareOk');        
    }
    catch {
        die "Failed declaring exchange: " . $_;
    };   
}

=head2 publish($exchange, $routing_key, $body, $params, $props)

Publish a message via $exchange with $routing_key. Message contents are 
passed in $body. $params is a hashref of args to the publish request
(such as the mandatory and immediate flags), $props is a hashref of
header parameters (such as correlation_id and reply_to)

=cut

sub publish {
    my $self = shift;
    my $exchange = shift;
    my $routing_key = shift;
    my $body = shift;
    my $args = shift // {};
    my $props = shift // {}; 
    
    my $publish = Net::AMQP::Protocol::Basic::Publish->new(
        exchange  => $exchange,
        mandatory => 0,
        immediate => 0,
        routing_key => $routing_key,
        ticket    => 0,
        %$args,
    );
    
    my $header = Net::AMQP::Frame::Header->new(
        weight       => 0,
        body_size    => length($body),
        header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
            content_type     => 'application/octet-stream',
            content_encoding => undef,
            headers          => {},
            delivery_mode    => 1,
            priority         => 1,
            correlation_id   => undef,
            expiration       => undef,
            message_id       => undef,
            timestamp        => time,
            type             => undef,
            user_id          => undef,
            app_id           => undef,
            cluster_id       => undef,
            %$props
        ),
    );
   
    $self->_write_frame($publish);
    $self->_write_frame($header);

    # We split the body into frames of 30000 characters.
    # TODO: this size should really be based on the max_frame_size set
    #  in the Tune/TuneOk frames during connection
    my @chunks = unpack '(a30000)*', $body;
    
    foreach my $chunk (@chunks) {
        my $body_frame = Net::AMQP::Frame::Body->new(payload => $chunk);
        $self->_write_frame($body_frame);
    }
}

=head2 get($queue, %params)

Get a message from $queue. Return a hashref with the message details, or undef
if there is no message. This is essentially a poll of a given queue. %params is
an optional hash containing parameters to the Get request.

The message returned in a hashref with the following keys:

* body - the body of the message

* reply_to - the reply_to header of the message

* correlation_id - the correlation_id of the message

* delivery_tag - used in acking messages.

=cut

sub get {
    my $self = shift;
    my $queue = shift;
    my %args = @_;
        
    my $get = Net::AMQP::Protocol::Basic::Get->new(
        no_ack => 1,
        queue => $queue,
        %args,
        ticket => 0,           
    );
    
    $self->_write_frame($get);
    
    my ($get_ok) = $self->_read_frames();
    
    return unless $get_ok;
 
    if ($get_ok->method_frame->isa('Net::AMQP::Protocol::Basic::GetEmpty')) {
        return;
    }
    
    try {
        $self->_assert_frame_is($get_ok, 'Net::AMQP::Protocol::Basic::GetOk');        
    }
    catch {
        die "Failed getting message: " . $_;
    };
    
    my ($header, @bodies) = $self->_read_resp();
    
    return $self->_create_resp($get_ok, $header, @bodies);
}

=head2 consume($queue, %params)

Indicate that a given queue should be consumed from. %params contains 
params to be passed to the Consume request.

Returns the consumer tag. Once the client is consuming from a queue,
receive() can be called to get any messages.

=cut

sub consume {
    my $self = shift;
    my $queue = shift;
    my %args = @_;
    
    my $consume = Net::AMQP::Protocol::Basic::Consume->new(
        consumer_tag => '',
        no_local     => 0,
        no_ack       => 1,
        exclusive    => 0,
        queue => $queue,
        %args, # queue
        ticket       => 0,
        nowait       => 0,
    );
    
    $self->_write_frame($consume);
    
    my ($consume_ok) = $self->_read_frames(); 
    
    try {
        $self->_assert_frame_is($consume_ok, 'Net::AMQP::Protocol::Basic::ConsumeOk');        
    }
    catch {
        die "Failed getting message: " . $_;
    };
    
    $self->{consuming} = 1;
    
    return $consume_ok->method_frame->{consumer_tag};
}

=head2 receive($timeout)

Receive a message from a queue that has previously been consumed from. Wait for
up to $timeout seconds before giving up and returning undef.

The message returned is of the same format as that returned from get()

=cut

sub receive {
    my $self = shift;
    my $timeout = shift;

    $self->_read_frames($timeout, 1) if $self->receive_cache_is_empty;
        
    my $resp = $self->receive_cache_shift;
           
    return unless $resp;
    
    return $self->_create_resp($resp->{deliver}, $resp->{header}, @{ $resp->{bodies} });
       
}

# Strip out any receive frames, and add them to the cache
sub _strip_receive_frames {
    my $self = shift;
    my $timeout = shift;
    my $expecting_receive = shift;
    my $frame = shift;
    
    # Only do something if we're consuming
    return $frame unless $self->{consuming};
    
    my @messages;
    
    my @other_frames;
    
    while (1) {
        my $deliver = $frame;
                    
        try {
            $self->_assert_frame_is($deliver, 'Net::AMQP::Protocol::Basic::Deliver');
        }
        catch {            
            undef $deliver;            
        };
        
        last unless $deliver;
        
        my ($header, @bodies) = $self->_read_resp();
        
        push @messages, {
            deliver => $deliver, 
            header => $header, 
            bodies => \@bodies
        };
        
        # See if there's a new frame to read, unless we were
        #  expecting a receive, in which case there may not be anything
        #  more.
        if ($expecting_receive) {
            last;
        }
        else {
            ($frame) = $self->_read_frames($timeout);
        }
    }
    
    $self->receive_cache_push(@messages);

    return $frame;
}

=head2 cancel($consumer_tag, %params)

Cancel consuming a queue. $consumer_tag is the tag returned from
the original consume() request.

=cut

sub cancel {
    my $self = shift;
    my $consumer_tag = shift;
    my %args = @_;
    
    my $consume = Net::AMQP::Protocol::Basic::Cancel->new(
        consumer_tag => $consumer_tag,
        %args,
        nowait       => 0,
    );
    
    $self->_write_frame($consume);
    
    my ($consume_ok) = $self->_read_frames(); 
    
    try {
        $self->_assert_frame_is($consume_ok, 'Net::AMQP::Protocol::Basic::CancelOk');        
    }
    catch {
        die "Failed getting message: " . $_;
    };    
}

=head2 disconnect()

Disconnect from the server.

=cut

sub disconnect {
    my $self = shift; 
    
    my $close = Net::AMQP::Protocol::Connection::Close->new();      
    
    $self->_write_frame($close, 0);
    
    my ($close_ok) = $self->_read_frames(); 
    
    try {
        $self->_assert_frame_is($close_ok, 'Net::AMQP::Protocol::Connection::CloseOk');        
    }
    catch {
        die "Failed getting message: " . $_;
    };
    
    $self->socket->close();
}

=head2 is_connected()

Return true if we appear to be connected to the server. This just checks
that the TCP socket appears to be connected, so the application may actually
have disconnected.

=cut

sub is_connected {
    my $self = shift;
    
    return $self->socket->connected ? 1 : 0;   
}

sub _read_resp {
    my $self = shift;
    
    my ($header) = $self->_read_frames();
    
    my $read_length = 0;
    my @bodies;

    while ($read_length < $header->body_size()) {
        my ($body) = $self->_read_frames();

        $read_length += length($body->payload);

        push @bodies, $body;
    }
    
    return ($header, @bodies);
    
}

sub _create_resp {
    my $self = shift;
    my ($control, $header, @bodies) = @_;

    return unless $control && $header && @bodies;
    
    my $data;
    foreach my $body (@bodies) {
        $data .= $body->payload;   
    }
    
    my $headers = $header->header_frame->headers // {};
    
    return {
        body => $data,
        delivery_tag => $control->method_frame->delivery_tag,        
        reply_to => $headers->{reply_to},
        correlation_id => $headers->{correlation_id},
    }
}

sub _assert_frame_is {
    my $self = shift;
    my $frame = shift;
    my $expected_class = shift;
    
    die "Expected $expected_class but got a non-blessed scalar!\nFrame Dump:" . Dumper $frame
        unless blessed $frame;
    
    if (! $frame->can('method_frame')) {
        die "Exepected $expected_class, but got " . ref($frame) . "\nFrame Dump:" . Dumper $frame;
    }
    
    if (! $frame->method_frame->isa($expected_class)) {
        if (! $frame->method_frame->can('reply_text')) {
            die "Exepected $expected_class, but got " . ref($frame->method_frame) . "\nFrame Dump:" . Dumper $frame;
        }
        die $frame->method_frame->reply_text . "\n";
    }
}


sub _write_frame {
    my $self = shift;
    my $frame = shift;
    my $channel = shift // 1;
    
    if ($frame->isa('Net::AMQP::Protocol::Base')) {
        $frame = $frame->frame_wrap;
    }
    $frame->channel($channel);
    
    $self->_debug("Writing frame: " . Dumper $frame);
    
    $self->_write_data($frame->to_raw_frame()); 
      
    
}

sub _read_frames {
    my $self = shift;
    my $timeout = shift;
    my $expecting_receive = shift // 0;
    
    my $data = $self->_read_data($timeout);
        
    return unless $data;
 
    my @frames = Net::AMQP->parse_raw_frames(\$data);
    
    $self->_debug("Read frames: " . Dumper \@frames);
    $self->_debug("Raw data: $data") if ! @frames;

    @frames = $self->_strip_receive_frames($timeout, $expecting_receive, @frames);
    
    if (length($data) > 0 && ! @frames) {
        die "Read " . length($data) . " bytes of data, but it contained no parsable frames\n";
    }
    
    return @frames;
}

sub _write_data {
    my $self = shift;
    my $data = shift;
    
    $self->socket->send($data) || die "Failed in writing data ($!)\n";
    
}

sub _read_data {
    my $self = shift;
    my $timeout = shift // 30;
        
    # Set the timeout
    $self->socket->setsockopt(SOL_SOCKET, SO_RCVTIMEO, pack('L!L!', $timeout, 0));
    
    my $data = $self->{_pre_read_data} // '';
        
    # If we have less than 7 bytes of data, we need to read more so we at least get the header
    if (length $data < 7) {                
        $data .= $self->_read_from_socket(1024) // '';
    }

    # Read header    
    my $header = substr $data, 0, 7, ''; 
    
    return unless $header;
    
    my ($type_id, $channel, $size) = unpack 'CnN', $header;
      
    # Read body
    my $body = substr $data, 0, $size, '';
    
    # If we haven't got the full body and the footer, we have more to read
    if (length $body < $size || length $data == 0) {        
        # Add 1 to the size to make sure we get the footer
        my $size_remaining = $size+1 - length $body;
        
        while ($size_remaining > 0) {
            my $chunk = $self->_read_from_socket($size_remaining);

            $size_remaining -= length $chunk;
            $data .= $chunk;
        }
        
        $body .= substr($data, 0, $size-length($body), '');
    }
    
    # Read footer
    my $footer = substr $data, 0, 1, '';
    my $footer_octet = unpack 'C', $footer;
    
    die "Invalid footer: $footer_octet\n" unless $footer_octet == 206;
    
    $self->{_pre_read_data} = $data;
            
    return $header . $body . $footer;    
}

sub _read_from_socket {
    my $self = shift;
    my $read_size = shift;
    
    my $chunk_size;
    my $chunk;
    
    while (! defined $chunk_size) {
        $chunk_size = $self->socket->sysread($chunk,$read_size);        

        if (! defined $chunk_size) {
            my $read_error = $!;
            if ($read_error eq 'Interrupted system call') {
                # A signal interrupted us... just try again
                next;
            }
            
            if ($read_error eq 'Resource temporarily unavailable') {
                # We assume this is a timeout...
                return;
            }
            
            die "Error reading from socket: $read_error\n";
        }
    }
    
    return $chunk;
}

sub _debug {
    my $self = shift;
    my $lines = shift;
    
    return unless $self->debug;
    
    if ($self->debug_hook) {
        $self->debug_hook->($lines);
    }
    else {
        warn $lines;
    }   
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 THE FUTURE

When I get a chance, I'd like to tidy up the API, improve the tests and
split some of the logic into different modules. Could also look at a lighter
weight alternative to Moose.

Patches are - of course - welcome.

=head1 AUTHORS

Created by Sam Crawley

Contributions by DanC (dconlon)

=head1 LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2012 NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut