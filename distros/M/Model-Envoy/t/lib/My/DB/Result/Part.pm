package My::DB::Result::Part;

use Moose;

extends 'DBIx::Class::Core';

__PACKAGE__->table('parts');
__PACKAGE__->add_columns(

    'id'        => { data_type => 'integer', is_nullable => 0, },
    'name'      => { data_type => 'text',   },
    'widget_id' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'widget', 'My::DB::Result::Widget', 'widget_id', );

sub sql {
    return 'create table parts ( id integer not null primary key, name varchar, widget_id integer)';
}

1;
