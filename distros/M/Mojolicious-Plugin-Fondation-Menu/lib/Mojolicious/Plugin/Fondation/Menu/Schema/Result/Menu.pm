package Mojolicious::Plugin::Fondation::Menu::Schema::Result::Menu;
$Mojolicious::Plugin::Fondation::Menu::Schema::Result::Menu::VERSION = '0.01';
# ABSTRACT: DBIx::Class Result class for menus table

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/TimeStamp Core/);

__PACKAGE__->table('menus');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
        extra => {
            openapi => {
                read => { required => 1 },
                list => { required => 1 },
            },
        },
    },

    title => {
        data_type   => 'text',
        is_nullable => 0,
        extra       => {
            openapi => {
                minLength => 1,
                create    => { required => 1 },
                update    => { required => 0 },
            },
        },
    },

    link => {
        data_type   => 'text',
        is_nullable => 1,
        extra       => {
            openapi => {
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    icon => {
        data_type   => 'text',
        is_nullable => 1,
        extra       => {
            openapi => {
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    icon_color => {
        data_type   => 'text',
        is_nullable => 1,
        extra       => {
            openapi => {
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    name => {
        data_type     => 'text',
        is_nullable   => 0,
        default_value => 'left',
        extra         => {
            openapi => {
                create => { required => 1 },
                update => { required => 0 },
            },
        },
    },

    condition => {
        data_type   => 'text',
        is_nullable => 1,
        extra       => {
            openapi => {
                description => 'Visibility condition: empty, group:NAME, or perm:NAME',
                create      => { required => 0 },
                update      => { required => 0 },
            },
        },
    },

    sort_order => {
        data_type     => 'integer',
        is_nullable   => 0,
        default_value => 0,
        extra         => {
            openapi => {
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    parent_id => {
        data_type     => 'integer',
        is_nullable   => 0,
        default_value => 0,
        extra         => {
            openapi => {
                description => 'Parent menu ID (0 for root)',
                create      => { required => 1 },
                update      => { required => 0 },
            },
        },
    },

    open_tab => {
        data_type     => 'integer',
        is_nullable   => 0,
        default_value => 0,
        extra         => {
            openapi => {
                enum   => [0, 1],
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    view_in_menu => {
        data_type     => 'integer',
        is_nullable   => 0,
        default_value => 1,
        extra         => {
            openapi => {
                enum   => [0, 1],
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    description => {
        data_type   => 'text',
        is_nullable => 1,
        extra       => {
            openapi => {
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    created_at => {
        data_type     => 'text',
        is_nullable   => 1,
        set_on_create => 1,
    },

    updated_at => {
        data_type     => 'text',
        is_nullable   => 1,
        set_on_create => 1,
        set_on_update => 1,
    },
);

__PACKAGE__->set_primary_key('id');

# ── Self-referential relationships ──────────────────────────────────────

__PACKAGE__->belongs_to(
    'parent',
    'Mojolicious::Plugin::Fondation::Menu::Schema::Result::Menu',
    'parent_id',
    { join_type => 'left', is_nullable => 1 },
);

__PACKAGE__->has_many(
    'children',
    'Mojolicious::Plugin::Fondation::Menu::Schema::Result::Menu',
    'parent_id',
    { order_by => { -asc => 'sort_order' } },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Menu::Schema::Result::Menu - DBIx::Class Result class for menus table

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
