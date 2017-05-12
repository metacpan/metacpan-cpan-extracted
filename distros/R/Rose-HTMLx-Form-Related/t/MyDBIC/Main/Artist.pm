package MyDBIC::Main::Artist;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
    artistid => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    name => {
        data_type   => 'varchar',
        size        => 250,
        is_nullable => 0,
        indexed     => 1,
    },
);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many( 'cds' => 'MyDBIC::Main::Cd' );
__PACKAGE__->add_unique_constraint( ['name'] );

sub schema_class_prefix {'MyDBIC::Main'}

1;
