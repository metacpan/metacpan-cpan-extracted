package Plack::Middleware::MangleEnv;
use strict;
use warnings;
use parent 'Plack::Middleware';

__PACKAGE__->mk_accessors(qw(https ));

sub call {
    my ($self, $env) = @_;
    $env->{HTTPS} = $self->https if $self->https;
    $self->app->($env);
}

1;
