use strict;
use warnings;

package Plack::Middleware::ForceEnv;
use parent 'Plack::Middleware';

our $VERSION = '0.02';

sub call {
    my ($self, $env) = @_;

    # Add to env whatever the user gave us
    $env = {
        %$env,
        map { $_ => $self->{$_} } grep { $_ ne 'app' } keys %$self
    };

    return $self->app->($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::ForceEnv - Force set environment variables for testing

=head1 SYNOPSIS

    # in app.psgi
    use Plack::Builder;

    builder {
        enable 'ForceEnv' =>
            REMOTE_ADDR => "127.0.0.1",
            REMOTE_USER => "trs";
        $app;
    };

    # with plackup
    plackup -e 'enable ForceEnv => REMOTE_USER => "trs"' app.psgi

=head1 DESCRIPTION

ForceEnv modifies the environment passed to the application by adding your
specified key value pairs.

This is primarily useful when testing apps under plackup (or similar) in a
development environment.

=head1 AUTHOR

Thomas Sibley <tsibley@cpan.org>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
