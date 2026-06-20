package Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::Group;

# ABSTRACT: Test Result class for groups table

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('groups');

__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'user_group',
    'Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::UserGroup',
    'group_id',
);

use DBIx::Class::Relationship::ManyToMany::Async;
__PACKAGE__->many_to_many_async('users', 'user_group', 'user');

1;
