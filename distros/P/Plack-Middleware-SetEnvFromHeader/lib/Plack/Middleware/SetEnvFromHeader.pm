use strict;
use warnings;

package Plack::Middleware::SetEnvFromHeader;
use parent 'Plack::Middleware';
use Plack::Request;

our $VERSION = '0.01';

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    # Passed ENV_NAME => "Header-Name"
    $env = {
        %$env,
        map  { $_ => scalar $req->header($self->{$_}) }
        grep { $_ ne 'app' }
        keys %$self
    };

    return $self->app->($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::SetEnvFromHeader - Set environment variables from the values of request headers

=head1 SYNOPSIS

    # in app.psgi
    use Plack::Builder;

    builder {
        enable 'SetEnvFromHeader' =>
            REMOTE_USER => "X-Proxy-REMOTE-USER";
        $app;
    };

    # with plackup
    plackup -e 'enable SetEnvFromHeader => REMOTE_USER => "X-Testing-User"' app.psgi

=head1 DESCRIPTION

SetEnvFromHeader modifies the environment passed to the application by adding your
specified keys with the values pulled from the request header.

This is primarily useful when testing apps under plackup (or similar) in a
development environment.

It may also be desireable in production to provide standard environment values
via non-standard headers, but if you're using this for security-sensitive
values like C<REMOTE_USER> make sure no one can make direct requests to your
backend!

=head1 AUTHOR

Thomas Sibley <tsibley@cpan.org>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
development environment, or for providing standard environment valuthe same terms as Perl itself.

=cut
