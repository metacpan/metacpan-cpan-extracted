package Mojolicious::Sessions::Store;
$Mojolicious::Sessions::Store::VERSION = '0.01';
# ABSTRACT: another server-side session storage for Mojolicious

use Mojo::Base 'Mojolicious::Sessions', -signatures;
use Bytes::Random::Secure;

has 'backend';    # backend instance (Mojolicious::Sessions::Store::Backend)

# ── Session ID management ───────────────────────────────────────────────

sub _session_id ($self, $c) {
    return $c->stash('mojo.session_id') if $c->stash('mojo.session_id');

    my $value = $c->signed_cookie($self->cookie_name);
    return undef unless $value;

    $c->stash('mojo.session_id' => $value);
    return $value;
}

sub _generate_session_id ($self) {
    my $random = Bytes::Random::Secure->new;
    return unpack('H*', $random->bytes(32));
}

# ── Override load() ─────────────────────────────────────────────────────

sub load ($self, $c) {
    my $session_id = $self->_session_id($c);
    return unless $session_id;

    my $session = $self->backend->load($session_id);
    return unless $session && ref $session eq 'HASH';

    # Check absolute expiration
    my $expires = delete $session->{expires};
    if (defined $expires && $expires <= time) {
        $self->backend->delete($session_id);
        return;
    }

    my $stash = $c->stash;
    return unless $stash->{'mojo.active_session'} = keys %$session;

    $stash->{'mojo.session'} = $session;

    # Move new_flash to flash (one-request flash mechanism)
    $session->{flash} = delete $session->{new_flash} if $session->{new_flash};
}

# ── Override store() ────────────────────────────────────────────────────

sub store ($self, $c) {
    my $stash = $c->stash;

    # No session data — clear the cookie and delete from backend
    unless ($stash->{'mojo.session'} || $stash->{'mojo.active_session'}) {
        my $session_id = $self->_session_id($c);
        if ($session_id) {
            $self->backend->delete($session_id);
            delete $c->stash->{'mojo.session_id'};
        }
        $c->signed_cookie($self->cookie_name => '', {expires => 1});
        return;
    }

    my $session = $stash->{'mojo.session'} || {};

    # Flash handling (mirrors Mojolicious::Sessions)
    my $old = delete $session->{flash};
    $session->{new_flash} = $old if $stash->{'mojo.static'};
    delete $session->{new_flash} unless $session->{new_flash} && keys %{$session->{new_flash}};

    # Compute expires
    my $expiration = $session->{expiration} // $self->default_expiration;
    my $default    = delete $session->{expires};
    $session->{expires} = $default || time + $expiration if $expiration || $default;

    # Get or create session ID
    my $session_id = $self->_session_id($c) || $self->_generate_session_id();

    # If the session is being explicitly expired (expires in the past), delete it now
    if ($session->{expires} && $session->{expires} <= time) {
        $self->backend->delete($session_id);
        delete $c->stash->{'mojo.session_id'};
        $c->signed_cookie($self->cookie_name => '', {expires => 1});
        return;
    }

    $c->stash('mojo.session_id' => $session_id);

    # Persist to backend
    $self->backend->save($session_id, $session);

    # Set signed cookie containing only the session ID
    $c->signed_cookie(
        $self->cookie_name => $session_id,
        {
            domain   => $self->cookie_domain,
            expires  => $session->{expires},
            httponly => 1,
            path     => $self->cookie_path,
            ($self->samesite ? (samesite => $self->samesite) : ()),
            ($self->secure   ? (secure   => 1)               : ()),
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Sessions::Store - another server-side session storage for Mojolicious

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Mojolicious::Lite;
    use Mojolicious::Sessions::Store;
    use Mojolicious::Sessions::Store::Backend::File;

    app->sessions(
        Mojolicious::Sessions::Store->new(
            backend => Mojolicious::Sessions::Store::Backend::File->new(
                store_dir => app->home->child('data/sessions'),
            ),
            cookie_name        => 'myapp',
            default_expiration => 3600,
        )
    );

    get '/' => sub ($c) {
        $c->session(user_id => 42);
        $c->render(text => 'Session stored server-side');
    };

    app->start;

=head1 DESCRIPTION

C<Mojolicious::Sessions::Store> replaces the default signed-cookie session
storage with server-side storage. A signed cookie containing only a
session ID is sent to the client; the actual session data lives in a
backend (filesystem, Redis, database, etc.).

The L<Mojolicious::Controller> C<session> helper works exactly as before
— the change is transparent to application code.

=head1 NAME

Mojolicious::Sessions::Store - Server-side session storage for Mojolicious

=head1 ATTRIBUTES

C<Mojolicious::Sessions::Store> inherits all attributes from
L<Mojolicious::Sessions> and adds the following.

=head2 backend

    my $backend = $store->backend;
    $store      = $store->backend($backend);

The backend instance that provides C<load>, C<save>, and C<delete> methods.
Required. See L<Mojolicious::Sessions::Store::Backend> for the interface.

=head1 INHERITED ATTRIBUTES

All attributes from L<Mojolicious::Sessions> are supported, including:

=over 4

=item cookie_domain

=item cookie_name

=item cookie_path

=item default_expiration

=item samesite

=item secure

=back

=head1 HOW IT WORKS

On C<load()>:

=over 4

=item 1. Read the signed cookie to extract the session ID.

=item 2. Call C<< $backend->load($session_id) >> to retrieve session data.

=item 3. Check expiration (C<expires> field).

=item 4. Store the hashref in C<< $c->stash('mojo.session') >>.

=back

On C<store()>:

=over 4

=item 1. Read session data from C<< $c->stash('mojo.session') >>.

=item 2. Generate a new session ID if this is the first write.

=item 3. Call C<< $store->save($session_id, $data) >>.

=item 4. Set a signed cookie containing only the session ID.

=back

=head1 BACKENDS

=over 4

=item L<Mojolicious::Sessions::Store::Backend::File> — JSON files on disk

=back

Custom backends must implement C<load>, C<save>, and C<delete> as
described in L<Mojolicious::Sessions::Store::Backend>.

=head1 SEE ALSO

L<Mojolicious::Sessions>, L<Mojolicious::Sessions::Store::Backend>,
L<Mojolicious::Sessions::Store::Backend::File>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
