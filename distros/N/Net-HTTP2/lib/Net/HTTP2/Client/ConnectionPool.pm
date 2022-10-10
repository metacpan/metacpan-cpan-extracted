package Net::HTTP2::Client::ConnectionPool;

use strict;
use warnings;

use Carp ();

use Net::HTTP2::Constants ();

sub new {
    my ($class, $io_name, $conn_opts_hr) = @_;

    my $ns = "Net::HTTP2::Client::Connection::$io_name";

    if (!$ns->can('new')) {
        local $@;
        Carp::croak $@ if !eval "require $ns";
    }

    return bless {
        conn_ns => $ns,
        conn_opts => $conn_opts_hr,
    }, $class;
}

sub get_connection {
    my ($self, $host, $port) = @_;

    return $self->{'pool'}{$host}{$port || q<>} ||= $self->{'conn_ns'}->new(
        $host,
        %{ $self->{'conn_opts'} },
        ($port == Net::HTTP2::Constants::HTTPS_PORT ? () : (port => $port)),
    );
}

1;
