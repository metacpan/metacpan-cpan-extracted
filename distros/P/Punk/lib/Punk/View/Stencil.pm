package Punk::View::Stencil;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

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

=head1 SLOTS

=head2 opts

The options the engine was registered with (an empty hashref by
default).

=head2 engine

The underlying L<Template::Stencil>, built by C<BUILD>.

=head1 METHODS

=head2 new(\%opts)

=head2 render($template, \%data)

The two-method engine contract; render returns UTF-8 bytes.

=head1 SEE ALSO

L<Template::Stencil>, L<Punk::Views>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
