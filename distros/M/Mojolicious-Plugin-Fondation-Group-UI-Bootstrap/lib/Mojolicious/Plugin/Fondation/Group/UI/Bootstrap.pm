package Mojolicious::Plugin::Fondation::Group::UI::Bootstrap;
$Mojolicious::Plugin::Fondation::Group::UI::Bootstrap::VERSION = '0.01';
# ABSTRACT: Web UI extension for Fondation::Group — injects group checkboxes into user forms

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Group', 'Fondation::Layout::Bootstrap'],
        defaults     => {
            title => 'Group Management UI',
        },
    };
}

sub register ($self, $app, $conf) {

    $app->routes->get('/groups')
      ->requires('fondation.perm' => 'group_list')
      ->to(
        controller => 'Group',
        action     => 'index'
    );

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Group::UI::Bootstrap - Web UI extension for Fondation::Group — injects group checkboxes into user forms

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Model::DBIx::Async',
            'Fondation::User',
            'Fondation::User::UI::Bootstrap',
            'Fondation::Group',
            'Fondation::Group::UI::Bootstrap',
        ],
    };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Fondation::Group::UI::Bootstrap> provides a Bootstrap 5
web interface for group management. It injects group-related zones into user
forms and adds a standalone group administration page.

This plugin is the UI counterpart to
L<Mojolicious::Plugin::Fondation::Group>, which provides the backend API
and data model. The UI plugin depends on
L<Mojolicious::Plugin::Fondation::Layout::Bootstrap> for Bootstrap assets
and layout.

=head1 DEPENDENCIES

This plugin depends on:

=over 4

=item L<Mojolicious::Plugin::Fondation::Group> — backend API, schema, and controllers

=item L<Mojolicious::Plugin::Fondation::Layout::Bootstrap> — Bootstrap 5 assets and layout

=back

All dependency resolution is handled automatically by the Fondation plugin
loader.

=head1 ROUTES

=over 4

=item GET /groups

Renders the group list page with a DataTable and inline CRUD modal.
Requires the C<group_list> permission.

=back

=head1 ZONES

The plugin injects zones into user management forms provided by
L<Mojolicious::Plugin::Fondation::User::UI::Bootstrap>:

=head2 HTML zones

=over 4

=item C<user/add/groups>

A multi-select picker (Bootstrap Select) for assigning groups when creating
or editing a user.

=item C<user/list/columns/groups>

A table header cell for the Groups column in the user DataTable.

=back

=head2 JavaScript zones

=over 4

=item C<user/add/groups>

Functions C<loadGroups(user)> and C<collectGroupAssignments()> called by
C<DatatableUser.js> to populate the group picker and collect selections
on save.

=item C<user/list/columns/groups>

Extends C<window._userExtraColumns> with a renderer that displays each
user's groups as a list, with inactive groups shown in strikethrough.

=back

=head1 TEMPLATES

The plugin ships one template in C<share/templates/group/list.html.ep>:

=over 4

=item group/list.html.ep

Bootstrap-styled page with DataTable, inline add/edit modal, and delete
confirmation modal. Permission checks control visibility of the add button
(C<group_create>).

=back

=head1 MENU

A menu entry is added under C<admin_menu> / Administration:

    [Groups]  (fas fa-shield-alt)  →  /groups

=head1 JAVASCRIPT

=head2 DatatableGroup.js

Bootstrap DataTable integration for the group list page
(C<share/public/js/DatatableGroup.js>). Handles:

=over 4

=item * Fetching groups via C<GET /api/group>

=item * Inline add/edit via modal form

=item * Delete with confirmation

=item * Selectpicker refresh for permission pickers

=back

=head2 Zone functions

When the Group UI plugin is active, the User edit form calls
C<loadGroups(user)> to populate the group picker and
C<collectGroupAssignments()> to collect group IDs before saving.

=head1 TRANSLATIONS

Translation files are provided for English and French in
C<share/translations/>. Keys include group management labels
(Groups list, Add group, Name, Permissions, Save, Delete, etc.).

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<Mojolicious::Plugin::Fondation::Group>,
L<Mojolicious::Plugin::Fondation::User::UI::Bootstrap>,
L<Mojolicious::Plugin::Fondation::Layout::Bootstrap>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
