package Net::NATS2::ServerInfo;

use v5.10;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub server_id {
    my $self = shift;
    $self->{server_id} = shift if @_;
    return $self->{server_id};
}

sub version {
    my $self = shift;
    $self->{version} = shift if @_;
    return $self->{version};
}

sub go {
    my $self = shift;
    $self->{go} = shift if @_;
    return $self->{go};
}

sub host {
    my $self = shift;
    $self->{host} = shift if @_;
    return $self->{host};
}

sub port {
    my $self = shift;
    $self->{port} = shift if @_;
    return $self->{port};
}

sub auth_required {
    my $self = shift;
    $self->{auth_required} = shift if @_;
    return $self->{auth_required};
}

sub ssl_required {
    my $self = shift;
    $self->{ssl_required} = shift if @_;
    return $self->{ssl_required};
}

sub tls_required {
    my $self = shift;
    $self->{tls_required} = shift if @_;
    return $self->{tls_required};
}

sub max_payload {
    my $self = shift;
    $self->{max_payload} = shift if @_;
    return $self->{max_payload};
}

sub headers {
    my $self = shift;
    $self->{headers} = shift if @_;
    return $self->{headers};
}

1;
