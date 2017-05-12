{
    package MyTCPServer;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose(':all');
    use MooseX::Types::Structured(':all');
    use MooseX::Params::Validate;
    use Socket;

    # we need to extend the Reflex::Base class
    extends 'Reflex::Base';

    # here is our callback for any inbound data from any sockets
    # take a look at what gets passed in $args
    sub on_socket_data
    {
        my ($self, $args) = pos_validated_list
        (
            \@_,
            { isa => 'MyTCPServer' },
            { isa => 'Reflexive::Event::Data' },
        );
        my $data = $args->data;
        my $socket = $args->get_first_emitter();
        warn "Received data ($data) from socket ($socket)";
        chomp($data);
        # look at Reflex::Stream for what methods are available
        $socket->put(reverse($data)."\n");
    }

    # with our required methods taken care of, we consume the TCPServer role
    with 'Reflexive::Role::TCPServer';

    # if there was a problem binding the socket on_listener_error is called
    # here, it is advised to not die (the default), but instead try to bind
    # again on a different port
    around on_listener_error => sub
    {
        my ($orig, $self, $args) = pos_validated_list
        (
            \@_,
            { isa => CodeRef },
            { does => 'Reflexive::Role::TCPServer' },
            { isa => 'Reflex::Event::Error' },
        );

        if($args->function eq 'bind')
        {
            warn 'Failed to bind, attempting again';
            $self->_set_port($self->port + 1);
            $self->try_listener_build();
        }
    };

    # try_listener_build wraps the invocation of the attribute which triggers
    # the builder method. If it fails, listener_error is emitted instead of
    # dying
    before try_listener_build => sub
    {
        my $self = shift;
        warn "Attempting to listen on ${\$self->host}:${\$self->port}";
    };

    # the role takes care of accepting connections and building filtering
    # streams for you

    after on_listener_accept => sub
    {
        my ($self, $args) = pos_validated_list
        (
            \@_,
            { isa => 'MyTCPServer' },
            { isa => 'Reflex::Event::Socket' },
        );

        my($port, $addr) = sockaddr_in($args->{peer});
        warn "Accepting a socket connection from $addr:$port";
    };

    # same with socket clean up when they are stopped, but we can hook into
    # those events if needed

    after on_socket_stop => sub
    {
        my ($self, $args) = pos_validated_list
        (
            \@_,
            { isa => 'MyTCPServer' },
            { isa => 'Reflex::Event' },
        );

        warn 'Closing socket: ' . $args->get_first_emitter();

    }
}

my $server = MyTCPServer->new();
$server->run_all();
