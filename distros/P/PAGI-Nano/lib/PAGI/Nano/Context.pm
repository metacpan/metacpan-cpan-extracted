package PAGI::Nano::Context;
$PAGI::Nano::Context::VERSION = '0.001000';
use strict;
use warnings;
use Carp ();
use Encode ();

# Shared behavior mixed into every Nano context (HTTP, WebSocket, SSE) alongside
# the stock PAGI context class for that scope type. It only needs $self->{scope},
# which all of them carry. uri_for lives here (not in PAGI-Tools) because it
# resolves against the flat name registry PAGI::Nano injects on the scope — a
# Nano concept the base toolkit knows nothing about.

# Build a URL for a named route. Resolves against the flat name->path registry
# PAGI::Nano injects on the scope, so any name in the app (including across
# mounts, in either direction) is reachable.
sub uri_for {
    my ($self, $name, $path_params, $query_params) = @_;

    my $routes = $self->{scope}{'pagi.nano.routes'};
    Carp::croak('uri_for: no named-route registry on the scope '
        . '(is this a PAGI::Nano app, and is the route named?)')
        unless $routes;
    my $path = $routes->{$name};
    Carp::croak("uri_for: no route named '$name'") unless defined $path;

    $path_params  ||= {};
    $query_params ||= {};

    $path = _render_path($path, $path_params);

    if (%$query_params) {
        my @pairs;
        for my $k (sort keys %$query_params) {
            push @pairs, _uri_escape($k) . '=' . _uri_escape($query_params->{$k});
        }
        $path .= '?' . join('&', @pairs);
    }

    return $path;
}

sub _render_path {
    my ($template, $params) = @_;
    my $rendered = '';
    my $offset = 0;

    while ($template =~ /(\{(\w+)(?::[^}]*)?\}|\*(\w+)|:(\w+))/g) {
        # Capture all match state before an escaping helper runs another regex.
        my ($start, $end) = ($-[0], $+[0]);
        my ($token, $braced, $splat, $colon) = ($1, $2, $3, $4);
        $rendered .= _escape_path_literal(
            substr($template, $offset, $start - $offset)
        );

        my $name = defined $braced ? $braced
                 : defined $splat  ? $splat
                 :                   $colon;

        if (!exists $params->{$name}) {
            $rendered .= $token;
        }
        else {
            my $value = defined $params->{$name} ? "$params->{$name}" : '';
            if (defined $splat) {
                $rendered .= join '/', map { _uri_escape($_) }
                    split '/', $value, -1;
            }
            else {
                Carp::croak(
                    "uri_for: value for '$name' contains '/' -- use a *splat route for path-valued parameters"
                ) if index($value, '/') >= 0;
                $rendered .= _uri_escape($value);
            }
        }
        $offset = $end;
    }

    $rendered .= _escape_path_literal(substr($template, $offset));
    return $rendered;
}

# Resolve a declared service by name. Delegates to the registry PAGI::Nano
# injects on the scope (the same mechanism uri_for uses for named routes),
# which applies the scope-discrimination rule: an app-scoped value is returned
# as-is, a per-request maker is invoked and memoized for this request/
# connection, and a factory-marked maker is invoked fresh on every call.
sub service {
    my ($self, $name) = @_;

    my $registry = $self->{scope}{'pagi.nano.services'};
    Carp::croak("service: no service registry on the scope "
        . "(is this a PAGI::Nano app, and was '$name' declared?)")
        unless $registry;

    return $registry->_resolve($name, $self);
}

sub _utf8_bytes {
    my ($s) = @_;
    $s = '' unless defined $s;
    return Encode::encode('UTF-8', $s, Encode::FB_CROAK());
}

sub _escape_path_literal {
    my $bytes = _utf8_bytes($_[0]);
    $bytes =~ s/([^A-Za-z0-9\-._~!\$&'()*+,;=:\@\/])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

sub _uri_escape {
    my $bytes = _utf8_bytes($_[0]);
    $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

1;

=encoding utf8

=head1 NAME

PAGI::Nano::Context - Shared behavior for the contexts PAGI::Nano vends

=head1 DESCRIPTION

A mixin inherited by L<PAGI::Nano::Context::HTTP>,
L<PAGI::Nano::Context::WebSocket>, and L<PAGI::Nano::Context::SSE> alongside the
stock PAGI context class for each scope type. It provides L</uri_for> and
L</service>, both available to handlers of every protocol.

=head1 METHODS

=head2 uri_for

    my $url = $c->uri_for($name);
    my $url = $c->uri_for($name, \%path_params);
    my $url = $c->uri_for($name, \%path_params, \%query_params);

Builds the URL for a route named with L<PAGI::Nano/name>. Path placeholders
(C<:id>, C<{id}>, C<{id:regex}>, C<*splat>) are filled from C<%path_params>.
Pass decoded Perl strings, not pre-encoded URL components. Ordinary placeholders
represent one path segment and percent-encode inserted values as UTF-8 bytes;
they croak if a value contains C</>. Use C<*splat> for a path-valued parameter:
its slash separators are preserved while each segment is encoded separately.
This distinction is required because PAGI decodes percent-encoded paths,
including C<%2F>, before routing. Literal route text preserves RFC 3986 path
characters and slash separators. C<%query_params> (if any) is appended in sorted
key order with UTF-8 percent encoding and C<%20> for spaces.
Resolution is against the flat name registry PAGI::Nano injects on the scope, so
names defined anywhere in the app — including across a C<mount>, in either
direction — are reachable, with mount prefixes applied. Dies if the name is
unknown.

=head2 service

    my $value = $c->service($name);

Resolves a service declared with L<PAGI::Nano/service>. Whether this returns
the same app-scoped value every time, a per-request object built and memoized
on first access, or a fresh object on every call, is decided by what the
service's builder returned — see L<PAGI::Nano/SERVICES> for the full scoping
rule. Dies if C<$name> was never declared.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
