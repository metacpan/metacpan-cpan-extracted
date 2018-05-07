package My::DB::Result::Widget;

use Moose;

extends 'DBIx::Class::Core';

__PACKAGE__->table('widgets');
__PACKAGE__->add_columns(

    'id'      => { data_type => 'integer', is_nullable => 0, },
    'name'    => { data_type => 'text',    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( 'parts', 'My::DB::Result::Part', 'widget_id', );

sub sql {
    return 'create table widgets ( id integer not null primary key, name varchar)';
}

1;
