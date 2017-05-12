package # hide from PAUSE
    TDCSTest::Schema::Person;

use base 'DBIx::Class::Core';

__PACKAGE__->table('person');

__PACKAGE__->add_columns(
    qw<
        personid
        first_name
    >
);

__PACKAGE__->set_primary_key('personid');

__PACKAGE__->might_have(
    audiophile => 'TDCSTest::Schema::Audiophile',
    { 'foreign.personid' => 'self.personid' },
);

__PACKAGE__->has_many(
    artists => 'TDCSTest::Schema::Artist',
    { 'foreign.personid' => 'self.personid' },
);

1;
