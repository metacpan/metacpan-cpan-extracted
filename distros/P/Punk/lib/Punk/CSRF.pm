package Punk::CSRF;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.20';

1;

__END__

=head1 NAME

Punk::CSRF - single-use CSRF tokens

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    session secret => secret('session_key');
    csrf;

    get '/edit' => sub {
        my ($c) = @_;
        return $c->render('edit', { csrf => $c->csrf_field });
    };

    post '/edit' => sub {
        my ($c) = @_;          # only runs if the token was good
        ...;
    };

    # root/templates/edit.tmpl
    #   <form method="post" action="/edit">
    #     {% raw csrf %}
    #     ...
    #   </form>

=head1 DESCRIPTION

Every unsafe request must carry a token that the session says is live.
Using a token B<spends> it: the check replaces it with a fresh one, so the
same value never authorises twice.

The token lives in the session, which is a signed cookie, so rotation costs
nothing extra - changing it dirties the session and the session's own
write-back re-signs the cookie. Enabling C<csrf> without C<session> croaks at
C<to_app>, because there would be nowhere for the token to live.

=head2 What this does and does not give you

The server keeps no record of spent tokens - there is no server-side session
store - so this is B<freshness, not one-time enforcement>. A token replayed
on its own is refused, because the session it is checked against has moved
on. A replay of an entire captured request, old session cookie and old token
together, would still validate.

For CSRF that is the right trade. An attacker's whole difficulty is that they
cannot read the token from another origin; if they can present your session
cookie and the matching token, they already have your session and CSRF is no
longer the problem you have. Do not read this as protection against a stolen
cookie - C<secure>, C<httponly> and C<samesite> on the session are what
address that.

=head2 The cost of single use

One token is live at a time. A page rendered before a rotation carries a dead
token, so two tabs open on the same form means the second submission is
refused with a C<403>. That is the deliberate default. C<< keep => N >> holds
the N most recent tokens instead, each still usable once, which lets parallel
forms and in-flight requests work at the cost of a wider window.

=head1 THE KEYWORD

    csrf;

    csrf field    => '_csrf',
         header   => 'X-CSRF-Token',
         cookie   => 'csrf',
         keep     => 1,
         max_body => 65536,
         exempt   => [ '/hooks/' ],
         on_error => sub { my ($c) = @_; $c->text('no', 403) };

=over 4

=item * C<field> - the form field the token may arrive in (default C<_csrf>).

=item * C<header> - the header it may arrive in (default C<X-CSRF-Token>).

=item * C<cookie> - the name of the script-readable mirror (default C<csrf>).

=item * C<keep> - how many tokens stay live (default C<1>).

=item * C<max_body> - the largest urlencoded body the field will be looked for
in (default 64KB); above it, and for any multipart body, the header is
required.

B<Not> the same thing as L<Punk/max_body>, which refuses an oversize request
outright, or L<Hyperman/"max_body: the request ceiling">, which bounds what
the server will buffer at all. This one only decides how far into a body
C<csrf> will read looking for the token field; exceeding it rejects nothing,
it just means the token has to come from the header instead. The names
collide because each is the natural word in its own context, and renaming
this one would break every application that sets it.

=item * C<exempt> - path prefixes that skip the check, for endpoints
authenticated another way (a payment provider's webhook).

=item * C<on_error> - called with the context instead of the default C<403>;
return a response.

=back

C<csrf 0> turns it off again. It also reads a C<csrf:> block from
F<config/punk.yml>.

=head1 WHAT IS CHECKED

C<POST>, C<PUT>, C<PATCH> and C<DELETE>. C<GET>, C<HEAD>, C<OPTIONS> and
C<TRACE> are not - they are not supposed to change anything, and a token in a
URL leaks through C<Referer> and browser history.

A request carrying an C<Authorization> header is skipped: it is authenticated
by something the browser does not attach automatically, so it is not a CSRF
target. Cookie-authenticated API calls are still checked.

The token is looked for in the header first, then the form field. Comparison
is constant time.

=head1 CONTEXT METHODS

=head2 csrf_token

The live token, minting one on first ask.

=head2 csrf_field

The hidden input, escaped and ready:

    <input type="hidden" name="_csrf" value="...">

Pass it into the template and print it with C<{% raw %}>. It is not injected
into render data automatically - the view tier hands your hashref straight to
the engine, and copying it per render to add one key would put a cost on the
hottest path in the framework for the pages that do not have forms.

=head2 Script and fetch

The token also goes out in the C<csrf> cookie, which is deliberately not
C<HttpOnly>, so a fetch can read it and send the header:

    const token = document.cookie.match(/(?:^|; )csrf=([^;]*)/)[1];
    fetch('/edit', { method: 'POST', headers: { 'X-CSRF-Token': token } });

The cookie is not the authority - the session is - so a forged one proves
nothing. It is a delivery mechanism.

When an application has both C<csrf> and a C<docs> mount, L<Open::API::UI>'s
try-it-out is wired to the same pair automatically.

=head1 SEE ALSO

L<Punk>, L<Punk::Session>, L<Punk::Context>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
