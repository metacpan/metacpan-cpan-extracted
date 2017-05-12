package # hide from PAUSE
    TDCSTest::Schema::CDShop;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cd_shop');

__PACKAGE__->add_columns(
    qw<
        cdid
        shopid
    >
);

__PACKAGE__->set_primary_key(qw/cdid shopid/);

__PACKAGE__->belongs_to(
    cd => 'TDCSTest::Schema::CD',
    { 'foreign.cdid' => 'self.cdid' },
);

__PACKAGE__->belongs_to(
    shop => 'TDCSTest::Schema::Shop',
    { 'foreign.shopid' => 'self.shopid' }
);

__PACKAGE__->has_many(
    cdshop_audiophiles => 'TDCSTest::Schema::CDShopAudiophile',
    [
        { 'foreign.cdid' => 'self.cdid' },
        { 'foreign.shopid' => 'self.shopid' },
    ],
);

1;
