package MyDBIC::Main::CdEdition;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd_edition');
__PACKAGE__->add_columns(
    cdid => {
        data_type         => 'bigint',
        is_auto_increment => 0,
        is_nullable       => 0,
    },
    lang => {
        data_type   => 'char',
        size        => '2',
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key( 'cdid', 'lang' );
__PACKAGE__->belongs_to( 'cdid' => 'MyDBIC::Main::Cd' );
__PACKAGE__->has_many(
    'cd_collections' => 'MyDBIC::Main::CdCollection',
    { 'foreign.cdid' => 'self.cdid', 'foreign.lang' => 'self.lang' },
);

sub schema_class_prefix {'MyDBIC::Main'}

1;
