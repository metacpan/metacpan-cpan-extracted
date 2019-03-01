package Starch::Plugin::CookieArgs::State;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

sub cookie_args {
    my ($self) = @_;

    return $self->cookie_delete_args() if $self->is_deleted();
    return $self->cookie_set_args();
}

sub cookie_set_args {
    my ($self) = @_;

    my $expires = $self->expires();

    my $args = {
        name     => $self->manager->cookie_name(),
        value    => $self->id(),
        $expires ? (expires => "+${expires}s") : (),
        domain   => $self->manager->cookie_domain(),
        path     => $self->manager->cookie_path(),
        secure   => $self->manager->cookie_secure(),
        httponly => $self->manager->cookie_http_only(),
    };

    # Filter out undefined values.
    return {
        map { $_ => $args->{$_} }
        grep { defined $args->{$_} }
        keys( %$args )
    };
}

sub cookie_delete_args {
    my ($self) = @_;

    return {
        %{ $self->cookie_set_args() },
        expires => '-1d',
    };
}

1;
