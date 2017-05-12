package # hide from PAUSE
    TDCSTest::Schema::Artist;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
    qw<
        artistid
        personid
        name
    >
);

__PACKAGE__->set_primary_key('artistid');

__PACKAGE__->belongs_to( person => 'TDCSTest::Schema::Person', 'personid' );

__PACKAGE__->has_many( 'cds' => 'TDCSTest::Schema::CD', 'artistid' );

1;
