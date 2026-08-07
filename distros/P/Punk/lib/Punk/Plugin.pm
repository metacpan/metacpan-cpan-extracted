package Punk::Plugin;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

sub new { bless {}, $_[0] }

sub register { }

1;

__END__

=head1 NAME

Punk::Plugin - base class for Punk plugins

=head1 SYNOPSIS

    package Punk::Plugin::RequestId;
    use parent 'Punk::Plugin';

    my $rid = 0;

    sub register {
        my ($self, $app, $opts) = @_;
        $app->helper(rid => sub { my ($c) = @_; $c->stash->{rid} });
        $app->hook(before_dispatch => sub {
            my ($c) = @_;
            $c->stash->{rid} = ++$rid;
            return;
        });
    }

    1;

    # in the app:
    plugin 'RequestId';

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
