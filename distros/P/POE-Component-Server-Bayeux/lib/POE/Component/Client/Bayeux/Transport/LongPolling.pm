package POE::Component::Client::Bayeux::Transport::LongPolling;

use strict;
use warnings;
use POE;
use Data::Dumper;
use HTTP::Request;
use POE::Component::Client::Bayeux::Utilities qw(decode_json_response);

use base qw(POE::Component::Client::Bayeux::Transport);

sub extra_states {
    # return an array of method names in this class that I want exposed
    return ( qw( openTunnelWith tunnelResponse ) );
}

sub check {
    my ($kernel, $heap, $types, $version, $xdomain) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
}

sub tunnelInit {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # Allow parent class to do error checking
    #$class->SUPER::tunnelInit(@_);

    my %connect = (
        channel => '/meta/connect',
        clientId => $heap->{parent_heap}{clientId},
        connectionType => 'long-polling',
    );

    $kernel->yield('openTunnelWith', \%connect);
}

sub openTunnelWith {
    my ($kernel, $heap, @messages) = @_[KERNEL, HEAP, ARG0 .. $#_];
    my $pheap = $heap->{parent_heap};
    $pheap->{_polling} = 1;

    # Ensure clientId is defined
    foreach my $message (@messages) {
        $message->{clientId} = $pheap->{clientId};
    }

    $pheap->{client}->logger->debug(">>> LongPolling tunnel >>>\n".Dumper(\@messages));

    # Create an HTTP POST request, encoding the messages into JSON
    my $request = HTTP::Request->new('POST', $pheap->{remote_url},
        [ 'content-type', 'text/json' ],
        $pheap->{json}->encode(\@messages),
    );

    # Create a UUID so I can collect meta info about this request
    my $uuid = $pheap->{uuid}->create_str();
    $heap->{_tunnelsOpen}{$uuid} = { opened => time() };

    # Use parent user agent to make request
    $kernel->post( $pheap->{ua}, 'request', 'tunnelResponse', $request, $uuid );

    # TODO: use $heap->{parent_heap}{advice}{timeout} as a timeout for this connect to reply
}

sub tunnelResponse {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $pheap = $heap->{parent_heap};
    $pheap->{_polling} = 0;

    my $request_object  = $request_packet->[0];
    my $request_tag     = $request_packet->[1]; # from the 'request' post
    my $response_object = $response_packet->[0];

    my $meta = delete $heap->{_tunnelsOpen}{$request_tag};

    my $json;
    eval {
        $json = decode_json_response($response_object);
    };
    if ($@) {
        # Ignore errors if shutting down
        return if $pheap->{_shutdown};
        die $@;
    }

    $pheap->{client}->logger->debug("<<< LongPolling tunnel <<<\n".Dumper($json));

    foreach my $message (@$json) {
        $kernel->post( $heap->{parent}, 'deliver', $message );
        if ($message->{channel} eq '/meta/connect') {
            $pheap->{advice} = $message->{advice} || {};
        }
    }

    $kernel->yield('tunnelCollapse');
}

sub tunnelCollapse {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $pheap = $heap->{parent_heap};

    my $reconnect;
    if ($pheap->{advice}) {
        $reconnect = $pheap->{advice}{reconnect};
    }
    if (delete $pheap->{_reconnect}) {
        $reconnect = 'handshake';
    }
    if ($reconnect) {
        if ($reconnect eq 'none') {
            die "Server asked us not to reconnect";
        }
        elsif ($reconnect eq 'handshake') {
            $pheap->{_initialized} = 0;
            $pheap->{_connected} = 0;
            $kernel->yield('_stop');
            $kernel->post( $heap->{parent}, 'handshake' );
            return;
        }
    }

    return if (! $pheap->{_initialized});
    if (delete $pheap->{_disconnect}) {
        $pheap->{_connected} = 0;
        return;
    }

    if ($pheap->{_polling}) {
        $pheap->{client}->logger->debug("tunnelCollapse: Wait for polling to end");
        return;
    }

    if ($pheap->{_connected}) {
        my %connect = (
            channel => '/meta/connect',
            clientId => $pheap->{clientId},
            connectionType => 'long-polling',
        );

        $kernel->yield('openTunnelWith', \%connect);
    }
}

sub sendMessages {
    my ($kernel, $heap, $messages) = @_[KERNEL, HEAP, ARG0];
    my $pheap = $heap->{parent_heap};

    foreach my $message (@$messages) {
        $message->{clientId} = $pheap->{clientId};
    }

    $pheap->{client}->logger->debug(">>> LongPolling >>>\n".Dumper($messages));

    # Create an HTTP POST request, encoding the messages into JSON
    my $request = HTTP::Request->new('POST', $pheap->{remote_url},
        [ 'content-type', 'text/json' ],
        $pheap->{json}->encode($messages),
    );

    # Use parent user agent to make request
    $kernel->post( $pheap->{ua}, 'request', 'deliver', $request );
}

sub deliver {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $pheap = $heap->{parent_heap};

    my $request_object  = $request_packet->[0];
    my $request_tag     = $request_packet->[1]; # from the 'request' post
    my $response_object = $response_packet->[0];

    my $json = decode_json_response($response_object);

    $pheap->{client}->logger->debug("<<< LongPolling <<<\n" . Dumper($json));

    foreach my $message (@$json) {
        $kernel->post( $heap->{parent}, 'deliver', $message );
    }
}

1;
