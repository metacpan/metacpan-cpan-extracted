package Net::Statsd::Tiny::Test;

use Test::Roo::Role;

use IO::Select;
use Net::EmptyPort qw/ listen_socket /;

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

    my $socket = listen_socket( { proto => $self->proto } )
        or die $!;

    my $pid = fork;
    if ($pid) {

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
            port            => $socket->sockport,
            host            => $self->host,
            proto           => $self->proto,
            prefix          => $self->prefix,
            max_buffer_size => $self->max_buffer_size,
            autoflush       => $self->autoflush,
        );

        $callback->($client);

        exit 0;
    }
    else {
        die $!;
    }

}

1;
