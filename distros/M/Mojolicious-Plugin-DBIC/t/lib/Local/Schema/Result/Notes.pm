package Local::Schema::Result::Notes;
use parent 'DBIx::Class::Core';
__PACKAGE__->table( 'notes' );
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    title => {
        data_type => 'varchar',
    },
    description => {
        data_type => 'text',
    },
);
__PACKAGE__->set_primary_key( 'id' );
1;
