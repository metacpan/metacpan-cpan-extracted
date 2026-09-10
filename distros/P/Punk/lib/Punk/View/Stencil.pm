package Punk::View::Stencil;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.48';

1;

__END__

=head1 NAME

Punk::View::Stencil - the Template::Stencil view engine

=head1 SYNOPSIS

    views Stencil => {
        template_dir => 'root/templates',
        wrapper      => 'layout.tmpl',
        filters      => { money => sub { sprintf '%.2f', $_[0] } },
    };

    # in a controller
    return $c->render('book/list', { books => $page->{rows} });

=head1 DESCRIPTION

The options hashref is handed to L<Template::Stencil/new> untouched;
see there for the full set (C<template_dir>, C<wrapper>, C<filters>,
C<auto_escape>, C<strict>, C<cache>, ...). Template names resolve
against C<template_dir> with C<.tmpl> inference, so
C<render('book/list', ...)> renders F<root/templates/book/list.tmpl>
inside the wrapper layout.

The class is entirely XS. The object is two array slots - the options
as registered and the L<Template::Stencil> object built from them - and
C<render> reaches the template VM through Stencil's own C ABI, so no
Perl frame sits between the dispatcher and the engine.

L<Punk::Views> constructs the view once per worker, handing the
registered options to C<new> as a single positional argument, and
C<new> builds the Stencil engine there and then - so an engine that
will not construct fails at boot along with the rest of the
configuration rather than on the first render. Editing a template takes
effect without a restart through Stencil's mtime cache.

This needs L<Template::Stencil> 0.02 or newer, which is where that ABI
arrived. There is no Perl render path behind it: an engine too old to
provide the ABI croaks when the view is constructed, naming the version
required, rather than starting an application whose pages cannot
render.

=head1 BUILT-IN FILTERS AND VARIABLES

Punk merges two filters into the engine's C<filters> at C<to_app>, and
binds one variable per render. All three are B<set only where the
application left a gap>: a C<filters> entry of the same name, or a
C<url> key already on the render data, is the application's and wins.

=head2 asset

    <link rel="stylesheet" href="{% "/static/app.css" | asset %}">

The content-addressed URL for a file under a fingerprinted C<static>
mount. See L<Punk::Context/asset>.

=head2 Named routes

    <a href="{% url.books %}">all books</a>
    <a href="{% book.id | url_for('book') %}">one</a>
    <a href="{% book    | url_for('book') %}">one</a>

C<url> is a hash of the application's named B<static> routes, so the
commonest link on a page costs a lookup inside the engine and no call into
Perl. A route that captures is not in it - it has nothing to fill the
captures with - and asking for one says so, naming the filter instead.

The C<url_for> filter takes the captures from the value and the route from
its one argument, which is all a filter is given. A hashref fills captures
by name, which is usually a row straight out of the model, and any key of
it that names no capture becomes a query pair. A scalar fills a route that
has exactly one capture; on a route with more it croaks rather than guess
which.

A name the application does not have B<fails the render>, naming itself and
the template. That is deliberate and it is what the C<url> hash costs: a
missing path would otherwise resolve to the empty string, and C<href="">
is a link to the current page that looks like it works. The tie is about
280ns a lookup, roughly eight microseconds on a page with thirty links.

Both forms carry the application's prefix - the path on L<Punk/host>, then
C<SCRIPT_NAME> - so a fragment rendered under a mount links under it too.

Auto-escaping runs after the last filter, as it does for every filter, so
the C<&> joining two query pairs reaches the page as C<&amp;>. That is
correct inside an C<href> and is what writing the URL by hand would have
had to do.

=head1 SLOTS

=head2 opts

The options the engine was registered with (an empty hashref by
default).

=head2 engine

The underlying L<Template::Stencil>, built by C<BUILD>.

=head1 METHODS

=head2 new(\%opts)

=head2 render($template, \%data, \%opts?)

The two-method engine contract; render returns UTF-8 bytes. C<\%opts> is
handed to L<Template::Stencil/render> untouched, and is how
C<< $c->render(..., layout => ...) >> arrives: C<< { wrapper => $name } >>
renders inside that template instead of the configured one, C<< { wrapper
=> undef } >> renders with none. A template holding C<{% content %}>
rendered with no wrapper is a render error naming the template, and a
wrapper that does not exist is one naming the wrapper.

=head1 SEE ALSO

L<Template::Stencil>, L<Punk::Views>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
