package t::Middleware::Inherit;

use strict;
use warnings;

use parent qw(Plack::Middleware::EasyHooks);

our ($path, $status, $length);

sub before {
    my ($self, $env) = @_;

    $path = $env->{PATH_INFO};
}

sub after {
    my ($self, $env, $res) = @_;

    $status = $res->[0];
}

sub filter {
    my ($self, $env, $chunk) = @_;
    $env->{length} += length $chunk;

    return uc($chunk);
}

sub tail {
    return "baz";
}

sub finalize {
    my ($self, $env) = @_;

    $length = $env->{length};
}

1;

