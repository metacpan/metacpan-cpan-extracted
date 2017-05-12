package MyDBIC::Main::CdTrackJoin;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd_track_join');
__PACKAGE__->add_columns(qw/ trackid cdid /);
__PACKAGE__->set_primary_key( 'trackid', 'cdid' );
__PACKAGE__->belongs_to( 'cdid'    => 'MyDBIC::Main::Cd' );
__PACKAGE__->belongs_to( 'trackid' => 'MyDBIC::Main::Track' );

sub schema_class_prefix {'MyDBIC::Main'}

1;
