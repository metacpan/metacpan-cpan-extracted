package DBSchema::Result::Dvd;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';
use overload '""' => sub {$_[0]->name}, fallback => 1;

use lib '../../DBIx-Class-HTML-FormFu/lib/';
__PACKAGE__->load_components('InflateColumn::DateTime', 'Core');
__PACKAGE__->table('dvd');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  'imdb_id' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  'owner' => { data_type => 'integer' },
  'current_borrower' => { 
    data_type => 'integer', 
    is_nullable => 1,
  },

  'creation_date' => { 
    data_type => 'datetime',
    is_nullable => 1,
  },
  'alter_date' => { 
    data_type => 'datetime',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('owner', 'User', { id => 'owner' });
__PACKAGE__->belongs_to('current_borrower', 'User', { id => 'current_borrower' });
__PACKAGE__->has_many('dvdtags', 'Dvdtag', { 'foreign.dvd' => 'self.id' });
__PACKAGE__->many_to_many('tags', 'dvdtags' => 'tag');
__PACKAGE__->might_have(
    liner_notes => 'DBSchema::Result::LinerNotes', undef,
    { proxy => [ qw/notes/ ] },
);

1;

