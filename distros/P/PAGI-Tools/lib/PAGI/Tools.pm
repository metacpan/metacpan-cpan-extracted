package PAGI::Tools;

use strict;
use warnings;

our $VERSION = '0.002000';

1;

__END__

=encoding UTF-8

=head1 NAME

PAGI::Tools - Application toolkit for the PAGI specification

=head1 SYNOPSIS

Raw PAGI is deliberately minimal — an application is just an C<async> sub that
speaks the protocol directly:

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'application/json']],
        });
        await $send->({ type => 'http.response.body', body => '{"hello":"world"}' });
    };

PAGI-Tools adds the ergonomics — requests, response values, routing, a
middleware suite — so the same application reads like this:

    use PAGI::App::Router;
    use PAGI::Request;
    use PAGI::Response;

    my $router = PAGI::App::Router->new;

    # A response value mounts straight onto a route:
    $router->get('/' => PAGI::Response->json({ hello => 'world' }));

    # A dynamic handler builds a request and sends a response value:
    $router->get('/users/:id' => async sub {
        my ($scope, $receive, $send) = @_;
        my $req = PAGI::Request->new($scope, $receive);
        await PAGI::Response->json({ id => $req->path_param('id') })->respond($send);
    });

    my $app = $router->to_app;   # still just a PAGI app: an async sub

Run it with any PAGI server (such as C<pagi-server> from the C<PAGI-Server>
distribution), or mount it inside a larger PAGI application.

=head1 DESCRIPTION

L<PAGI> — the Perl Asynchronous Gateway Interface — is deliberately small: an
application is just an C<async> sub that speaks a simple event protocol over
C<$scope>, C<$receive>, and C<$send>. That minimalism is a virtue, but building
applications directly against the raw protocol can get verbose.

PAGI-Tools is the application-side toolkit that smooths this over. It collects
the ergonomics an author reaches for again and again, so you can build real
PAGI applications without hand-emitting protocol events:

=over 4

=item * L<PAGI::Middleware> and the C<PAGI::Middleware::*> suite

=item * C<PAGI::App::*> - ready-made apps (static files, routers, proxies,
WebSocket chat/echo, PSGI bridging)

=item * L<PAGI::Endpoint::HTTP>, L<PAGI::Endpoint::Router>,
L<PAGI::Endpoint::SSE>, L<PAGI::Endpoint::WebSocket> - high-level endpoint
framework

=item * L<PAGI::Request>, L<PAGI::Response>, L<PAGI::Context> - request
processing and ergonomics

=item * L<PAGI::Test::Client> and friends - in-process test utilities for
PAGI applications

=item * L<PAGI::Utils> - composition and lifespan helpers; its
L<to_app|PAGI::Utils/to_app> coercion is what lets every composition
point above accept component objects and class names directly

=back

It is the author's hope that these tools serve two audiences: people
I<exploring> PAGI, who get going with far less friction than the raw protocol
asks for; and framework authors, who get a I<ready-made base> to build
higher-order frameworks on top of, rather than starting from C<$scope>,
C<$receive>, and C<$send> every time.

The reference server lives in the C<PAGI-Server> distribution; the
protocol specification lives in the C<PAGI> distribution.

=head1 SEE ALSO

L<PAGI::Tutorial> (the protocol tutorial, in the C<PAGI> distribution),
L<PAGI::Tools::Tutorial> (this distribution's helpers guide),
L<PAGI::Tools::Cookbook> (this distribution's recipes), L<PAGI::Spec>,
L<PAGI::Server::Runner> - runs PAGI applications from the command line
(ships with the PAGI-Server distribution)

=head1 AUTHOR

John Napiorkowski <jjnapiork@cpan.org>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as the Artistic License 2.0.

=cut
