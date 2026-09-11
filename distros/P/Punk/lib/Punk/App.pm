package Punk::App;

use 5.010;
use strict;
use warnings;
use Punk::Router;
use Punk::Router::Scope;
use Punk::Context;
use Punk::Static;

our $VERSION = '0.49';

sub compile_extras {
    my ($self) = @_;
    my $rr = $self->{rate_limit_routes};
    if ($rr && ref $rr eq 'ARRAY' && @$rr) {
        Punk::RateLimit::_compile_routes($self);  # XS; always loaded
    }
    my $vr = $self->{validate_routes};
    if ($vr && ref $vr eq 'ARRAY' && @$vr) {
        Punk::Validate::_compile_routes($self);   # XS; always loaded
    }
    if ($self->env eq 'development') {
        require Punk::DevError;
        Punk::DevError::_install($self);
    }
    return;
}

sub env {
    my ($self) = @_;
    my $cfg = $self->config_object;
    my $env = $cfg ? $cfg->env : undef;
    return defined $env && length $env
        ? $env : ($ENV{PUNK_ENV} // 'production');
}

1;

__END__

=head1 NAME

Punk::App - the per-application registry and boot compiler

=head1 DESCRIPTION

C<use Punk;> creates one of these per application class. The DSL
keywords and plugins record into it; C<to_app> calls L</compile>,
which resolves every target string, flattens guard chains, freezes the
route tables and returns the PSGI coderef. Everything wrong croaks at
boot; the returned closure is the only code on the request path.

=head1 THE REGISTRAR SURFACE

Plugins receive this object; each method mirrors a DSL keyword:
C<route>, C<under>, C<api>, C<docs>, C<static>, C<mount>, C<websocket>,
C<sse>, C<session>, C<logging>, C<views>, C<database>, C<model_class>, C<hook>,
C<middleware>, C<on_error>, C<on_not_found>, C<helper>, C<plugin>,
C<config>, C<secret>, C<host>, C<favicon>. Two read back rather than
record: C<databases>, C<auth_config> and, with no argument, C<host>.
C<on_compile> registers a callback for C<to_app>.

C<< $app->host >> with no argument reads the declared origin back (undef
when the application never declared one), which is how a plugin defaults
its own base-URL option; a plugin supporting older Punk should guard with
C<< $app->can('host') >>.
C<install_kw> gives a plugin a keyword of its own; C<keyword> and
C<has_keyword> call, and detect, one another plugin installed. C<model_auto>
toggles auto-discovery of C<MyApp::Model::*> (on unless models are named
explicitly). C<caller_class> and C<config_object> give a plugin the
app's controller namespace and its L<Punk::Config>; C<new> and the
compile-time helpers (C<compile>, C<model_instance>, C<render_view>) are
called by the framework, not apps.

=head2 databases

    my $dbs = $app->databases;    # { default => {...}, analytics => {...} }

The configured databases read back: what the C<database> keyword recorded
and what F<punk.yml> applied, keyed by name with C<default> for the
unnamed one. A deep copy - a plugin must not be able to edit the
connection options of the application it is installed in. Credentials
included, since this is the application's own registrar and a plugin that
deploys schema needs them. The registrar's other methods record; this one
reads, the way C<host> reads back with no argument.

=head2 auth_config

    my $cfg = $app->auth_config;    # { model, fields, rank, roles, ... } | undef

The frozen L<Punk::Auth> configuration read back, a deep copy, or C<undef>
when no C<auth> keyword ran. The C<rank> ladder and the C<roles> hook are
what a plugin deciding "may this user act on this row" needs, and it needs
them from here rather than from an option of its own: two ladders, one on
the plugin and one on C<auth_guard>, drift.

=head2 on_compile

    $app->on_compile(sub { my ($app) = @_; ... }, __PACKAGE__);

A callback for C<to_app>: run once, in registration order, after every
keyword has recorded and before anything is compiled - so it may still
use the registrar (read C<databases>, add a route, a hook, a helper) and
what it adds is compiled with the rest. The framework's own
C<compile_extras> runs after these. A die is a boot croak naming the
owner (the second argument, defaulting to the registering package).
Calling it after C<to_app> croaks, since the callback would never run.

This is the moment a plugin needs when its C<plugin> line may sit above
the C<database> line it depends on, and the one L<Punk::Plugin::Queue>
reached, before this existed, by registering a middleware whose
constructor runs once at compile. Not a C<hook> phase: those are request
phases, and this runs once per compile, never per request.

=head2 helper

    $app->helper(rid => sub { my ($c, @args) = @_; ... });

Installed as a real method on the application's context subclass at
compile time. Collisions with core context methods or another helper
croak, naming both owners.

=head2 env

The application environment, resolved once at compile: the loaded
config's C<env> when there is one, else C<PUNK_ENV>, else
C<production> - the same safe default L<Punk::Config> and C<punk> use.
Development is opted into: C<punk dev> sets it for its server, or set
C<PUNK_ENV=development> yourself.

=head2 compile_extras

A boot hook: C<compile> calls it just before the compiled state
freezes, after the router and hooks are assembled. The framework's own
extras live here (the L<Punk::DevError> wiring in development), so a
subclass that overrides it B<must> call C<SUPER::compile_extras>.

=head2 install_kw

    $app->install_kw(task => sub { my ($name, $target) = @_; ... },
                     __PACKAGE__);

Installs a declaration keyword into the application class - how a plugin
adds to the DSL without assigning to a glob. The keyword is a magic CV
named for the class it lands in; it forwards its arguments to the code
and returns what the code returns, in the caller's context.

Installing over a core keyword croaks. Two owners claiming one name croak,
naming both, as helpers do; the same owner installing twice is a no-op,
which is what a plugin that installs from both C<import> and C<register>
needs. Chains. See L<Punk::Plugin/KEYWORDS OF YOUR OWN>.

=head2 keyword($name, @args)

    $app->keyword(sitemap => blog => sub { ... });

Calls a keyword a plugin installed, from code rather than from the
application's package body. The installed code runs with C<@args> in the
caller's context and its return is passed through, exactly as the keyword
in the application class would have done. This is how one plugin consumes
another's declaration - a blog adding its posts to the sitemap - without
reaching into the application class by name.

A name nothing installed croaks naming it, because the plugin that
provides it is not loaded and doing nothing would be a silence. A core DSL
word croaks too; those are this registrar's own methods.

=head2 has_keyword($name)

The owner of an installed keyword - the class that installed it - or undef
when nothing did. The way to ask whether this application loaded a plugin
whose keyword you want to call, rather than sniffing C<%INC>, which says a
module was loaded somewhere and not that this application registered it.
Core DSL words answer undef.

=head2 log

The application L<Punk::Logger> (cached on the app), for logging outside a
request - startup, background work: C<< $app->log->info(...) >>. Its lines have
no method or path. See L<Punk::Logger> and the C<logging> keyword.

=head2 url_for($name, %args)

    my $link = $app->url_for('verify', token => $tok, absolute => 1);

The URL of a named route (L<Punk/Named routes>), for code that has no
request to reach L<Punk::Context/url_for> through: a mail built in a queue
worker, a test naming a route rather than typing its path. Same names, same
captures, same croaks.

Two things follow from there being no request, and both are the safe
direction. The prefix is the path on the C<host> keyword alone, because
C<SCRIPT_NAME> belongs to a request and there is not one. And C<absolute>
builds on the B<declared> host rather than negotiating the C<allow> list,
because a background job has no C<Host> header to be allowed or refused.

Only meaningful after C<to_app>: the names are resolved when the routes are.

=head1 COMPILE

=head2 compile

Freezes the configuration and returns the PSGI app. Dispatch order:
before_request hooks (when any are registered - they run before anything
is matched, so they are the only phase a 404, a 405 or a mount reaches),
static table, PSGI/static-file mounts (longest prefix first), dynamic
buckets, then 404/405. Matched requests construct the context, run
before_dispatch hooks and the route's frozen guard chain (a reference
return short-circuits), call the handler, and coerce the return value:

=over 4

=item * a PSGI triplet passes through untouched;

=item * a L<Punk::Response> is finalized;

=item * a Future is chained on C<psgi.nonblocking> servers (the server
awaits it) and awaited inline on blocking ones;

=item * anything else is JSON-encoded as C<200 application/json>,
folding in any status/headers set through the context;

=item * a die runs C<on_error>, then answers
C<500 {"errors":[{"message":...}]}>.

=back

"Construct the context" happens once per request, not once per phase: when
a C<before_request> hook has already built one, the routed match is stored
into it rather than a second context being made, so a stash written before
routing is the same stash the handler reads.

after_dispatch hooks see the finalized triplet (mutate it, or return a
replacement); HEAD responses are stripped of their body.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
