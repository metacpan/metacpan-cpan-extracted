package POE::Component::Client::Bayeux;

=head1 NAME

POE::Component::Client::Bayeux - Bayeux/cometd client implementation in POE

=head1 SYNOPSIS

    use POE qw(Component::Client::Bayeux);

    POE::Component::Client::Bayeux->spawn(
        Host => '127.0.0.1',
        Alias => 'comet',
    );

    POE::Session->create(
        inline_states => {
            _start => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];
                $kernel->alias_set('my_client');

                $kernel->post('comet', 'init');
                $kernel->post('comet', 'subscribe', '/chat/demo', 'events');
                $kernel->post('comet', 'publish', '/chat/demo', {
                    user => "POE",
                    chat => "POE has joined",
                    join => JSON::XS::true,
                });
            },
            events => sub {
                my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

                print STDERR "Client got subscribed message:\n" . Dumper($message);
            },
        },
    );

    $poe_kernel->run();

=head1 DESCRIPTION

This module implements the Bayeux Protocol (1.0draft1) from the Dojo Foundation.
Also called cometd, Bayeux is a low-latency routing protocol for JSON encoded
events between clients and servers in a publish-subscribe model.

This is the client implementation.  It is not feature complete, but works at the
moment for testing a Bayeux server.

=cut

use strict;
use warnings;
use POE qw(Component::Client::HTTP Component::Client::Bayeux::Transport);
use Params::Validate;
use Data::Dumper;
use JSON::Any;
use Data::UUID;
use HTTP::Request::Common;
use Log::Log4perl qw(get_logger :levels);
use Log::Log4perl::Appender;
use Log::Log4perl::Layout;

use POE::Component::Client::Bayeux::Utilities qw(decode_json_response);
use POE::Component::Server::Bayeux::Utilities qw(channel_match);

use base qw(Class::Accessor Exporter);
__PACKAGE__->mk_accessors(qw(session clientId logger));

our @EXPORT_OK = qw(decode_json_response);

my $protocol_version = '1.0';
our $VERSION = '0.03';

=head1 USAGE

=head2 spawn (...)

=over 4

Create a new Bayeux client.  Arguments to this method:

=over 4

=item I<Host> (required)

Connect to this host.

=item I<Port> (default: 80)

Connect to this port.

=item I<SSL> (default: 0)

Use SSL on connection

=item I<Alias> (default: 'bayeux_client')

The POE session alias for local sessions to interact with.

=item I<Debug> (default: 0)

Either 0 or 1, indicates level of logging.

=item I<LogFile> (default: undef)

Logfile to write output to.

=item I<LogStdout> (default: 1)

If false, no logger output to STDOUT.

=item I<CrossDomain> (not implemented)

Enables cross domain protocol of messaging.

=item I<ErrorCallback> (default: none)

Provide a coderef that will receive a message hashref of any failed messages (erorrs in protocol, or simply unhandled messages).

=back

Returns a class object with methods of interest:

=over 4

=item I<session>

The L<POE::Session> object returned from an internal create() call.

=back

=back

=cut

sub spawn {
    my $class = shift;
    my %args = validate(@_, {
        Host => 1,
        Port => { default => 80 },
        Path => { default => '/cometd' },
        SSL  => { default => 0 },
        Alias => { default => 'bayeux_client' },
        CrossDomain => { default => 0 },
        Debug => { default => 0 },
        ErrorCallback => 0,
        LogFile => 0,
        LogStdout => { default => 1 },
    });

    if ($args{CrossDomain}) {
        # TODO
        die __PACKAGE__ . " doesn't yet support cross domain protocol.\n";
    }

    my $ua_alias = $args{Alias} . '_ua';
    my $cometd_url = sprintf 'http%s://%s:%s%s',
        ($args{SSL} ? 's' : ''), $args{Host}, $args{Port}, $args{Path};

    POE::Component::Client::HTTP->spawn(
        Alias => $ua_alias,
    );

    my $self = bless { %args }, $class;

    my $session = POE::Session->create(
        inline_states => {
            _start => \&client_start,
            _stop  => \&client_stop,
            shutdown => \&client_shutdown,

            # Public methods
            init        => \&init,
            publish     => \&publish,
            subscribe   => \&subscribe,
            unsubscribe => \&unsubscribe,
            disconnect  => \&disconnect,
            reconnect   => \&reconnect,

            # Internal
            handshake => \&handshake,
            handshake_response => \&handshake_response,
            send_message => \&send_message,
            ua_response => \&ua_response,
            deliver => \&deliver,
            flush_queue => \&flush_queue,
            send_transport => \&send_transport,
        },
        heap => {
            args       => \%args,
            ua         => $ua_alias,
            remote_url => $cometd_url,
            json       => JSON::Any->new(),
            uuid       => Data::UUID->new(),
            subscriptions => {},
            client     => $self,
        },
        ($ENV{POE_DEBUG} ? (
        options => { trace => 1, debug => 1 },
        ) : ()),
    );

    # Setup logger
    my $logger = Log::Log4perl->get_logger('bayeux_client');
    {
        my $logger_layout = Log::Log4perl::Layout::PatternLayout->new("[\%d] \%p: \%m\%n");
        $logger->level($args{Debug} ? $DEBUG : $INFO);

        if ($args{LogFile}) {
            my $file_appender = Log::Log4perl::Appender->new(
                'Log::Log4perl::Appender::File',
                name => 'filelog',
                filename => $args{LogFile},
            );
            $file_appender->layout( $logger_layout );
            $logger->add_appender($file_appender);
        }
        if ($args{LogStdout}) {
            my $stdout_appender = Log::Log4perl::Appender->new(
                'Log::Log4perl::Appender::Screen',
                name => 'screenlog',
                stderr => 0,
            );
            $stdout_appender->layout($logger_layout);
            $logger->add_appender($stdout_appender);
        }
    }

    $self->{logger} = $logger;
    $self->{session} = $session->ID;
    return $self;
}

sub client_start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->alias_set( $heap->{args}{Alias} );

    if ($ENV{POE_DEBUG}) {
        $kernel->alias_resolve($heap->{ua})->option( trace => 1, debug => 1 );
    }
}

sub client_stop {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
}

sub client_shutdown {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $heap->{_shutdown} = 1;

    $kernel->call( $heap->{ua}, 'shutdown' );

    if ($heap->{transport}) {
        $kernel->call( $heap->{transport}, 'shutdown' );
    }

    $kernel->alias_remove( $heap->{args}{Alias} );
}

## Public States ###

=head1 POE STATES

The following are states you can post to to interact with the client.

=head2 init ()

=over 4

Initializes the client, connecting to the server, and sets up long polling.

=back

=cut

sub init {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->yield('handshake');
}


sub handshake {
    my ($kernel, $heap, %ext) = @_[KERNEL, HEAP, ARG0 .. $#_];

    my %handshake = (
        channel => '/meta/handshake',
        version => $protocol_version,
        minimumVersion => $protocol_version,
        supportedConnectionTypes => [ 'long-polling' ],
        ext => {
            'json-comment-filtered' => 1,
            %ext,
        }
    );

    $kernel->yield('send_message', 'handshake_response', \%handshake);

    # Unsubscribe from all TODO

    $heap->{_initialized} = 1;
    $heap->{_connected} = 0;
}

=head2 publish ($channel, $message)

=over 4

Publishes arbitrary message to the channel given.  Message will have 'clientId'
and 'id' fields auto-populated.

=back

=cut

sub publish {
    my ($kernel, $heap, $channel, $message) = @_[KERNEL, HEAP, ARG0, ARG1];

    $kernel->call($_[SESSION], 'send_transport', {
        channel => $channel,
        data => $message,
    });
}

=head2 subscribe ($channel, $callback)

=over 4

Subscribes client to the channel given.  Callback can either be a coderef or
the name of a state in the calling session.  Callback will get one arg, the
message that was posted to the channel subscribed to.

=back

=cut

sub subscribe {
    my ($kernel, $heap, $channel, $callback) = @_[KERNEL, HEAP, ARG0, ARG1];

    return if $heap->{subscriptions}{$channel}
        && $heap->{subscriptions}{$channel}{callback} eq $callback
        && $heap->{subscriptions}{$channel}{session}  eq $_[SENDER];

    $heap->{subscriptions}{$channel} = {
        callback => $callback,
        session  => $_[SENDER],
    };

    $kernel->call($_[SESSION], 'send_transport', {
        channel => '/meta/subscribe',
        subscription => $channel,
    });
}

=head2 unsubscribe ($channel)

=over 4

Unsubscribes from channel.

=back

=cut

sub unsubscribe {
    my ($kernel, $heap, $channel) = @_[KERNEL, HEAP, ARG0];

    delete $heap->{subscriptions}{$channel};

    $kernel->call($_[SESSION], 'send_transport', {
        channel => '/meta/unsubscribe',
        subscription => $channel,
    });
}

=head2 disconnect ()

=over 4

Sends a disconnect request.

=back

=cut

sub disconnect {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->call($_[SESSION], 'send_transport', {
        channel => '/meta/disconnect',
    });
    $heap->{_disconnect} = 1;
}

=head2 reconnect ()

=over 4

Disconnect and reconnect

=back

=cut

sub reconnect {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->call($_[SESSION], 'send_transport', {
        channel => '/meta/disconnect',
    });
    $heap->{_reconnect} = 1;
}

## Internal Main States ###

sub handshake_response {
    my ($kernel, $heap, $session, $response) = @_[KERNEL, HEAP, SESSION, ARG0];

    if (! $response || ! ref $response || ! ref $response eq 'HASH') {
        die "Invalid response from handshake\n";
    }

    if ($response->{version} && $protocol_version < $response->{version}) {
        die "Can't connect to server: version $$response{version} is > my supported version $protocol_version\n";
    }

    if (! $response->{successful}) {
        die "Unsuccessful handshake.\n" . Dumper($response);
    }

    # Store client id for all future requests
    $heap->{clientId} = $response->{clientId};
    $heap->{client}->clientId( $heap->{clientId} );

    # Store advice
    $heap->{advice}   = $response->{advice} || {};

    # Choose a transport, build it, and ask it to connect
    # TODO: make sure it's one of the returned supportedConnectionTypes

    $heap->{transport} = POE::Component::Client::Bayeux::Transport->spawn(
        type   => 'long-polling',
        parent => $session,
        parent_heap => $heap,
    );

    $kernel->post($heap->{transport}, 'tunnelInit');
}

sub deliver {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

    if (! $message || ! ref $message || ! ref $message eq 'HASH' || ! $message->{channel}) {
        die "deliver(): Invalid message\n";
    }

    # If the message has an id, see if I have a record of the instigating request
    my $request;
    if ($message->{id}) {
        $request = delete $heap->{messages}{ $message->{id} };
    }

    # Handle /meta/ channel responses
    if (my ($meta_channel) = $message->{channel} =~ m{^/meta/(.+)$}) {
        if ($meta_channel eq 'connect') {
            if ($message->{successful} && ! $heap->{_connected}) {
                $heap->{_connected} = 1;
            }
            elsif (! $heap->{_initialized}) {
                $heap->{_connected} = 0;
            }
            $kernel->yield('flush_queue');
            return;
        }
    }

    # Publishes to a non-private channel MAY yield a simple successful message.  Ignore those.
    if ($request && $request->{caller_state} eq 'publish'
        && $message->{successful} && $message->{channel} !~ m{^/service/}) {
        return;
    }

    # Check if I have a subscription for the channel
    my $matching_subscription;
    foreach my $subscription (keys %{ $heap->{subscriptions} }) {
        next unless channel_match($message->{channel}, $subscription);
        $matching_subscription = $subscription;
        last;
    }

    # Call the callback if so for each subscription
    if ($matching_subscription) {
        my $sub_details = $heap->{subscriptions}{$matching_subscription};
        if ($sub_details->{callback}) {
            if (ref $sub_details->{callback}) {
                $sub_details->{callback}($message, $heap);
                return;
            }
            elsif ($_[SESSION] ne $sub_details->{session}) {
                $kernel->post( $sub_details->{session}, $sub_details->{callback}, $message, $heap );
                return;
            }
        }
    }

    # Call generic callback for all non-successful messages
    if (defined $message->{successful} && ! $message->{successful} && $heap->{args}{ErrorCallback}) {
        $heap->{args}{ErrorCallback}($message);
    }

    $heap->{client}->logger->debug("deliver() couldn't handle message:\n" . Dumper($message));
}

## Utilities ###

sub send_message {
    my ($kernel, $heap, $callback_state, @args) = @_[KERNEL, HEAP, ARG0 .. $#_];

    $heap->{client}->logger->debug(" >>> Pre-transport >>>\n" . Dumper(\@args));

    # Create an HTTP POST request, encoding the args into JSON
    my $request = POST $heap->{remote_url}, [ message => $heap->{json}->encode(\@args) ];

    # Create a UUID so I can collect meta info about this request
    my $uuid = $heap->{uuid}->create_str();
    $heap->{_ua_requests}{$uuid} = { json_callback => $callback_state };

    # Send the request to the user agent
    $kernel->post( $heap->{ua}, 'request', 'ua_response', $request, $uuid );
}

sub ua_response {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $request_object  = $request_packet->[0];
    my $request_tag     = $request_packet->[1]; # from the 'request' post
    my $response_object = $response_packet->[0];

    my $meta = delete $heap->{_ua_requests}{$request_tag};
    if ($meta && $meta->{json_callback}) {
        my $json;
        eval {
            $json = decode_json_response($response_object);
        };
        if ($@) {
            # Ignore errors if shutting down
            return if $heap->{_shutdown};
            die $@;
        }
        $heap->{client}->logger->debug("<<< Pre-transport <<<\n" . Dumper($json));
        $kernel->yield( $meta->{json_callback}, @$json );
    }
}

sub send_transport {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

    # Add unique ID to each message
    my $msg_id = ++$heap->{message_id};
    $message->{id} = $msg_id;

    # Store a copy of this message
    $heap->{messages}{$msg_id} = {
        %$message,
        caller_session => $_[SENDER],
        caller_state   => $_[CALLER_STATE],
    };

    if ($heap->{transport}) {
        $kernel->post( $heap->{transport}, 'sendMessages', [ $message ]);
    }
    else {
        $heap->{client}->logger->debug("Queueing message ".Dumper($message)." as no active transport");
        push @{ $heap->{message_queue} }, $message;
    }

    return $msg_id;
}

sub flush_queue {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    return unless $heap->{message_queue} && ref $heap->{message_queue} && int @{ $heap->{message_queue} };
    return unless $heap->{transport};

    $heap->{client}->logger->debug("Flushing queue to transport");

    $kernel->post($heap->{transport}, 'sendMessages', [ @{ $heap->{message_queue} } ]);

    $heap->{message_queue} = [];
}

=head1 TODO

Lots of stuff.

The code currently implements only the long-polling transport and doesn't yet
strictly follow all the directives in the protocol document http://svn.xantus.org/shortbus/trunk/bayeux/bayeux.html

=head1 KNOWN BUGS

No known bugs, but I'm sure you can find some.

=head1 SEE ALSO

L<POE>, L<POE::Component::Server::Bayeux>, L<POE::Component::Client::HTTP>

=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut

1;
