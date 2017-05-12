package # hide from PAUSE
    TDCSTest::Schema::Shop;

use base 'DBIx::Class::Core';

__PACKAGE__->table('shop');

__PACKAGE__->add_columns(
    qw<
        shopid
        name
    >
);

__PACKAGE__->set_primary_key('shopid');

1;
