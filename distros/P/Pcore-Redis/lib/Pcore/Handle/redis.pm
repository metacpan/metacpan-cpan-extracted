package Pcore::Handle::redis;

use Pcore -class;
use AnyEvent::RipeRedis;

with qw[Pcore::Handle::Wrapper];

has connect_timeout => ( is => 'ro', isa => Maybe [PositiveInt], default => undef );
has read_timeout    => ( is => 'ro', isa => Maybe [PositiveInt], default => undef );

sub _connect ($self) {
    my %params = (
        host     => undef,
        port     => undef,
        password => $self->uri->username,
        database => $self->uri->query_params->{db} || 0,

        # params
        encoding               => 'UTF-8',
        connection_timeout     => $self->connect_timeout,
        read_timeout           => $self->read_timeout,
        lazy                   => 0,
        reconnect              => 1,
        min_reconnect_interval => undef,
        handle_params          => undef,

        # callbacks
        on_connect       => undef,
        on_connect_error => undef,
        on_error         => undef,
    );

    if ( $self->uri->path ne q[/] ) {
        $params{host} = 'unix/';

        $params{port} = $self->uri->path->to_string;
    }
    else {
        $params{host} = $self->uri->host->name;

        $params{port} = $self->uri->port || 6379;
    }

    return AnyEvent::RipeRedis->new(%params);
}

sub _disconnect ($self) {
    $self->h->disconnect;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 11                   | * Private subroutine/method '_connect' declared but not used                                                   |
## |      | 47                   | * Private subroutine/method '_disconnect' declared but not used                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::redis

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
