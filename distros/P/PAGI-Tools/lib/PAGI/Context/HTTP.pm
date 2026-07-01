package PAGI::Context::HTTP;
$PAGI::Context::HTTP::VERSION = '0.002001';
use strict;
use warnings;
use Carp qw(croak);

our @ISA = ('PAGI::Context');

=encoding UTF-8

=head1 NAME

PAGI::Context::HTTP - HTTP-specific context subclass

=head1 DESCRIPTION

Returned by C<< PAGI::Context->new(...) >> when C<< $scope->{type} >> is
C<'http'>. Adds lazy accessors for L<PAGI::Request> and L<PAGI::Response>,
plus an HTTP C<method> accessor.

Inherits all shared methods from L<PAGI::Context>.

=head1 METHODS

=head2 request

    my $req = $ctx->request;

Returns a L<PAGI::Request> instance. Lazy-constructed and cached.

=head2 response

    my $res = $ctx->response;

Returns a detached L<PAGI::Response> accumulator. Lazy-constructed and cached
for the lifetime of the context. The response holds no connection — it is a
pure value object you mutate via the chainer methods (C<status>, C<header>,
C<json>, etc.) and then pass to L</respond> when ready to send.

=head2 respond

    $ctx->respond($res);

Guarded send. Sends the L<PAGI::Response> value C<$res> over this request's
connection, marks the request as done, and returns a L<Future> that resolves
when all protocol events have been emitted.

The sent state is read from C<< $scope->{'pagi.connection'}->response_started >>,
the server-seeded per-request object — a shared reference, so the fact propagates
across the whole middleware stack even though middleware shallow-clone the scope.
A second C<respond> on the same context is rejected synchronously via a per-context
flag; the server enforces single-response at the protocol level as the backstop.

Delegates to the unguarded primitive C<< $res->respond($send) >>.

=head2 method

    my $method = $ctx->method;    # 'GET', 'POST', etc.

Returns the HTTP method from the scope.

=head2 req

    my $req = $ctx->req;

Alias for C<request>.

=head2 resp

    my $res = $ctx->resp;

Alias for C<response>.

=head2 text, html, json, redirect

    return $ctx->text('Hello');
    return $ctx->html('<h1>Hi</h1>');
    return $ctx->json({ ok => 1 });
    return $ctx->json($data, status => 201);
    return $ctx->redirect('/login');

Shorthands that set the body — and any trailing options such as C<status>,
C<headers>, or C<content_type> — on this context's L</response>, then return the
L<PAGI::Response> value, so a handler can build and return its response in a
single call. C<< $ctx->json($data) >> is exactly C<< $ctx->response->json($data) >>.
They operate on the one response accumulator, so you can still reach for
C<< $ctx->response >> to set cookies or extra headers alongside them.

=cut

sub request {
    my ($self) = @_;
    return $self->{_request} //= do {
        require PAGI::Request;
        PAGI::Request->new($self->{scope}, $self->{receive});
    };
}

sub response {
    my ($self) = @_;
    return $self->{_response} //= do {
        require PAGI::Response;
        PAGI::Response->new($self->{scope});    # detached accumulator; no $send
    };
}

sub respond {
    my ($self, $res) = @_;
    my $conn = $self->{scope} ? $self->{scope}{'pagi.connection'} : undef;
    if ($conn && !$conn->can('response_started')) {
        croak("pagi.connection lacks response_started (non-conforming server)");
    }
    croak("response already sent")
        if $self->{_responded} || ($conn && $conn->response_started);   # mutex + cross-context read
    $self->{_responded} = 1;                                            # synchronous, self-owned
    return $res->respond($self->{send});
}

sub method { shift->{scope}{method} }

sub req  { shift->request }
sub resp { shift->response }

# Value-contract response shorthands: set the body (+ opts) on the cached
# response accumulator and return it, so handlers can `return $ctx->json(...)`.
sub text     { shift->response->text(@_) }
sub html     { shift->response->html(@_) }
sub json     { shift->response->json(@_) }
sub redirect { shift->response->redirect(@_) }

1;

__END__

=head1 SEE ALSO

L<PAGI::Context>, L<PAGI::Request>, L<PAGI::Response>

=cut
