package PAGI::Middleware::CSRF;
$PAGI::Middleware::CSRF::VERSION = '0.002002';
use strict;
use warnings;
use parent 'PAGI::Middleware';
use Future::AsyncAwait;
use Digest::SHA qw(sha256_hex);
use PAGI::Utils::Random qw(secure_random_bytes);
use PAGI::Utils::SecureCompare qw(secure_compare);

=head1 NAME

PAGI::Middleware::CSRF - Cross-Site Request Forgery protection middleware

=head1 SYNOPSIS

    use PAGI::Middleware::Builder;

    my $app = builder {
        enable 'CSRF',
            secret       => 'your-secret-key',
            token_header => 'X-CSRF-Token',
            cookie_name  => 'csrf_token',
            safe_methods => ['GET', 'HEAD', 'OPTIONS'];
        $my_app;
    };

    # Issue-only mode: the middleware never rejects; the app validates via
    # $ctx->csrf_verify once it has parsed the submitted form/JSON params.
    my $app2 = builder {
        enable 'CSRF', secret => 'your-secret-key', enforce => 'app';
        $my_app;
    };

=head1 DESCRIPTION

PAGI::Middleware::CSRF provides protection against Cross-Site Request
Forgery attacks by validating tokens on state-changing requests.

=head1 CONFIGURATION

=over 4

=item * secret (required)

Secret key used for token generation.

=item * token_header (default: 'X-CSRF-Token')

Header name to look for the CSRF token.

=item * cookie_name (default: 'csrf_token')

Cookie name for the CSRF token.

=item * safe_methods (default: ['GET', 'HEAD', 'OPTIONS', 'TRACE'])

HTTP methods that don't require CSRF validation.

=item * secure (default: 0)

Add the C<Secure> attribute to the CSRF cookie, restricting it to HTTPS
requests. Off by default so plain-HTTP development setups keep working;
for production HTTPS deployments, add C<< secure => 1 >>.

=item * enforce (default: 'header')

How unsafe methods (anything not in C<safe_methods>) are checked:

=over 4

=item * C<'header'> - the middleware itself validates: the request must
carry a C<token_header> whose value matches the cookie token, or the
middleware responds 403 and the app is never called. This only works for
requests that can set a custom header (typically AJAX/fetch); a plain HTML
form POST has no way to add one, so a server-rendered form under this mode
would always 403 -- see L</USAGE> for why.

=item * C<'app'> - issue-only. The middleware mints/persists the cookie
token exactly as it does for safe methods, on I<every> method, and never
auto-rejects. It stashes the cookie token (the existing one, or a freshly
minted one if none existed yet) into scope as C<csrf_token> for the app to
read via C<< $ctx->csrf_token >>. The app owns validation, by calling
C<< $ctx->csrf_verify($submitted) >> once it has parsed the request's
params, and decides the response for a failed check. This is what
server-rendered form POSTs need.

=back

=back

=cut

sub _init {
    my ($self, $config) = @_;

    $self->{secret}       = $config->{secret} // die "CSRF middleware requires 'secret' option";
    $self->{token_header} = $config->{token_header} // 'X-CSRF-Token';
    $self->{cookie_name}  = $config->{cookie_name} // 'csrf_token';
    $self->{safe_methods} = { map { $_ => 1 } @{$config->{safe_methods} // [qw(GET HEAD OPTIONS TRACE)]} };
    $self->{secure}       = $config->{secure} // 0;

    $self->{enforce} = $config->{enforce} // 'header';
    die "CSRF middleware 'enforce' must be 'header' or 'app', got '$self->{enforce}'"
        unless $self->{enforce} eq 'header' || $self->{enforce} eq 'app';
}

sub wrap {
    my ($self, $app) = @_;

    return async sub  {
        my ($scope, $receive, $send) = @_;
        # Only handle HTTP requests
        if ($scope->{type} ne 'http') {
            await $app->($scope, $receive, $send);
            return;
        }

        my $method = $scope->{method};

        # Get existing token from cookie
        my $cookie_token = $self->_get_cookie_token($scope);

        # Generate new token if none exists
        my $token = $cookie_token // $self->_generate_token();

        # Safe methods always just issue the token. Under enforce => 'app', unsafe
        # methods do too: the middleware never validates, it only issues; the app
        # calls $ctx->csrf_verify once it has parsed the submitted params. Either
        # way $token is the existing cookie token if there was one, never a
        # regenerated one, so a submitted form token still has something to match.
        if ($self->{safe_methods}{$method} || $self->{enforce} eq 'app') {
            my $modified_scope = $self->modify_scope($scope, {
                csrf_token => $token,
            });

            # Add Set-Cookie if token is new
            my $wrapped_send = $cookie_token ? $send : async sub {
                my ($event) = @_;
                if ($event->{type} eq 'http.response.start') {
                    my $cookie = "$self->{cookie_name}=$token; Path=/; HttpOnly; SameSite=Strict";
                    $cookie .= "; Secure" if $self->{secure};
                    push @{$event->{headers}}, ['Set-Cookie', $cookie];
                }
                await $send->($event);
            };

            await $app->($modified_scope, $receive, $wrapped_send);
            return;
        }

        # Unsafe method under enforce => 'header': the middleware validates itself.
        my $submitted_token = $self->_get_submitted_token($scope);

        # Use timing-safe comparison to prevent timing attacks
        if (!$submitted_token || !$cookie_token || !secure_compare($submitted_token, $cookie_token)) {
            await $self->_send_error($send, 403, 'CSRF token validation failed');
            return;
        }

        # Token valid, continue with request
        my $modified_scope = $self->modify_scope($scope, {
            csrf_token => $token,
        });

        await $app->($modified_scope, $receive, $send);
    };
}

sub _generate_token {
    my ($self) = @_;

    # Use cryptographically secure random bytes
    my $random = secure_random_bytes(32);
    return sha256_hex($self->{secret} . time() . $random . $$);
}

sub _get_cookie_token {
    my ($self, $scope) = @_;

    my $cookie_header = $self->_get_header($scope, 'cookie');
    return unless $cookie_header;

    my $name = $self->{cookie_name};
    if ($cookie_header =~ /(?:^|;\s*)\Q$name\E=([^;]+)/) {
        return $1;
    }
    return;
}

sub _get_submitted_token {
    my ($self, $scope) = @_;
    return $self->_get_header($scope, $self->{token_header});
}

sub _get_header {
    my ($self, $scope, $name) = @_;

    $name = lc($name);
    for my $h (@{$scope->{headers} // []}) {
        return $h->[1] if lc($h->[0]) eq $name;
    }
    return;
}

async sub _send_error {
    my ($self, $send, $status, $message) = @_;

    await $send->({
        type    => 'http.response.start',
        status  => $status,
        headers => [
            ['content-type', 'text/plain'],
            ['content-length', length($message)],
        ],
    });
    await $send->({
        type => 'http.response.body',
        body => $message,
        more => 0,
    });
}

1;

__END__

=head1 USAGE

The CSRF middleware always uses a double-submit cookie pattern: a token is
generated and stored in an C<HttpOnly> cookie, and a request is only valid if
it also carries that same token some other way -- because C<HttpOnly> means
client-side JavaScript cannot read the cookie itself (C<document.cookie>
won't show it, and neither would a hypothetical C<getCookie> helper). That
"some other way" is where the two C<enforce> modes diverge.

=head2 Header flow (enforce => 'header', the default)

Use this for JSON/AJAX APIs, where the client can set a custom request
header. The middleware validates the header itself; the app is never called
on a mismatch.

Render the token into the page once (a C<< <meta> >> tag is the usual spot),
reading it from the context helper -- B<not> from the cookie, which
JavaScript cannot see:

    <meta name="csrf-token" content="<%= $ctx->csrf_token %>">

Then have client-side script read the meta tag and send it back as the
configured header:

    const token = document.querySelector('meta[name="csrf-token"]').content;
    fetch('/api/resource', {
        method: 'POST',
        headers: { 'X-CSRF-Token': token },
    });

=head2 Form flow (enforce => 'app')

Use this for server-rendered HTML forms. A plain C<< <form> >> POST has no
way to add a custom header, so C<enforce => 'header'> would 403 every such
submission -- that's precisely why this mode exists: the middleware only
issues the token (on every method, including the POST itself) and never
auto-rejects; the app validates once it has parsed the submitted params.

Embed the token as a hidden field:

    <input type="hidden" name="_csrf_token" value="<%= $ctx->csrf_token %>">

Then, in the handler, verify the submitted value against the one the
middleware stashed in scope:

    return $ctx->text('CSRF token validation failed', status => 403)
        unless $ctx->csrf_verify($params->{_csrf_token});

See L<PAGI::Context/csrf_token> and L<PAGI::Context/csrf_verify> for the
helper reference.

=head1 SEE ALSO

L<PAGI::Middleware> - Base class for middleware

L<PAGI::Context/csrf_token>, L<PAGI::Context/csrf_verify> - context helpers
for reading and checking the token, used by the C<enforce =E<gt> 'app'> flow

=cut
