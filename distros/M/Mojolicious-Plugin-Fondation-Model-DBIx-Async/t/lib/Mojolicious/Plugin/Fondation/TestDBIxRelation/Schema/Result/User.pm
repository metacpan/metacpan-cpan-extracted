package Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::User;

# ABSTRACT: Test Result class for users table

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'user_group',
    'Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::UserGroup',
    'user_id',
);

use DBIx::Class::Relationship::ManyToMany::Async;
__PACKAGE__->many_to_many_async('groups', 'user_group', 'group');

1;
