package Mojolicious::Plugin::Fondation::SessionStore;
$Mojolicious::Plugin::Fondation::SessionStore::VERSION = '0.01';
# ABSTRACT: Fondation plugin — server-side session storage via Mojolicious::Sessions::Store

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojolicious::Sessions::Store;
use Mojolicious::Sessions::Store::Backend::File;
use Bytes::Random::Secure;
use Mojo::File;


sub fondation_meta {
    return {
        dependencies => [],
        before       => [ 'Fondation::Auth' ],
        defaults     => {
            backend   => 'file',
            store_dir => undef,       # resolved at startup: $app->home->child('data/sessions')
            session   => {
                cookie_name        => 'fondation',
                default_expiration => 1800,
            },
        },
    };
}

sub register ($self, $app, $config) {

    # ── Resolve store_dir ──────────────────────────────────────────────
    my $store_dir = $config->{store_dir}
        // $app->home->child('data/sessions')->to_string;

    # ── Auto-generate secrets if using insecure default ─────────────────
    _ensure_secrets($self, $app);

    # ── Instantiate backend ────────────────────────────────────────────
    my $backend;
    if (ref $config->{backend}) {
        # Direct backend instance (useful for tests)
        $backend = $config->{backend};
    }
    elsif ($config->{backend} eq 'file') {
        $backend = Mojolicious::Sessions::Store::Backend::File->new(
            store_dir => $store_dir,
        );
    }
    else {
        die "Unknown session store backend: $config->{backend}";
    }

    # ── Create Sessions::Store and replace app sessions ────────────────
    my %session_opts = %{$config->{session} // {}};
    my $store = Mojolicious::Sessions::Store->new(
        backend => $backend,
        %session_opts,
    );
    $app->sessions($store);

    $self->log->debug(
        sprintf("Using backend '%s' at %s",
            $config->{backend}, $store_dir));

    return $self;
}

# ── Internal: auto-generate secrets if default (CVE-2024-58134) ─────────

sub _ensure_secrets ($self, $app) {
    # Only act if secrets are the default (moniker-derived — predictable)
    my $secrets = $app->secrets;
    return unless @$secrets == 1 && $secrets->[0] eq $app->moniker;

    my $secret_file = $app->home->child('data/session_store_secret');

    if (-f $secret_file) {
        my $secret = $secret_file->slurp;
        chomp $secret;
        $app->secrets([$secret]) if length $secret >= 32;
        return;
    }

    # Generate and persist a new secret
    my $random = Bytes::Random::Secure->new;
    my $secret = unpack('H*', $random->bytes(32));
    $secret_file->dirname->make_path;
    $secret_file->spurt($secret);
    $app->secrets([$secret]);

    $self->log->warn(
        "Auto-generated secret saved to $secret_file.\n"
        . "  Set \$app->secrets(['your-secret-here']) explicitly in production.");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::SessionStore - Fondation plugin — server-side session storage via Mojolicious::Sessions::Store

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In myapp.pl or myapp.conf
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::SessionStore',
        ],
    };

    # With custom configuration
    plugin 'Fondation' => {
        dependencies => [
            { 'Fondation::SessionStore' => {
                backend   => 'file',
                store_dir => '/var/lib/myapp/sessions',
                session   => {
                    cookie_name        => 'myapp',
                    default_expiration => 3600,
                },
            }},
        ],
    };

=head1 DESCRIPTION

C<Mojolicious::Plugin::Fondation::SessionStore> replaces the default
signed-cookie session storage with server-side storage via
L<Mojolicious::Sessions::Store>.

A signed cookie containing only a session ID is sent to the client;
the actual session data lives in a backend (filesystem by default).

The L<Mojolicious::Controller> C<session> helper works unchanged.

=head1 NAME

Mojolicious::Plugin::Fondation::SessionStore - Server-side session storage for Fondation

=head1 WHY SERVER-SIDE STORAGE?

By default, Mojolicious stores session data directly in a signed cookie.
The cookie I<is> the session — serialized, signed, but still readable by
the client (base64-encoded, not encrypted). This plugin opts for server-side
storage instead, for three key reasons:

=over 4

=item Security

Only an opaque session ID is sent to the browser. The actual session data
(user ID, roles, permissions, etc.) never leaves the server.

=item Revocation

Sessions can be destroyed server-side at any time — useful for forced
logout, password resets, or banning users. With cookie-only sessions,
the cookie remains valid until it expires, regardless of server intent.

=item Size

Cookies are limited to roughly 4 KB. Server-side sessions have no such
constraint, allowing larger payloads when needed.

=back

=head1 CONFIGURATION

All keys are optional and can be overridden in C<myapp.pl> or C<myapp.conf>.

=over 4

=item backend

Backend name (C<file>) or a backend instance (for testing).
Default: C<file>.

=item store_dir

Directory for session files when using the C<file> backend.
Default: C<$app-E<gt>home/data/sessions>.

=item session

Hashref of session options passed to L<Mojolicious::Sessions::Store>:

=over 4

=item cookie_name

Session cookie name. Default: C<fondation>.

=item default_expiration

Session lifetime in seconds. Default: C<1800> (30 minutes).

=back

=back

=head1 BACKENDS

=over 4

=item file

L<Mojolicious::Sessions::Store::Backend::File> — JSON files on disk.

=back

Future: C<redis>, C<dbi>.

=head1 DEPENDENCIES

L<Mojolicious::Sessions::Store> (standalone, no Fondation dependency).

=head1 SEE ALSO

L<Mojolicious::Sessions::Store>,
L<Mojolicious::Sessions::Store::Backend::File>,
L<Mojolicious::Plugin::Fondation>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
