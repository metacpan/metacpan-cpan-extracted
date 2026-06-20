package Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::UserGroup;

# ABSTRACT: Test Result class for user_group pivot table

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('user_group');

__PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    user_id  => { data_type => 'integer', is_nullable => 0 },
    group_id => { data_type => 'integer', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'user',
    'Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::User',
    { 'foreign.id' => 'self.user_id' },
);

__PACKAGE__->belongs_to(
    'grp',
    'Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::Group',
    { 'foreign.id' => 'self.group_id' },
);

1;
