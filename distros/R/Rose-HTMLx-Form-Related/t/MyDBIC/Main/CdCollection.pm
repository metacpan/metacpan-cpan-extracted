package MyDBIC::Main::CdCollection;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd_collection');
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
    name => {
        data_type   => 'varchar',
        size        => '128',
        is_nullable => 0,
    },

);
__PACKAGE__->set_primary_key( 'cdid', 'lang' );
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->belongs_to(
    'cd_edition' => 'MyDBIC::Main::CdEdition',
    { 'foreign.cdid' => 'self.cdid', 'foreign.lang' => 'self.lang' }
);

sub schema_class_prefix {'MyDBIC::Main'}

1;
