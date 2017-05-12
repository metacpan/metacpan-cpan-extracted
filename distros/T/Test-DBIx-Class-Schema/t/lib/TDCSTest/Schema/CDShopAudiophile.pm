package # hide from PAUSE
    TDCSTest::Schema::CDShopAudiophile;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cdshop_audiophile');

__PACKAGE__->add_columns(
    qw<
        cdid
        shopid
        personid
    >
);

__PACKAGE__->set_primary_key(qw/cdid shopid personid/);

__PACKAGE__->belongs_to(
    cd => 'TDCSTest::Schema::CD',
    { 'foreign.cdid' => 'self.cdid' }
);

__PACKAGE__->belongs_to(
    shop => 'TDCSTest::Schema::Shop',
    { 'foreign.shopid' => 'self.shopid' }
);

__PACKAGE__->belongs_to(
    cdshop => 'TDCSTest::Schema::CDShop',
    [
        { 'foreign.cdid' => 'self.cdid' },
        { 'foreign.shopid' => 'self.shopid' },
    ]
);

__PACKAGE__->belongs_to(
    audiophile => 'TDCSTest::Schema::Audiophile',
    { 'foreign.personid' => 'self.personid' }
);

__PACKAGE__->belongs_to(
    person => 'TDCSTest::Schema::Person',
    { 'foreign.personid' => 'self.personid' }
);

1;
