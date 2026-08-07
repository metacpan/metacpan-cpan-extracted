package Punk::Session;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Punk::Session - signed cookie sessions

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    session
        secret   => secret('session_key'),   # from the secrets system
        expires  => '7d',
        samesite => 'Lax';

    post '/login' => sub {
        my ($c) = @_;
        $c->session->{user_id} = $user->id;   # signed into the cookie
        $c->redirect('/');
    };

    get '/me' => sub {
        my ($c) = @_;
        my $id = $c->session->{user_id} or return $c->redirect('/login');
        $c->json({ id => $id });
    };

    post '/logout' => sub { my ($c) = @_; $c->session_expire; $c->redirect('/') };

=head1 DESCRIPTION

A session is a hashref carried in a cookie: the handler reads and writes
C<< $c->session >>, and at the end of the request Punk serializes it (JSON),
signs it with HMAC-SHA256 and the configured secret, and sets the cookie - only
when it actually changed. The client can read the contents but cannot forge
them, so do not put secrets in a session; a tampered cookie is rejected and the
session comes up empty.

There is no server-side store in this cut: the whole session lives in the
cookie. A session that serializes over ~4KB croaks, pointing at where a
server-side store would go.

=head1 THE KEYWORD

    session secret => secret('key'), expires => '7d', secure => 1;

Enables sessions for the application. Options:

=over 4

=item * C<secret> - the signing key (required for a real deployment); source it
from the L<secrets system|Punk/secret> so it never sits in the code.

=item * C<cookie> - the cookie name (default C<punk.sid>).

=item * C<expires> - a lifetime like C<'7d'> / C<'12h'> / C<'30m'> / seconds;
omitted means a session cookie (gone when the browser closes).

=item * C<path> (default C</>), C<domain>, C<secure>, C<httponly> (default on),
C<samesite> (default C<Lax>) - the cookie attributes.

=back

It also reads from C<config/punk.yml> under a C<session:> block.

=head1 CONTEXT METHODS

=head2 session

The session hashref. Read and write it; it is written back to the cookie at the
end of the request if it changed.

=head2 session_expire

Log out: empty the session and delete the cookie.

=head1 SEE ALSO

L<Punk>, L<Punk::Context/cookie>, L<Punk/secret>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
