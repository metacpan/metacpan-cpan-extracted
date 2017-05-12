package Plack::Middleware::Proxy::Requests;

=head1 NAME

Plack::Middleware::Proxy::Requests - Forward proxy server

=head1 SYNOPSIS

  # In app.psgi
  use Plack::Builder;
  use Plack::App::Proxy;

  builder {
      enable "Proxy::Connect";
      enable "Proxy::AddVia";
      enable "Proxy::Requests";
      Plack::App::Proxy->new->to_app;
  };

  # From shell
  plackup -s Twiggy -E Proxy -e 'enable q{AccessLog}' app.psgi

  # or
  twiggy -MPlack::App::Proxy \
         -e 'enable q{AccessLog}; enable q{Proxy::Connect}; \
             enable q{Proxy::AddVia}; enable q{Proxy::Requests}; \
             Plack::App::Proxy->new->to_app'

=head1 DESCRIPTION

This module handles HTTP requests as a forward proxy server.

Its job is to set a C<plack.proxy.url> environment variable based on
C<REQUEST_URI> variable.

The HTTP responses from the Internet might be invalid. In that case it
is required to run the server without L<Plack::Middleware::Lint> module.
This module is started by default and disabled if C<-E> or
C<--no-default-middleware> option is used when starting L<plackup>
script. Note that this disable also L<Plack::Middleware::AccessLog> so
it have to be enabled explicitly if needed.

The default server L<Plack::Server::PSGI> alias C<Standalone> can hang
up on stalled connection. It is better to run proxy server with
L<Starlet>, L<Starman> or L<Twiggy>.

=for readme stop

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0102';


use parent qw(Plack::Middleware);


sub call {
    my ($self, $env) = @_;

    $env->{'plack.proxy.url'} = $env->{REQUEST_URI};

    return $self->app->($env);
};


1;


=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::App::Proxy>, L<Plack::Middleware::Proxy::Connect>,
L<Plack::Middleware::Proxy::AddVia>, L<Starlet>, L<Starman>, L<Twiggy>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Plack-Middleware-Proxy-Requests/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Plack-Middleware-Proxy-Requests>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012-2013 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
