package Punk::Router;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Router - the compiled-at-boot route tables (XS)

=head1 DESCRIPTION

Internal to L<Punk>, and implemented entirely in C
(F<include/punk/punk_route.h>). The object is a blessed IV-ref to the C
router; every method is an XSUB.

C<new> opens an accumulation phase and C<add> records raw routes. C<compile>
resolves each route's target and guards to coderefs - the one step that must
stay Perl, since they are Perl code resolved against the app's controller
classes - through the C<$resolve> callback, then does all of the router work
in C: classify static vs dynamic (a C<:> or C<*> anywhere makes a route
dynamic), expand C<ANY> per method, reject duplicate routes and a misplaced
C<*splat>, parse dynamic paths into typed segments, and build the exact-match
table, the per-path Allow lists, the dynamic records and the per-route
record hashrefs.

Matching is one C call: an exact hash lookup for static routes
(C<match_static>), a memcmp'd typed-segment walk for dynamic ones with the
405 Allow set computed on a miss (C<match>). C<:name> captures one segment,
C<*name> the rest, C<HEAD> falls back to C<GET>, C<ANY> matches every method.
Both return a record index; C<records> is the array they index into.

=head1 METHODS

=head2 new

The router handle (accumulation phase).

=head2 add(method => $m, path => $p, target => $t, guards => \@g)

Record one raw, unresolved route. The path must start with C</>. Chains.

=head2 compile($resolve, \@extra?)

Resolve targets and guards through C<< $resolve->($target, $desc) >> and
build the tables in C. C<$extra> is an optional arrayref of the same
record shape (the docs UI routes). Returns the handle; C<ANY> static routes
expand per method, and a duplicate route or a misplaced C<*splat> croaks.

=head2 records

The compiled record hashrefs (C<code>, C<guards>, C<method>, C<path>),
indexed by the record index C<match_static> / C<match> return.

=head2 match_static($method, $path)

The record index of an exact static hit (C<HEAD> falls back to C<GET>), or
the empty list.

=head2 match($method, $path)

C<($index, \%captures)> on a dynamic hit; C<(undef, \@allow)> when the path
exists under other methods (a 405); the empty list for a 404.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
