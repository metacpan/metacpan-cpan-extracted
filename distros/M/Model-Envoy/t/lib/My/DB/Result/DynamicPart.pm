package My::DB::Result::DynamicPart;

use Moose;

extends 'DBIx::Class::Core';

__PACKAGE__->table('parts');
__PACKAGE__->add_columns(

    'id'        => { data_type => 'integer', is_nullable => 0, },
    'name'      => { data_type => 'text',    is_nullable => 1, },
    'widget_id' => { data_type => 'integer', is_nullable => 1, },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'widget', 'My::DB::Result::DynamicWidget', 'widget_id', );

1;
