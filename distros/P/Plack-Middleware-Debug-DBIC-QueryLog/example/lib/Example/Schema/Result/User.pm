package Example::Schema::Result::User;
use parent 'Example::Schema::Result';

__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'varchar',
        size => '36',
    },
    email => {
        data_type => 'varchar',
        size => '96',
    },
    created => {
        data_type => 'datetime', 
        set_on_create => 1,
        set_on_update => 1,
    },
);
__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->add_unique_constraint(['email']);

1;

