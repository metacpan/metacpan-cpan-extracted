package Net::Statsd::Tiny::Test;

use Test::Roo::Role;

use Carp;
use curry;
use IO::Select;
use IO::Socket;
use Net::EmptyPort qw/ empty_port /;
use Socket qw/ SOCK_DGRAM /;

use Net::Statsd::Tiny;

has proto => (
    is      => 'ro',
    default => 'udp',
);

has host => (
    is      => 'ro',
    default => '127.0.0.1',
);

has max_buffer_size => (
    is      => 'ro',
    default => 512,
);

has prefix => (
    is      => 'ro',
    default => 'test.',
);

has autoflush => (
    is      => 'ro',
    default => 1,
);

has timeout => (
    is      => 'ro',
    default => 2,
);

has input => (
    is       => 'ro',
    required => 1,
);

has output => (
    is       => 'ro',
    required => 1,
);

test "test client" => sub {
    my ($self) = @_;

    my $result = $self->test_udp( sub { $self->send_tests(@_) } );

  TODO: {

      local $TODO = "random sample" if $self->output =~ /\|\@\d/;

      is $result, $self->output, 'expected result';

    }

};

sub send_tests {
    my ($self, $client) = @_;

    foreach my $action (@{ $self->input }) {

        my ($method, @args) = @{ $action };
        $client->$method(@args);

    }

}

# Adapted from Log-Dispatch-UDP-0.01/t/01-basic.t

sub test_udp {
    my ( $self, $callback ) = @_;

    my $port = empty_port( { proto => $self->proto } );

    my $pid = fork;
    if ($pid) {

        my $socket = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => $self->proto,
            Type      => SOCK_DGRAM,
        ) or croak $!;

        my $select = IO::Select->new;
        $select->add($socket);

        my $buffer;

        if ( $select->can_read( $self->timeout ) ) {
            $socket->recv( $buffer, $self->max_buffer_size );
        }
        else {
            kill TERM => $pid;
            $buffer = undef;
        }

        waitpid $pid, 0;

        return $buffer;

    }
    if ( defined $pid ) {

        my $client = Net::Statsd::Tiny->new(
            port            => $port,
            host            => $self->host,
            proto           => $self->proto,
            prefix          => $self->prefix,
            max_buffer_size => $self->max_buffer_size,
            autoflush       => $self->autoflush,
        );

        sleep 1;    # wait for server to start

        $callback->($client);

        exit 0;
    }
    else {
        croak $!;
    }

}

1;
