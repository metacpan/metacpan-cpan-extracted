package Punk::Views;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.17';

1;

__END__

=head1 NAME

Punk::Views - the pluggable view engine registry (XS)

=head1 DESCRIPTION

Each C<views $name =E<gt> \%opts> call in the DSL registers one engine.
C<$name> resolves to C<Punk::View::$name>; C<'+Full::Class'> uses the class
as written. The engine contract is two methods and nothing more - adding
view backends never touches the dispatch path:

    my $engine = Engine->new(\%opts);
    my $bytes  = $engine->render($template_name, \%data);

The first registered engine is the default;
C<< $c->render($tpl, \%data, engine => 'Other') >> selects per render,
C<< type => '...' >> overrides the content type, C<< status => ... >> the
status. Everything resolves and croaks at C<to_app>, never per request.

Implemented entirely in C (F<include/punk/punk_views.h>): the object is a
blessed IV-ref to the engine registry, and C<render> - the hot path - looks
the engine up, calls its render, and assembles the PSGI triplet in C, so a
rendered page crosses the Perl boundary only for the engine's own render
(itself XS in L<Template::Stencil>).

=head1 METHODS

=head2 new(\@pairs)

Compile the registry from C<[ [ $name, \%opts ], ... ]>. Resolves, loads and
instantiates each engine; the first is the default. Duplicate names, a class
that will not load, or one missing C<new>/C<render> croak.

=head2 engine($name?)

The named (or default) engine instance; unknown names croak listing what is
registered.

=head2 default

The default engine's name.

=head2 render($c, $template, \%data, %overrides)

A finished PSGI triplet around the engine's bytes, folding in any status and
headers pending on the context C<$c> (which may be undef). Overrides:
C<status>, C<type>, C<engine>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
