package Net::NATS2::ConnectInfo;

use v5.10;
use strict;
use warnings;

use Net::NATS2::Base;

has verbose      => 0;
has pedantic     => 0;
has tls_required => 0;
has headers      => 0;
has $_ for qw(auth_token user pass name lang version nkey sig);

sub ssl_required {
    goto &tls_required;
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
