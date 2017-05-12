use warnings;
use strict;
use Test::More;
use POSIX qw(:errno_h);
use Test::TCP;

BEGIN
{
    use_ok('Reflexive::Role::TCPServer');
}

{
	package MyTCPClient;
	use Moose;
	extends 'Reflex::Client';

    has server =>
    (
        is => 'ro',
        weak_ref => 1,
    );

	sub on_client_connected
    {
		my ($self, $args) = @_;
		$self->connection()->put("TEST\n");
	};

	sub on_connection_data
    {
		my ($self, $args) = @_;

        Test::More::is($args->octets, "TSET\n", 'got the right data from the server');
		# Disconnect after we receive the echo.
		$self->stop();
        $self->server->shutdown();
	}
}


{
    package MyTCPServer;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose(':all');
    use MooseX::Types::Structured(':all');
    use MooseX::Params::Validate;

    extends 'Reflex::Base';

    sub on_socket_data
    {
        my ($self, $args) = pos_validated_list
        (
            \@_,
            { isa => 'MyTCPServer' },
            { isa => 'Reflexive::Event::Data' },
        );
        
        my $data = $args->data;
        Test::More::is($data, "TEST\n", 'got the right data from client');
        chomp($data);
        Test::More::diag('Sending reversed echo back to client');
        $args->get_first_emitter()->put(reverse($data)."\n");
    }

    with 'Reflexive::Role::TCPServer';

    around _build_socket => sub
    {
        my ($orig, $self, $args) = pos_validated_list
        (
            \@_,
            { isa => CodeRef },
            { does => 'Reflexive::Role::TCPServer' },
            { isa => FileHandle },
        );

        my $result = $self->$orig($args);

        Test::More::isa_ok
        (
            $result,
            'Reflexive::Stream::Filtering',
            'Properly built a filtering socket'
        );

        return $result;
    };

    after on_listener_accept => sub
    {
        my $self = shift;
        Test::More::is($self->_count_sockets, 1, 'Accepted the one socket');
    };

    after on_socket_stop => sub
    {
        my $self = shift;
        Test::More::is($self->_count_sockets, 0, 'Removed the one socket');
    };

    after shutdown => sub
    {
        Test::More::pass('Shutdown called');
    };

    around on_listener_error => sub
    {
        my ($orig, $self, $args) = pos_validated_list
        (
            \@_,
            { isa => CodeRef },
            { does => 'Reflexive::Role::TCPServer' },
            { isa => 'Reflex::Event::Error' },
        );

        if($args->{errfun} eq 'bind')
        {
            Test::More::diag('Failed to bind, attempting again');
            $self->_set_port($self->port + 1);
            $self->try_listener_build();
        }
    };

    before try_listener_build => sub
    {
        my $self = shift;
        Test::More::diag("Attempting to listen on ${\$self->host}:${\$self->port}");
    };
}

my $port = Test::TCP::empty_port();

my $server = MyTCPServer->new(port => $port);
my $client = MyTCPClient->new(port => $port, server => $server);

Reflex->run_all();

done_testing();
