package # hide from PAUSE
    TDCSTest::Schema::CD;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cd');

__PACKAGE__->add_columns(
    qw<
        cdid
        artistid
        title
        year
    >
);

__PACKAGE__->set_primary_key('cdid');

__PACKAGE__->belongs_to( artist => 'TDCSTest::Schema::Artist', 'artistid' );

__PACKAGE__->belongs_to(
    artist_broken_self => 'TDCSTest::Schema::Artist',
    { 'foreign.artistid' => 'self.artistid_self' }
);
__PACKAGE__->belongs_to(
    artist_broken_foreign => 'TDCSTest::Schema::Artist',
    { 'foreign.artistid_foreign' => 'self.artistid' }
);


1;
