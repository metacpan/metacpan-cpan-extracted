package Mojolicious::Plugin::Moai;
our $VERSION = '0.005';
# ABSTRACT: Mojolicious UI components using modern UI libraries

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Moai => 'Bootstrap4'; # or 'Bulma'
#pod     app->start;
#pod     __DATA__
#pod     @@ list.html.ep
#pod     %= include 'moai/lib'
#pod     %= include 'moai/table', items => \@items, columns => [qw( id name )]
#pod     %= include 'moai/pager', current_page => 1, total_pages => 5
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides some common UI components using a couple different
#pod popular UI libraries.
#pod
#pod These components are designed to integrate seamlessly with L<Yancy>,
#pod L<Mojolicious::Plugin::DBIC>, and L<Mojolicious::Plugin::SQL>.
#pod
#pod =head1 SUPPORTED LIBRARIES
#pod
#pod These libraries are not included and the desired version should be added
#pod to your layout templates. To add your library using a CDN, see
#pod L</moai/lib>, below.
#pod
#pod =head2 Bootstrap4
#pod
#pod L<http://getbootstrap.com>
#pod
#pod =head2 Bulma
#pod
#pod L<http://bulma.io>
#pod
#pod =head1 WIDGETS
#pod
#pod Widgets are snippets that you can include in your templates using the
#pod L<include helper|Mojolicious::Guides::Rendering/Partial templates>.
#pod
#pod =head2 moai/pager
#pod
#pod     <%= include 'moai/pager',
#pod         current_page => param( 'page' ),
#pod         total_pages => $total_pages,
#pod     %>
#pod
#pod A pagination control. Will display previous and next buttons along with
#pod individual page buttons.
#pod
#pod Also comes in a C<mini> variant in C<moai/pager/mini> that has just
#pod previous/next buttons.
#pod
#pod =head3 Stash
#pod
#pod =over
#pod
#pod =item current_page
#pod
#pod The current page number. Defaults to the value of the C<page> parameter.
#pod
#pod =item total_pages
#pod
#pod The total number of pages. Required.
#pod
#pod =item page_param
#pod
#pod The name of the parameter to use for the current page. Defaults to C<page>.
#pod
#pod =item id
#pod
#pod An ID to add to the pager
#pod
#pod =back
#pod
#pod =head2 moai/table
#pod
#pod     <%= include 'moai/table',
#pod         items => [
#pod             { id => 1, name => 'Doug' },
#pod         ],
#pod         columns => [
#pod             { key => 'id', title => 'ID' },
#pod             { key => 'name', title => 'Name' },
#pod         ],
#pod     %>
#pod
#pod A table of items.
#pod
#pod =head3 Stash
#pod
#pod =over
#pod
#pod =item items
#pod
#pod The items to display in the table. An arrayref of hashrefs.
#pod
#pod =item columns
#pod
#pod The columns to display, in order. An arrayref of hashrefs with the following
#pod keys:
#pod
#pod =over
#pod
#pod =item key
#pod
#pod The hash key in the item to use.
#pod
#pod =item title
#pod
#pod The text to display in the column heading
#pod
#pod =item link_to
#pod
#pod Add a link to the given named route. The route will be filled in by the current
#pod item, like C<< url_for $link_to => $item >>.
#pod
#pod =item id
#pod
#pod An ID to add to the table.
#pod
#pod =item class
#pod
#pod A hashref of additional classes to add to certain elements:
#pod
#pod =over
#pod
#pod =item * C<col> - Add these classes to every cell in the column
#pod
#pod =back
#pod
#pod =back
#pod
#pod =item class
#pod
#pod A hashref of additional classes to add to certain elements:
#pod
#pod =over
#pod
#pod =item * C<table>
#pod
#pod =item * C<thead>
#pod
#pod =item * C<wrapper> - Add a wrapper element with these classes
#pod
#pod =back
#pod
#pod =back
#pod
#pod =head2 moai/lib
#pod
#pod     %= include 'moai/lib', version => '4.1.0';
#pod
#pod Add the required stylesheet and JavaScript links for the current library
#pod using a CDN. The stylesheets and JavaScript can be added separately
#pod using C<moai/lib/stylesheet> and C<moai/lib/javascript> respectively.
#pod
#pod =head3 Stash
#pod
#pod =over
#pod
#pod =item version
#pod
#pod The specific version of the library to use. Required.
#pod
#pod =back
#pod
#pod =head1 TODO
#pod
#pod =over
#pod
#pod =item Security
#pod
#pod The CDN links should have full security hashes.
#pod
#pod =item Accessibility Testing
#pod
#pod Accessibility testing should be automated and applied to all supported
#pod libraries.
#pod
#pod =item Internationalization
#pod
#pod This library should use Mojolicious's C<variant> feature to provide
#pod translations for every widget in every library.
#pod
#pod =item Add more widgets
#pod
#pod There should be widgets for...
#pod
#pod =over
#pod
#pod =item * menus (vertical lists, horizontal navbars, dropdown buttons)
#pod
#pod =item * switched panels (tabs, accordion, slider)
#pod
#pod =item * alerts (error, warning, info)
#pod
#pod =item * menus (dropdown button, menu bar)
#pod
#pod =item * popups (modal dialogs, tooltips, notifications)
#pod
#pod =item * grid (maybe...)
#pod
#pod =back
#pod
#pod =item Add more libraries
#pod
#pod There should be support for...
#pod
#pod =over
#pod
#pod =item * Bootstrap 3
#pod
#pod =item * Material
#pod
#pod =back
#pod
#pod Moai should support the same features for each library, allowing easy
#pod switching between them.
#pod
#pod =item Add progressive enhancement
#pod
#pod Some examples of progressive enhancement:
#pod
#pod =over
#pod
#pod =item * The table widget could have sortable columns
#pod
#pod =item * The table widget could use AJAX to to filter and paginate
#pod
#pod =item * The pager widget could use AJAX to update a linked element
#pod
#pod =item * The switched panel widgets could load their content lazily
#pod
#pod =back
#pod
#pod =item Themes
#pod
#pod Built-in selection of CDN-based themes for each library
#pod
#pod =item Layouts
#pod
#pod A customizable layout with good defaults.
#pod
#pod =item Extra Classes
#pod
#pod A standard way of adding extra classes to individual tags inside components. In addition
#pod to a string, we should also support a subref so that loops can apply classes to certain
#pod elements based on input criteria.
#pod
#pod =item Documentation Sheet
#pod
#pod Each supported library should come with a single page that demonstrates the various
#pod widgets and provides copy/paste code snippets to achieve that widget.
#pod
#pod It would be amazing if there was a way to make one template apply to all
#pod supported libraries.
#pod
#pod =item Content section overrides
#pod
#pod We cannot, should not, must not make every little thing customizable or
#pod else our templates will be so complex as to be unmaintainable and
#pod unusable. We should instead make content sections that can be extended,
#pod like the C<moai/table> template could have a C<thead> section,
#pod a C<tbody> section, and a C<tbody.tr> section.
#pod
#pod A rule of thumb for adding a feature should be if it can be configured simply by a single
#pod string. The more complex the configuration needs to be, the more likely it should be
#pod customized using L<Mojolicious's template C<extends>|Mojolicious::Guides::Rendering/Template inheritance>
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious::Guides::Rendering>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw( path );

sub register {
    my ( $self, $app, $conf ) = @_;
    my $library = $conf->[0];
    $conf = $conf->[1] || {};
    my $libdir = path( __FILE__ )->sibling( 'Moai' )->child( 'resources', lc $library );
    push @{$app->renderer->paths}, $libdir->child( 'templates' );
    return;
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Moai - Mojolicious UI components using modern UI libraries

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Moai => 'Bootstrap4'; # or 'Bulma'
    app->start;
    __DATA__
    @@ list.html.ep
    %= include 'moai/lib'
    %= include 'moai/table', items => \@items, columns => [qw( id name )]
    %= include 'moai/pager', current_page => 1, total_pages => 5

=head1 DESCRIPTION

This plugin provides some common UI components using a couple different
popular UI libraries.

These components are designed to integrate seamlessly with L<Yancy>,
L<Mojolicious::Plugin::DBIC>, and L<Mojolicious::Plugin::SQL>.

=head1 SUPPORTED LIBRARIES

These libraries are not included and the desired version should be added
to your layout templates. To add your library using a CDN, see
L</moai/lib>, below.

=head2 Bootstrap4

L<http://getbootstrap.com>

=head2 Bulma

L<http://bulma.io>

=head1 WIDGETS

Widgets are snippets that you can include in your templates using the
L<include helper|Mojolicious::Guides::Rendering/Partial templates>.

=head2 moai/pager

    <%= include 'moai/pager',
        current_page => param( 'page' ),
        total_pages => $total_pages,
    %>

A pagination control. Will display previous and next buttons along with
individual page buttons.

Also comes in a C<mini> variant in C<moai/pager/mini> that has just
previous/next buttons.

=head3 Stash

=over

=item current_page

The current page number. Defaults to the value of the C<page> parameter.

=item total_pages

The total number of pages. Required.

=item page_param

The name of the parameter to use for the current page. Defaults to C<page>.

=item id

An ID to add to the pager

=back

=head2 moai/table

    <%= include 'moai/table',
        items => [
            { id => 1, name => 'Doug' },
        ],
        columns => [
            { key => 'id', title => 'ID' },
            { key => 'name', title => 'Name' },
        ],
    %>

A table of items.

=head3 Stash

=over

=item items

The items to display in the table. An arrayref of hashrefs.

=item columns

The columns to display, in order. An arrayref of hashrefs with the following
keys:

=over

=item key

The hash key in the item to use.

=item title

The text to display in the column heading

=item link_to

Add a link to the given named route. The route will be filled in by the current
item, like C<< url_for $link_to => $item >>.

=item id

An ID to add to the table.

=item class

A hashref of additional classes to add to certain elements:

=over

=item * C<col> - Add these classes to every cell in the column

=back

=back

=item class

A hashref of additional classes to add to certain elements:

=over

=item * C<table>

=item * C<thead>

=item * C<wrapper> - Add a wrapper element with these classes

=back

=back

=head2 moai/lib

    %= include 'moai/lib', version => '4.1.0';

Add the required stylesheet and JavaScript links for the current library
using a CDN. The stylesheets and JavaScript can be added separately
using C<moai/lib/stylesheet> and C<moai/lib/javascript> respectively.

=head3 Stash

=over

=item version

The specific version of the library to use. Required.

=back

=head1 TODO

=over

=item Security

The CDN links should have full security hashes.

=item Accessibility Testing

Accessibility testing should be automated and applied to all supported
libraries.

=item Internationalization

This library should use Mojolicious's C<variant> feature to provide
translations for every widget in every library.

=item Add more widgets

There should be widgets for...

=over

=item * menus (vertical lists, horizontal navbars, dropdown buttons)

=item * switched panels (tabs, accordion, slider)

=item * alerts (error, warning, info)

=item * menus (dropdown button, menu bar)

=item * popups (modal dialogs, tooltips, notifications)

=item * grid (maybe...)

=back

=item Add more libraries

There should be support for...

=over

=item * Bootstrap 3

=item * Material

=back

Moai should support the same features for each library, allowing easy
switching between them.

=item Add progressive enhancement

Some examples of progressive enhancement:

=over

=item * The table widget could have sortable columns

=item * The table widget could use AJAX to to filter and paginate

=item * The pager widget could use AJAX to update a linked element

=item * The switched panel widgets could load their content lazily

=back

=item Themes

Built-in selection of CDN-based themes for each library

=item Layouts

A customizable layout with good defaults.

=item Extra Classes

A standard way of adding extra classes to individual tags inside components. In addition
to a string, we should also support a subref so that loops can apply classes to certain
elements based on input criteria.

=item Documentation Sheet

Each supported library should come with a single page that demonstrates the various
widgets and provides copy/paste code snippets to achieve that widget.

It would be amazing if there was a way to make one template apply to all
supported libraries.

=item Content section overrides

We cannot, should not, must not make every little thing customizable or
else our templates will be so complex as to be unmaintainable and
unusable. We should instead make content sections that can be extended,
like the C<moai/table> template could have a C<thead> section,
a C<tbody> section, and a C<tbody.tr> section.

A rule of thumb for adding a feature should be if it can be configured simply by a single
string. The more complex the configuration needs to be, the more likely it should be
customized using L<Mojolicious's template C<extends>|Mojolicious::Guides::Rendering/Template inheritance>

=back

=head1 SEE ALSO

L<Mojolicious::Guides::Rendering>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
