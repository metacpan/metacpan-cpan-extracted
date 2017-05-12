# -*-perl-*-

# $Id: 33_dbi_discover_field.t,v 3.1 2002/09/09 12:40:37 lachoy Exp $

use strict;
use constant NUM_TESTS       => 7;
use constant TEST_TABLE_NAME => 'foo';

my $SPOPS_CLASS = 'DBIDiscoverTest';

my ( $db, $do_end );

END {
    cleanup( $db, TEST_TABLE_NAME ) if ( $do_end );
 }

sub DBIDiscoverTest::global_datasource_handle { return $db }

{
    # Grab our DBI routines and be sure we're supposed to run.

    do "t/dbi_config.pl";
    my $config = test_dbi_run();
    $do_end++;

    require Test::More;
    Test::More->import( tests => NUM_TESTS );

    require_ok( 'SPOPS::Initialize' );

    my $driver_name = $config->{DBI_driver};
    my $spops_dbi_driver = get_spops_driver( $config, $driver_name );

    $db = get_db_handle( $config );
    create_table( $db, 'simple', TEST_TABLE_NAME );

    # Create the class using SPOPS::Initialize

    my $spops_config = {
        tester => {
           class        => $SPOPS_CLASS,
           isa          => [ $spops_dbi_driver, 'SPOPS::DBI' ],
           rules_from   => [ 'SPOPS::Tool::DBI::DiscoverField' ],
           field        => [],
           id_field     => 'spops_id',
           base_table   => TEST_TABLE_NAME,
           table_name   => TEST_TABLE_NAME,
           field_discover => 'yes',
        },
    };
    my $class_init_list = eval { SPOPS::Initialize->process({ config => $spops_config }) };
    diag( "Warning from initialize: $@" ) if ( $@ );
    ok( ! $@, 'Initialize process run' );
    is( $class_init_list->[0], $SPOPS_CLASS, 'Initialize class' );

    my $field_list = $SPOPS_CLASS->field_list();
    is( $field_list->[0], 'spops_id', 'Field 1 ok' );
    is( $field_list->[1], 'spops_name', 'Field 2 ok' );
    is( $field_list->[2], 'spops_goop', 'Field 3 ok' );
    is( $field_list->[3], 'spops_num', 'Field 4 ok' );
}
