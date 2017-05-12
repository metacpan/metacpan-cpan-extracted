package # hide from PAUSE
    TDCSTest::Schema::Track;

use base 'DBIx::Class::Core';

__PACKAGE__->table('track');

__PACKAGE__->add_columns(
    qw<
        trackid
        cdid
        position
        title
    >
);

__PACKAGE__->set_primary_key('trackid');

__PACKAGE__->belongs_to( cd => 'TDCSTest::Schema::CD', 'cdid' );

1;
