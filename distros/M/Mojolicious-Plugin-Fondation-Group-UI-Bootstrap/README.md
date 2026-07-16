# NAME

Mojolicious::Plugin::Fondation::Group::UI::Bootstrap - Web UI extension for Fondation::Group — injects group checkboxes into user forms

# VERSION

version 0.01

# SYNOPSIS

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

# DESCRIPTION

[Mojolicious::Plugin::Fondation::Group::UI::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AGroup%3A%3AUI%3A%3ABootstrap) provides a Bootstrap 5
web interface for group management. It injects group-related zones into user
forms and adds a standalone group administration page.

This plugin is the UI counterpart to
[Mojolicious::Plugin::Fondation::Group](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AGroup), which provides the backend API
and data model. The UI plugin depends on
[Mojolicious::Plugin::Fondation::Layout::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ALayout%3A%3ABootstrap) for Bootstrap assets
and layout.

# DEPENDENCIES

This plugin depends on:

- [Mojolicious::Plugin::Fondation::Group](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AGroup) — backend API, schema, and controllers
- [Mojolicious::Plugin::Fondation::Layout::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ALayout%3A%3ABootstrap) — Bootstrap 5 assets and layout

All dependency resolution is handled automatically by the Fondation plugin
loader.

# ROUTES

- GET /groups

    Renders the group list page with a DataTable and inline CRUD modal.
    Requires the `group_list` permission.

# ZONES

The plugin injects zones into user management forms provided by
[Mojolicious::Plugin::Fondation::User::UI::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser%3A%3AUI%3A%3ABootstrap):

## HTML zones

- `user/add/groups`

    A multi-select picker (Bootstrap Select) for assigning groups when creating
    or editing a user.

- `user/list/columns/groups`

    A table header cell for the Groups column in the user DataTable.

## JavaScript zones

- `user/add/groups`

    Functions `loadGroups(user)` and `collectGroupAssignments()` called by
    `DatatableUser.js` to populate the group picker and collect selections
    on save.

- `user/list/columns/groups`

    Extends `window._userExtraColumns` with a renderer that displays each
    user's groups as a list, with inactive groups shown in strikethrough.

# TEMPLATES

The plugin ships one template in `share/templates/group/list.html.ep`:

- group/list.html.ep

    Bootstrap-styled page with DataTable, inline add/edit modal, and delete
    confirmation modal. Permission checks control visibility of the add button
    (`group_create`).

# MENU

A menu entry is added under `admin_menu` / Administration:

    [Groups]  (fas fa-shield-alt)  →  /groups

# JAVASCRIPT

## DatatableGroup.js

Bootstrap DataTable integration for the group list page
(`share/public/js/DatatableGroup.js`). Handles:

- Fetching groups via `GET /api/group`
- Inline add/edit via modal form
- Delete with confirmation
- Selectpicker refresh for permission pickers

## Zone functions

When the Group UI plugin is active, the User edit form calls
`loadGroups(user)` to populate the group picker and
`collectGroupAssignments()` to collect group IDs before saving.

# TRANSLATIONS

Translation files are provided for English and French in
`share/translations/`. Keys include group management labels
(Groups list, Add group, Name, Permissions, Save, Delete, etc.).

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[Mojolicious::Plugin::Fondation::Group](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AGroup),
[Mojolicious::Plugin::Fondation::User::UI::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser%3A%3AUI%3A%3ABootstrap),
[Mojolicious::Plugin::Fondation::Layout::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ALayout%3A%3ABootstrap)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
