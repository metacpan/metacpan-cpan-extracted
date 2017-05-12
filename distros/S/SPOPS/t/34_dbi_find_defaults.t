# -*-perl-*-

# $Id: 34_dbi_find_defaults.t,v 3.0 2002/08/28 01:16:32 lachoy Exp $

use strict;
use constant NUM_TESTS       => 5;

my $TEST_TABLE_NAME = 'foo';

my $SPOPS_CLASS = 'DBIDefaultsTest';

my ( $db, $do_end );

END {
    cleanup( $db, $TEST_TABLE_NAME ) if ( $do_end );
 }

sub DBIDefaultsTest::global_datasource_handle { return $db }

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
    create_table( $db, 'simple', $TEST_TABLE_NAME );

    # Before we create the SPOPS class, we need to insert a record to
    # use as the default

    my $DEFAULT_ID   = 5;
    my $DEFAULT_NAME = 'DEFAULT_NAME';
    my $DEFAULT_GOOP = 'DEFAULT_GOOP';

    my $sql = <<SQL;
INSERT INTO $TEST_TABLE_NAME
( spops_id, spops_name, spops_goop )
VALUES
( $DEFAULT_ID, '$DEFAULT_NAME', '$DEFAULT_GOOP' )
SQL

    eval { $db->do( $sql ) };
    if ( $@ ) {
        die "Cannot run tests. Initial insert failed: $@";
    }

    # Create the class using SPOPS::Initialize

    my $spops_config = {
        tester => {
           class        => $SPOPS_CLASS,
           isa          => [ $spops_dbi_driver, 'SPOPS::DBI' ],
           rules_from   => [ 'SPOPS::Tool::DBI::FindDefaults' ],
           field        => [ qw( spops_id spops_name spops_goop spops_num ) ],
           id_field     => 'spops_id',
           base_table   => $TEST_TABLE_NAME,
           table_name   => $TEST_TABLE_NAME,
           find_default_id => 5,
           find_default_field => [ qw( spops_name spops_goop ) ],
        },
    };
    my $class_init_list = eval { SPOPS::Initialize->process({ config => $spops_config }) };
    ok( ! $@, 'Initialize process run' );
    is( $class_init_list->[0], $SPOPS_CLASS, 'Initialize class' );

    my $item = $SPOPS_CLASS->new();
    is( $item->{spops_name}, $DEFAULT_NAME, "Field 1 default set on new()" );
    is( $item->{spops_goop}, $DEFAULT_GOOP, "Field 2 default set on new()" );

    $item->{spops_name} = 'changed';
    $item->{spops_goop} = 'changed';
}
