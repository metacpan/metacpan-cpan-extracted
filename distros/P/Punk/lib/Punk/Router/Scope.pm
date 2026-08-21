package Punk::Router::Scope;

use 5.010;
use strict;
use warnings;

use Punk ();

our $VERSION = '0.27';

1;

__END__

=head1 NAME

Punk::Router::Scope - the handle an C<under> returns

=head1 SYNOPSIS

    my $admin = under '/admin' => 'Web::Auth#required';
    $admin->get('/books' => 'Web::Book#admin_list');

    my $super = $admin->under('/super' => 'Web::Auth#superuser');
    $super->del('/books/:id' => 'Web::Book#purge');

=head1 DESCRIPTION

Scopes nest as explicit objects - no dynamic scoping. Each scope holds
its full path prefix and the outer-to-inner guard chain; routes
attached to it inherit both. Guards receive the context and continue
on a non-reference return; a reference return short-circuits the
request and is finalized like any controller return.

=head1 METHODS

=head2 new(app => $app, prefix => $prefix, guards => \@guards)

A scope. Constructed for you by the C<under> keyword (and by an outer
scope's L</under>); you rarely call it directly.

=head2 under($prefix => $guard)

A nested scope.

=head2 get / post / put / patch / del / any ($path => $target)

Routes under this scope; chainable.

=head2 api ($spec, \%opts?)

An OpenAPI mount under this scope's prefix and guards; returns the
mount. See L<Punk::Mount::OpenAPI>.

=head2 websocket ($path => $target, \%opts?)

A WebSocket route under this scope; chainable. See L<Punk/websocket>.

=head2 headers (%pairs)

    $scope->headers('X-Frame-Options' => 'DENY',
                    'Referrer-Policy' => undef);

A response-header policy for this scope's prefix - the pairs the app-wide
C<headers> keyword takes, applied ahead of it for requests under the
prefix (including their C<404>s); an C<undef> value drops a header for the
subtree. Chainable. See L<Punk::Headers/SCOPED POLICIES>.

=head2 prefix

=head2 guards

Introspection.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
