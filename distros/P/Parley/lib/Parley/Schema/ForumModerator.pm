package Parley::Schema::ForumModerator;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use base 'DBIx::Class';

use Parley::Version;  our $VERSION = $Parley::VERSION;

__PACKAGE__->load_components('PK::Auto', 'Core');
__PACKAGE__->table('parley.forum_moderator');
__PACKAGE__->add_columns(
    id => {},

    person_id => {
        data_type       => "integer",
        default_value   => undef,
        is_nullable     => 0,
        size            => 4
    },

    forum_id => {
        data_type       => "integer",
        default_value   => undef,
        is_nullable     => 0,
        size            => 4
    },

    can_moderate => {
        data_type => "boolean",
        default_value => "false",
        is_nullable => 0,
        size => 1,
    },
);

__PACKAGE__->set_primary_key(qw/id/);

__PACKAGE__->add_unique_constraint(
    'forum_moderator_person_key',
    ['person_id', 'forum_id']
);
__PACKAGE__->belongs_to(
    'person' => 'Person',
    { 'foreign.id' => 'self.person_id' }
);
__PACKAGE__->belongs_to(
    'forum' => 'Forum',
    { 'foreign.id' => 'self.forum_id'  }
);

1;
