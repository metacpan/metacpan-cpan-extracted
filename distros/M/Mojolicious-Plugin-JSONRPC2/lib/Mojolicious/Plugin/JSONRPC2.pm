package Mojolicious::Plugin::JSONRPC2;

use Mojo::Base 'Mojolicious::Plugin';
use Carp;

our $VERSION = 'v2.0.0';

use JSON::XS;
# to ensure callback runs on notification
use JSON::RPC2::Server 0.004000;

use constant TIMEOUT    => 5*60;    # sec
use constant HTTP_200   => 200;
use constant HTTP_204   => 204;
use constant HTTP_415   => 415;

my $Type = 'application/json';
my %HEADERS = (
    'Content-Type' => qr{\A\s*\Q$Type\E\s*(?:;|\z)}msi,
    'Accept' => qr{(?:\A|,)\s*\Q$Type\E\s*(?:[;,]|\z)}msi,
);


sub register {
    my ($self, $app, $conf) = @_;

    $app->helper(jsonrpc2_headers => sub { return %HEADERS });

    $app->routes->add_shortcut(jsonrpc2     => sub { _shortcut('POST', @_) });
    $app->routes->add_shortcut(jsonrpc2_get => sub { _shortcut('GET',  @_) });

    return;
}

sub _shortcut {
    my ($method, $r, $path, $server) = @_;
    croak 'usage: $r->jsonrpc2'.($method eq 'GET' ? '_get' : q{}).'("/rpc/path", JSON::RPC2::Server->new)'
        if !(ref $server && $server->isa('JSON::RPC2::Server'));
    return $r->any([$method] => $path, [format => 0], sub { _srv($server, @_) });
}

sub _srv {
    my ($server, $c) = @_;

    if (($c->req->headers->content_type // q{}) !~ /$HEADERS{'Content-Type'}/ms) {
        return $c->render(status => HTTP_415, data => q{});
    }
    if (($c->req->headers->accept // q{}) !~ /$HEADERS{'Accept'}/ms) {
        return $c->render(status => HTTP_415, data => q{});
    }

    $c->res->headers->content_type($Type);
    $c->render_later;

    my $timeout = $c->stash('jsonrpc2.timeout') || TIMEOUT;
    $c->inactivity_timeout($timeout);

    my $request;
    if ($c->req->method eq 'GET') {
        $request = $c->req->query_params->to_hash;
        if (exists $request->{params}) {
            $request->{params} = eval { decode_json($request->{params}) };
        }
    } else {
        $request = eval { decode_json($c->req->body) };
    }

    $server->execute($request, sub {
        my ($json_response) = @_;
        my $status = $json_response ? HTTP_200 : HTTP_204;
        $c->render(status => $status, data => $json_response);
    });

    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::JSONRPC2 - JSON-RPC 2.0 over HTTP


=head1 VERSION

This document describes Mojolicious::Plugin::JSONRPC2 version v2.0.0


=head1 SYNOPSIS

    use JSON::RPC2::Server;

  # in Mojolicious app
  sub startup {
    my $app = shift;
    $app->plugin('JSONRPC2');

    my $server = JSON::RPC2::Server->new();

    $r->jsonrpc2('/rpc', $server);
    $r->jsonrpc2_get('/rpc', $server)->over(headers => { $app->jsonrpc2_headers });


=head1 DESCRIPTION

L<Mojolicious::Plugin::JSONRPC2> is a plugin that allow you to handle
some routes in L<Mojolicious> app using JSON-RPC 2.0 over HTTP protocol.

Implements this spec: L<http://www.simple-is-better.org/json-rpc/transport_http.html>.
The "pipelined Requests/Responses" is not supported yet.

=head1 INTERFACE

=over

=item $app->defaults( 'jsonrpc2.timeout' => 300 )

Configure timeout for RPC requests in seconds (default value 5 minutes).

=item $r->jsonrpc2($path, $server)

Add handler for JSON-RPC 2.0 over HTTP protocol on C<$path>
(with C<< format=>0 >>) using C<POST> method.

RPC functions registered with C<$server> will be called only with their
own parameters (provided with RPC request) - if they will need access to
Mojolicious app you'll have to provide it manually (using global vars or
closures).

=item $r->jsonrpc2_get($path, $server_safe_idempotent)

B<WARNING!> In most cases you don't need it. In other cases usually you'll
have to use different C<$server> objects for C<POST> and C<GET> because
using C<GET> you can provide only B<safe and idempotent> RPC functions
(because of C<GET> semantic, caching/proxies, etc.).

Add handler for JSON-RPC 2.0 over HTTP protocol on C<$path>
(with C<< format=>0 >>) using C<GET> method.

RPC functions registered with C<$server_safe_idempotent> will be called only with their
own parameters (provided with RPC request) - if they will need access to
Mojolicious app you'll have to provide it manually (using global vars or
closures).

=item $r->over(headers => { $app->jsonrpc2_headers })

You can use this condition to distinguish between JSON-RPC 2.0 and other
request types on same C<$path> - for example if you want to serve web page
and RPC on same url you can do this:

    my $r = $app->routes;
    $r->jsonrpc2_get('/', $server)->over(headers=>{$app->jsonrpc2_headers});
    $r->get('/')->to('controller#action');

If you don't use this condition and plugin's handler will get request with
wrong headers it will reply with C<415 Unsupported Media Type>.

=back


=head1 OPTIONS

L<Mojolicious::Plugin::JSONRPC2> has no options.


=head1 METHODS

L<Mojolicious::Plugin::JSONRPC2> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register hooks in L<Mojolicious> application.


=head1 SEE ALSO

L<JSON::RPC2::Server>, L<Mojolicious>, L<MojoX::JSONRPC2::HTTP>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Mojolicious-Plugin-JSONRPC2/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Mojolicious-Plugin-JSONRPC2>

    git clone https://github.com/powerman/perl-Mojolicious-Plugin-JSONRPC2.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Mojolicious-Plugin-JSONRPC2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Mojolicious-Plugin-JSONRPC2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-JSONRPC2>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-JSONRPC2>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-JSONRPC2>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut

