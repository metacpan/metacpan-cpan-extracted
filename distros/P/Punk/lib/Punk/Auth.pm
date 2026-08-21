package Punk::Auth;

use 5.010;
use strict;
use warnings;
use Punk ();
use Punk::Auth::Password;

our $VERSION = '0.27';

# The whole battery is C (punk_auth.h + xs/auth.xs): the guard fast path,
# current_user and the await seam, check_password with the dummy-verify
# rule, and the token pair. This file is documentation, plus the load of
# the KDF's cost variable.

1;

__END__

=head1 NAME

Punk::Auth - the authentication battery

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    session secret => secret('session_key');
    auth    model  => 'User',
            roles  => sub { my ($c, $user) = @_; $user->{role} };

    my $account = under '/account' => auth_guard;
    my $admin   = under '/admin'   => auth_guard(role => 'admin');

    post '/login' => sub {
        my ($c) = @_;
        my $user = $c->model('User')->get(email => $c->param('email'));
        return $c->redirect('/login')
            unless $c->check_password($user, $c->param('password'));
        $c->login($user);
        return $c->redirect('/account');
    };

    post '/logout' => sub { $_[0]->logout->redirect('/') };

=head1 DESCRIPTION

Authentication for Punk applications: a signed-in identity over the session,
a memoized C<current_user>, password hashing in C (L<Punk::Auth::Password>),
and guards for C<under> that replace the per-action boilerplate. The common
guard case - is anyone signed in - runs entirely in C: one session load, one
hash fetch.

Needs the C<session> keyword; C<to_app> croaks without it.

=head1 THE KEYWORD

    auth model       => 'User',
         fields      => { id       => 'id',
                          email    => 'email',
                          password => 'password_hash',
                          verified => 'verified' },
         session_key => 'user_id',
         login_path  => '/login',
         iterations  => 60_000,
         roles       => sub { my ($c, $user) = @_; ... },
         rank        => [qw(member admin owner)];

Everything shown is the default except C<model> and C<roles>, which have
none. C<model> names the L<Punk::Model> class C<current_user> loads through;
the C<fields> map renames columns, so an existing schema needs no migration.
C<roles> returns what the user holds - one role name, a list, or an
arrayref; a user can hold several at once. C<rank> orders the ladder names
so C<< auth_guard(role => 'admin') >> means "admin or better". A required
role that is B<not> in the ladder is orthogonal and matches by exact
membership - which is how a platform-staff role lives alongside tenant
roles without inventing a rung for it:

    roles => sub {
        my ($c, $user) = @_;
        my @r = ($user->{role});
        push @r, 'staff' if is_staff($user);
        return @r;
    };
    under '/internal' => auth_guard(role => 'staff', on_denied => '404');

A C<'Controller#method'> string for C<roles> resolves at C<to_app>, so a
typo croaks at boot. C<auth 0> turns the battery off. Unknown options
croak - a misspelled auth option must not become a silently open door. It
also reads an C<auth:> block from F<config/punk.yml>.

=head1 GUARDS

    my $s = under '/account' => auth_guard;
    under '/admin' => auth_guard(role => 'admin');
    under '/staff' => auth_guard(role => 'admin', on_denied => '404');
    auth_guard(verified => 1);

C<auth_guard> returns an ordinary guard: a reference return short-circuits,
anything else continues. Denial negotiates on the request's C<Accept> - a
client asking for C<text/html> is redirected to C<login_path> with
C<?to=E<lt>pathE<gt>> so a login can return the user where they were headed;
anything else gets a C<401> in the house error shape. C<on_denied> overrides
with C<'403'>, C<'404'> (for pages whose existence is nobody's business - the
staff-area convention) or a coderef receiving the context.

The C<?to=> Punk writes is a percent-encoded relative path, but the value
your login form reads back is whatever the browser sent, and someone else may
have written that link. Put it through L<< C<< $c->safe_path >>|Punk::Context/safe_path >>
before redirecting to it, or a crafted C<?to=> turns your login into an open
redirect:

    post '/login' => sub {
        my ($c) = @_;
        ...
        $c->redirect($c->safe_path($c->param('to'), '/'));
    };

A passing guard records what it knows in C<< $c->stash->{auth} >> -
C<user_id> always, C<user> and C<roles> (an arrayref of everything the
roles hook returned) when the guard loaded them - the same slot the
L<Open::API> security checkers use.

=head1 CONTEXT METHODS

=head2 login($user_or_id)

Record the signed-in user in the session (a row hashref uses its id field).
This is the one primitive the federation half shares: a
L<Punk::OAuth2|https://metacpan.org/pod/Punk::OAuth2> C<on_login> body ends
in C<< $c->login($user) >>.

=head2 logout

Empty the session and delete its cookie. Chains.

=head2 auth_id

The signed-in id straight off the session - no database. The shape
C<oauth2_server>'s C<authenticate> wants.

=head2 current_user

The user row, loaded once per request through the configured model and
memoized; C<undef> when nobody is signed in or the row is gone. Works on
both model backends - a future-returning backend is awaited.

=head2 check_password($user, $password)

True when the password matches the user's stored hash. When there is no
user or no hash it burns the same PBKDF2 work before returning false, so
login response time cannot reveal which emails exist. Pair it with
C<needs_rehash> for opportunistic cost upgrades:

    if ($c->check_password($user, $pw)) {
        if (Punk::Auth::Password::needs_rehash($user->{password_hash})) {
            $c->model('User')->update({ id => $user->{id},
                password_hash => Punk::Auth::Password::hash($pw) });
        }
        $c->login($user);
    }

=head2 issue_token($user_id, $kind, $ttl)

    my $token = $c->issue_token($user->{id}, 'verify', 60 * 60 * 48);
    # mail base_url . "/verify/$token" - the plaintext exists only here

A single-use token on the configured C<token_model>. Only the SHA-256
digest is stored, with an absolute expiry epoch; issuing a new token
invalidates the user's older tokens of the same kind, so a re-sent mail
leaves exactly one live link.

=head2 take_token($token, @kinds)

    my $row = $c->take_token($c->param('token'), 'reset', 'invite')
        or return $c->text('that link has expired', 410);

The row, or nothing. The order inside is deliberate and inherited from
production: the token is deleted B<first>, then kind and expiry are
checked - it is spent whether or not it turns out valid, so a wrong-kind
probe burns it rather than leaving it live for its real endpoint.

=head1 THE SCHEMA

The defaults expect (spellings adjustable through C<fields>):

    CREATE TABLE users (
        id            bigserial PRIMARY KEY,
        email         text NOT NULL,
        password_hash text,              -- null: invited or federated-only
        verified      integer NOT NULL DEFAULT 0
    );
    CREATE UNIQUE INDEX users_email ON users (lower(email));

A null password hash is meaningful: the account exists (an invite, or a
federated sign-in) but no password has been set; C<check_password> is simply
false for it.

The token model (any name; declare it with C<< auth token_model => ... >>):

    CREATE TABLE auth_tokens (
        id      bigserial PRIMARY KEY,
        user_id bigint NOT NULL,
        kind    text   NOT NULL,        -- verify | reset | invite | yours
        digest  text   NOT NULL,
        expires bigint NOT NULL         -- absolute epoch, compared in Perl
    );
    CREATE UNIQUE INDEX auth_tokens_digest ON auth_tokens (digest);

Single use is the delete plus the unique digest index; there is no
C<used_at> audit trail. Expired rows that were never taken are not
reaped automatically - run

    DELETE FROM auth_tokens WHERE expires < extract(epoch from now());

on whatever schedule suits (a L<Punk::Queue> cron task is the natural
home).

=head1 COMPOSING WITH OAUTH2

Local and federated sign-in meet at C<< $c->login >>:

    oauth2_login '/auth' => { on_login => sub {
        my ($c, $identity, $tokens) = @_;
        return $c->redirect('/login?error=oauth')
            unless $identity->{email_verified} && $identity->{email};
        my $user = find_or_create_by_email($c, $identity->{email});
        $c->login($user);
        return;                          # the plugin redirects
    } };

And an C<oauth2_server> authenticates with:

    authenticate => sub {
        my ($c) = @_;
        return $c->auth_id // $c->redirect('/login?to=' . $c->req->path);
    }

=head1 SEE ALSO

L<Punk>, L<Punk::Auth::Password>, L<Punk::Session>, L<Punk::CSRF>,
L<Punk::RateLimit>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
