package Punk::App;

use 5.010;
use strict;
use warnings;
use Punk::Router;
use Punk::Router::Scope;
use Punk::Context;
use Punk::Static;

our $VERSION = '0.12';

# The boot hook compile() probes just before the state hash freezes
# (xs/compile.xs). The framework's own extras live here; a subclass that
# overrides it must call SUPER::compile_extras.
sub compile_extras {
    my ($self) = @_;
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

# The application environment, resolved once at compile: the loaded
# config's env when there is one, else PUNK_ENV, else production - the
# safe default. Development is opted into (PUNK_ENV=development, or
# `punk dev`, which sets it).
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
C<config>, C<secret>.
C<install_kw> gives a plugin a keyword of its own. C<model_auto>
toggles auto-discovery of C<MyApp::Model::*> (on unless models are named
explicitly). C<caller_class> and C<config_object> give a plugin the
app's controller namespace and its L<Punk::Config>; C<new> and the
compile-time helpers (C<compile>, C<model_instance>, C<render_view>) are
called by the framework, not apps.

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

=head2 log

The application L<Punk::Logger> (cached on the app), for logging outside a
request - startup, background work: C<< $app->log->info(...) >>. Its lines have
no method or path. See L<Punk::Logger> and the C<logging> keyword.

=head1 COMPILE

=head2 compile

Freezes the configuration and returns the PSGI app. Dispatch order:
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

after_dispatch hooks see the finalized triplet (mutate it, or return a
replacement); HEAD responses are stripped of their body.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
