package Punk::App;

use 5.010;
use strict;
use warnings;
use Punk::Router;
use Punk::Router::Scope;
use Punk::Context;
use Punk::Static;

our $VERSION = '0.63';

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

Plugins receive this object. Most of its methods are the DSL keywords
themselves: the keyword in the application class forwards its arguments
here, so C<< $app->session(expires => '7d') >> from a plugin does what
C<< session expires => '7d'; >> does in the class. Each records into the
registry and returns the app, so calls chain, unless its entry says
otherwise. Two read back rather than record: L</databases> and
L</auth_config>. L</on_compile> registers a callback for C<to_app>.

=head2 The keyword methods

=over 4

=item route($method, $path, $target, \@guards?, \%opts?)

What C<get>, C<post>, C<put>, C<patch>, C<del> and C<any> call, with the
method spelled out. See L<Punk/"get / post / put / patch / del / any">.

=item under($prefix, $guard?)

Returns a L<Punk::Router::Scope>, not the app. See L<Punk/under>.

=item websocket($path, $target, \%opts?, \@guards?)

See L<Punk/websocket>.

=item sse($path, $target, \%opts?, \@guards?)

See L<Punk/sse>.

=item api($spec, \%opts?, $scope?)

Returns the L<Punk::Mount::OpenAPI> it built, not the app. See L<Punk/api>.

=item docs($path, $mount?, \%opts?)

See L<Punk/docs>.

=item static($prefix, $dir, %opts)

See L<Punk/static>.

=item markdown($prefix, $dir, %opts)

See L<Punk/markdown> and L<Punk::Mount::Markdown>.

=item mount($prefix, $psgi_app)

See L<Punk/mount>.

=item favicon($path, %opts)

See L<Punk/favicon>.

=item views($name, \%opts?)

See L<Punk/views>.

=item database(%opts) / database($name => \%opts)

See L<Punk/"database / model">.

=item model_class(@names)

What the C<model> keyword calls. Names models to load; with no names it
turns auto-discovery on explicitly (see L</"model_auto($on?)">). See
L<Punk/"database / model">.

=item hook($phase, $code)

See L<Punk/hook>.

=item middleware($code)

See L<Punk/middleware>.

=item on_not_found($code)

See L<Punk/on_not_found>.

=item plugin($name, \%opts?)

See L<Punk/plugin>.

=item config(...)

With no arguments, the loaded configuration data, or undef when no file
was loaded. See L<Punk/config>.

=item secret($path)

Returns the resolved secret, not the app. See L<Punk/secret>.

=item session(%opts)

See L<Punk/session>.

=item logging(%opts)

See L<Punk/logging>. A C<to> path is opened here, so a path that cannot be
written croaks at boot.

=item cache(%opts) / cache($name => \%opts)

See L<Punk/cache>.

=item csrf(%opts)

See L<Punk/csrf>.

=item cors(%opts)

See L<Punk/cors>.

=item headers_scoped($prefix, \%pairs)

The scope form of C<headers>: what C<< $scope->headers(...) >> on an
L<Punk/under> scope calls, with the scope's prefix. Under that prefix
these headers apply ahead of the application-wide policy, the longest
prefix first. A value of undef drops that header there; a reference
croaks. See L<Punk/headers>.

=item proxy(%opts)

See L<Punk/proxy>.

=item rate_limit(%opts)

See L<Punk/rate_limit> and L<Punk::RateLimit>.

=item max_body($bytes)

See L<Punk/max_body>.

=item auth(%opts)

See L<Punk/auth> and L<Punk::Auth>.

=item auth_guard(%opts)

Returns the guard, not the app. See L<Punk/auth_guard>.

=item ua(%opts) / ua($name => \%opts)

See L<Punk/ua> and L<Punk::UA>.

=item upload_dir($path)

See L<Punk/upload_dir>.

=item host($origin?, allow => \@hosts?)

See L<Punk/host>. With no argument it reads the declared origin back
(undef when the application never declared one), which is how a plugin
defaults its own base-URL option; a plugin supporting older Punk should
guard with C<< $app->can('host') >>.

=item publish($topic, $payload)

=item subscribe($topic, $code, group => $name?)

The cross-worker bus at the application level, where a subscription
belongs: made at boot, in the parent, before the server forks. Each
returns what the context methods of the same names return, not the app.
See L<Punk/"publish / subscribe">.

=back

C<install_kw> gives a plugin a keyword of its own; C<keyword> and
C<has_keyword> call, and detect, one another plugin installed.

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
C<PUNK_ENV=development> yourself. C<test> is the third name with a meaning:
a C<500> still carries the die text there, which L<Punk::Test> relies on and
sets for you when C<PUNK_ENV> is unset.

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

=head2 markdown_pages($prefix)

    my $pages = $app->markdown_pages('/blog');

The pages of the C<markdown> mount at that prefix, in its order, as fresh
hashrefs (C<url>, C<path>, C<title>, C<date>, C<updated>, C<summary>,
C<meta>); see L<Punk::Mount::Markdown/LISTING>. Croaks before C<to_app>, and
for a prefix with no markdown mount.

=head1 FRAMEWORK METHODS

Called by Punk itself; a plugin may read the first three.

=head2 caller_class

The application class this registry belongs to, which is the namespace its
controllers, models and C<to_app> live under.

=head2 config_object

The loaded L<Punk::Config>, or undef when no configuration file was found.

=head2 model_auto($on?)

With no argument, whether models are found by scanning
C<< <caller_class>::Model:: >> at compile: true unless models were named
and auto-discovery was not also asked for. With an argument, sets it and
returns the app.

=head2 new(caller => $class)

Builds an empty registry. C<use Punk> calls it once per application class.

=head2 model_instance($name)

The model registered as C<$name>, built on first use with its database's
options and cached for the process. The cache is dropped when the pid
changes, so a forked worker builds its own instances. Croaks when no model
is registered, or for an unknown name, listing those there are.

=head2 render_view($c, @args)

Hands C<$c> and C<@args> to the configured view engine's C<render> and
returns its response. Croaks when no C<views> keyword ran.

=head1 COMPILE

=head2 compile

Freezes the configuration and returns the PSGI app. Dispatch order:
before_request hooks (when any are registered - they run before anything
is matched, so they are the only phase a 404, a 405 or a mount reaches),
static table, PSGI/static-file mounts (longest prefix first), the dynamic
records (a linear scan in declaration order), then 404/405. Matched
requests construct the context, run
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
