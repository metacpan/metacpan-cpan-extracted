package PAGI::Endpoint::HTTP;
$PAGI::Endpoint::HTTP::VERSION = '0.002000';
use strict;
use warnings;

use Future::AsyncAwait;
use Carp qw(croak);
use Scalar::Util qw(blessed);

# Factory class method - override in subclass for customization
sub context_class { 'PAGI::Context' }

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

# HTTP methods we support
our @HTTP_METHODS = qw(get post put patch delete head options);

sub allowed_methods {
    my ($self) = @_;
    my @allowed;
    for my $method (@HTTP_METHODS) {
        push @allowed, uc($method) if $self->can($method);
    }
    # HEAD is allowed if GET is defined
    push @allowed, 'HEAD' if $self->can('get') && !$self->can('head');
    # OPTIONS is always allowed
    push @allowed, 'OPTIONS' unless grep { $_ eq 'OPTIONS' } @allowed;
    return sort @allowed;
}

async sub dispatch {
    my ($self, $ctx) = @_;
    my $http_method = lc($ctx->method // 'GET');

    my $res;

    # OPTIONS - return allowed methods (auto-respond unless overridden)
    if ($http_method eq 'options' && !$self->can('options')) {
        my $allow = join(', ', $self->allowed_methods);
        $res = $ctx->response->header('Allow', $allow)->empty;
    }
    # HEAD falls back to GET if not explicitly defined
    elsif ($http_method eq 'head' && !$self->can('head') && $self->can('get')) {
        $res = await $self->get($ctx);
    }
    # Dispatch to the appropriate method handler
    elsif ($self->can($http_method)) {
        $res = await $self->$http_method($ctx);
    }
    # 405 Method Not Allowed
    else {
        my $allow = join(', ', $self->allowed_methods);
        $res = $ctx->response->header('Allow', $allow)->status(405)->text("405 Method Not Allowed");
    }

    croak ref($self) . "->$http_method did not return a response"
        unless blessed($res) && $res->can('respond');
    await $ctx->respond($res);
}

sub to_app {
    my ($class) = @_;
    my $context_class = $class->context_class;
    my $endpoint = $class->new;    # ONE instance for the app lifetime (singleton)

    return async sub {
        my ($scope, $receive, $send) = @_;

        my $type = $scope->{type} // 'http';
        croak "Expected http scope, got '$type'" unless $type eq 'http';

        require PAGI::Context;
        my $ctx = $context_class->new($scope, $receive, $send);

        await $endpoint->dispatch($ctx);
    };
}

1;

__END__

=head1 NAME

PAGI::Endpoint::HTTP - Class-based HTTP endpoint handler

=head1 SYNOPSIS

    package MyApp::UserAPI;
    use parent 'PAGI::Endpoint::HTTP';
    use Future::AsyncAwait;

    async sub get {
        my ($self, $ctx) = @_;
        my $users = get_all_users();
        return $ctx->json($users);
    }

    async sub post {
        my ($self, $ctx) = @_;
        my $data = await $ctx->request->json;
        my $user = create_user($data);
        return $ctx->json($user, status => 201);
    }

    async sub delete {
        my ($self, $ctx) = @_;
        my $id = $ctx->request->path_param('id');
        delete_user($id);
        return $ctx->response->status(204)->empty;
    }

    # Use with PAGI server
    my $app = MyApp::UserAPI->to_app;

=head1 DESCRIPTION

PAGI::Endpoint::HTTP provides a Starlette-inspired class-based approach
to handling HTTP requests. Define methods named after HTTP verbs (get,
post, put, patch, delete, head, options) and the endpoint automatically
dispatches to them.

=head2 Features

=over 4

=item * Automatic method dispatch based on HTTP verb

=item * 405 Method Not Allowed for undefined methods

=item * OPTIONS handling with Allow header

=item * HEAD falls back to GET if not defined

=item * Customizable context class for framework integration

=back

=head1 HTTP METHODS

Define any of these async methods to handle requests:

    async sub get { my ($self, $ctx) = @_; ... }
    async sub post { my ($self, $ctx) = @_; ... }
    async sub put { my ($self, $ctx) = @_; ... }
    async sub patch { my ($self, $ctx) = @_; ... }
    async sub delete { my ($self, $ctx) = @_; ... }
    async sub head { my ($self, $ctx) = @_; ... }
    async sub options { my ($self, $ctx) = @_; ... }

Each receives:

=over 4

=item C<$self> - The endpoint instance

=item C<$ctx> - A L<PAGI::Context::HTTP> instance

=back

Use C<< $ctx->request >> for request data and C<< $ctx->response >> for
building responses.

B<Handler contract:> Every HTTP handler MUST return a respond-able value
(e.g. C<< return $ctx->json(...) >>). Returning nothing (or an
object without a C<respond> method) causes dispatch to croak. The return
value is what dispatch sends to the client via C<< $ctx->respond($res) >>.

B<Singleton:> C<to_app> creates a single endpoint instance that serves the
entire application lifetime. State stored in C<$self> persists across
requests (within the same worker process).

B<Do not store per-request state on C<$self>> - one instance is shared by
every request (and concurrent requests), so request-scoped data on C<$self>
will leak between them. Keep configuration and long-lived services on
C<$self>; put request-scoped data on C<$ctx> (e.g. C<< $ctx->stash >>).

=head1 CLASS METHODS

=head2 to_app

    my $app = MyEndpoint->to_app;

Returns a PAGI-compatible async coderef that can be used directly
with PAGI::Server or composed with middleware. Creates a single endpoint
instance at construction time; that instance is reused for every request
(singleton).

=head2 context_class

    sub context_class { 'PAGI::Context' }

Override to use a custom context class.

=head1 INSTANCE METHODS

=head2 dispatch

    await $endpoint->dispatch($ctx);

Dispatches the request to the appropriate HTTP method handler.
Called automatically by C<to_app>.

=head2 allowed_methods

    my @methods = $endpoint->allowed_methods;

Returns list of HTTP methods this endpoint handles.

=head1 FRAMEWORK INTEGRATION

Framework designers can subclass and customize via context:

    package MyFramework::Endpoint;
    use parent 'PAGI::Endpoint::HTTP';

    sub context_class { 'MyFramework::Context' }

=head1 SEE ALSO

L<PAGI::Context>, L<PAGI::Endpoint::WebSocket>, L<PAGI::Endpoint::SSE>,
L<PAGI::Request>, L<PAGI::Response>

=cut
