package Net::NATS2::ConnectInfo;

use v5.10;
use strict;
use warnings;

sub _new {
    my $class = shift;
    return bless {@_}, $class;
}

sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    return $self->{verbose};
}

sub pedantic {
    my $self = shift;
    $self->{pedantic} = shift if @_;
    return $self->{pedantic};
}

sub ssl_required {
    goto &tls_required;
}

sub tls_required {
    my $self = shift;
    $self->{tls_required} = shift if @_;
    return $self->{tls_required};
}

sub headers {
    my $self = shift;
    $self->{headers} = shift if @_;
    return $self->{headers};
}

sub auth_token {
    my $self = shift;
    $self->{auth_token} = shift if @_;
    return $self->{auth_token};
}

sub user {
    my $self = shift;
    $self->{user} = shift if @_;
    return $self->{user};
}

sub pass {
    my $self = shift;
    $self->{pass} = shift if @_;
    return $self->{pass};
}

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    return $self->{name};
}

sub lang {
    my $self = shift;
    $self->{lang} = shift if @_;
    return $self->{lang};
}

sub version {
    my $self = shift;
    $self->{version} = shift if @_;
    return $self->{version};
}

sub new {
    my $class = shift;
    my $self  = $class->_new(@_);

    $self->verbose(0)      unless $self->verbose;
    $self->pedantic(0)     unless $self->pedantic;
    $self->tls_required(0) unless $self->tls_required;
    $self->headers(0)      unless $self->headers;

    return $self;
}

sub TO_JSON {
    my $self = shift;
    my $hash = {%{$self}};
    $hash->{verbose}      = $self->verbose      ? \1 : \0;
    $hash->{pedantic}     = $self->pedantic     ? \1 : \0;
    $hash->{tls_required} = $self->tls_required ? \1 : \0;
    $hash->{headers}      = $self->headers      ? \1 : \0;
    return $hash;
}

1;
