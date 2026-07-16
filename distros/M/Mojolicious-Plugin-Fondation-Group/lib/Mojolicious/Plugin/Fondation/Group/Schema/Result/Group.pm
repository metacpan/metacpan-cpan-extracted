package Mojolicious::Plugin::Fondation::Group::Schema::Result::Group;
$Mojolicious::Plugin::Fondation::Group::Schema::Result::Group::VERSION = '0.01';
# ABSTRACT: DBIx::Class Result class for groups table

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/TimeStamp Core/);

__PACKAGE__->table('groups');

__PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },

    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
        extra       => {
            openapi => {
                minLength => 2,
                pattern   => '^[a-zA-Z0-9 _-]{2,}$',
            }
        },
    },

    active => {
        data_type     => 'integer',
        default_value => 1,
        is_nullable   => 0,
        extra         => {
            openapi => {
                enum   => [0, 1],
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },

    created_at => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },

    updated_at => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'user_group',
    'Mojolicious::Plugin::Fondation::Group::Schema::Result::UserGroup',
    'group_id',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Group::Schema::Result::Group - DBIx::Class Result class for groups table

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
