package Local::Schema::Result::Events;
use parent 'DBIx::Class::Core';
__PACKAGE__->table( 'events' );
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
    start_date => {
        data_type => 'date',
    },
    end_date => {
        data_type => 'date',
    },
);
__PACKAGE__->set_primary_key( 'id' );
1;
