package Punk::Plugin;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.28';

sub new { bless {}, $_[0] }

sub register { }

1;

__END__

=head1 NAME

Punk::Plugin - base class for Punk plugins

=head1 SYNOPSIS

    package Punk::Plugin::Maintenance;
    use parent 'Punk::Plugin';

    sub register {
        my ($self, $app, $opts) = @_;
        my $flag = $opts->{file} || '/etc/myapp/maintenance';

        $app->helper(in_maintenance => sub { -e $flag });

        # before_dispatch: returning a reference short-circuits the
        # request, so this answers before any guard or handler runs
        $app->hook(before_dispatch => sub {
            my ($c) = @_;
            return unless -e $flag;
            return $c->text('back shortly', 503);
        });
    }

    1;

    # in the app:
    plugin 'Maintenance';
    plugin 'Maintenance' => { file => '/tmp/down' };

=head1 DESCRIPTION

A plugin's C<register($plugin, $app, \%opts)> runs at registration
time and receives the same registrar surface the DSL keywords use -
the L<Punk::App> - so a plugin can do anything the app class can:
add routes and C<under> scopes, register view engines and model
backends, hooks, middleware, C<on_error>, and helpers.

Helpers registered with C<< $app->helper(name => sub) >> become real
methods on the application's context subclass, installed once at
C<to_app> - no AUTOLOAD, no per-request cost. A helper name that
collides with a core L<Punk::Context> method or another helper croaks
at boot, naming both owners.

C<plugin 'Name'> resolves to C<Punk::Plugin::Name>; C<'+Full::Class'>
uses the class as written.

=head2 What the hook phases can and cannot see

C<before_request> runs before routing, so it sees every request - including
the ones that 404, 405, or are answered by a static mount.
C<before_dispatch> runs after a route matches, which is the right phase for
anything done on the client's behalf. C<after_dispatch> runs on the way out.

B<C<after_dispatch> does not see every response.> Punk's dispatcher has exits
that finish without reaching it - the house 404 and 405 among them - so a
plugin that must touch B<every> response cannot be written with this surface
alone. L<Punk::Plugin::RequestId>, which this distribution ships, needs
exactly that and is built on an internal seam instead; if you find yourself
wanting the same thing, read its source rather than assuming
C<after_dispatch> will do.

B<C<before_dispatch> runs ahead of a route's guards.> The order is
C<before_dispatch>, then the guards a C<under> scope put on the route, then
the handler - so a hook here sees requests an authentication guard is about
to refuse. That is fine for anything advisory and wrong for anything that
answers: a hook that short-circuits with a response has answered a request
the guard would have rejected. L<Punk::Plugin::ConditionalGet> needed to run
after the guards for exactly this reason - a C<304> issued before
authentication is an authorisation check turned into a cache hit - and is on
an internal seam too. There is currently no public phase between the guards
and the handler.

=head2 A shipped example

L<Punk::Plugin::RequestId> is the plugin bundled with Punk. It registers a
helper the ordinary way and is worth reading for the shape of a real one, with
the caveat above about where it goes further than this API.

=head2 KEYWORDS OF YOUR OWN

A plugin that wants a declaration keyword - C<task>, C<queue>, C<cron> -
installs it with C<< $app->install_kw >> rather than assigning to a glob
in the application class:

    $app->install_kw(task => sub {
        my ($name, $target) = @_;
        push @TASKS, [$name, $target];
        return;
    }, __PACKAGE__);

Punk installs it as a magic CV named for the class it lands in, beside
the DSL's own keywords, and keeps it in the same registry: two plugins
claiming one name croak naming both owners, and a core keyword cannot be
installed over. Installing the same name twice from the same owner is a
no-op, so a plugin with both an C<import> and a C<register> can install
from both without remembering which ran.

A keyword must be installed before the line that uses it is compiled, or
the bareword form (C<<< task 'x' => ... >>>) will not parse - which means from
the plugin's C<import>, i.e. C<use My::Plugin> in the app class.
C<register> runs at runtime, so a keyword installed there is only usable
in its parenthesised form (C<task(...)>) on later lines. These are
ordinary compile-time-visible subs, not calls lifted into the C<BEGIN>
phase: an argument is evaluated when the line runs, as usual.

=head1 METHODS

=head2 new

Plain constructor; override freely.

=head2 register($app, \%opts)

Override this. Called once, at C<plugin> time.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
