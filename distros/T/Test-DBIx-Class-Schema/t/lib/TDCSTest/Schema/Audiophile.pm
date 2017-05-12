package # hide from PAUSE
    TDCSTest::Schema::Audiophile;

use base 'DBIx::Class::Core';

__PACKAGE__->table('audiophile');

__PACKAGE__->add_columns(
    qw<
        personid
        shopid
    >
);

__PACKAGE__->set_primary_key('personid');

__PACKAGE__->has_many(
    cdshop_audiophiles => 'TDCSTest::Schema::CDShopAudiophile',
    { 'foreign.personid' => 'self.personid' },
);

__PACKAGE__->belongs_to(
    person => 'TDCSTest::Schema::Person',
    { 'foreign.personid' => 'self.personid' },
    { proxy => [qw/first_name/] },
);

__PACKAGE__->belongs_to(
    works_at => 'TDCSTest::Schema::Shop',
    { 'foreign.shopid' => 'self.shopid' },
    { proxy => [qw/employee_count name/] },
);

__PACKAGE__->many_to_many( 'cds', cdshop_audiophiles => 'cd' );

1;
