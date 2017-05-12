# -*-perl-*-

# $Id: 35_dbi_type_info.t,v 1.3 2003/01/03 05:12:50 lachoy Exp $

use strict;
use constant NUM_TESTS       => 35;
use constant TEST_TABLE_NAME => 'spops_test';

my ( $db, $do_end );

END {
    cleanup( $db, TEST_TABLE_NAME ) if ( $do_end );
 }

{
    # Grab our DBI routines and be sure we're supposed to run.

    do "t/dbi_config.pl";
    my $config = test_dbi_run();

    require Test::More;

    if ( $config->{DBI_driver} eq 'SQLite' ) {
        Test::More->import( skip_all => "Cannot test DBI types with DBD::SQLite" );
    }
    Test::More->import( tests => NUM_TESTS );

    require DBI;
    DBI->import( qw( SQL_VARCHAR SQL_INTEGER SQL_TIMESTAMP ) );

    $db = get_db_handle( $config );
    create_table( $db, 'simple', TEST_TABLE_NAME );
    $do_end++;

    require_ok( 'SPOPS::DBI::TypeInfo' );

    my $ti_simple = eval { SPOPS::DBI::TypeInfo->new({ database => 'foo',
                                                       table    => 'bar' }) };
    ok( ! $@, 'Object created' );
    is( ref $ti_simple, 'SPOPS::DBI::TypeInfo', 'Type of object created' );
    is( $ti_simple->database, 'foo', 'Database set in constructor' );
    is( $ti_simple->table, 'bar', 'Table set in constructor' );

    my @simple_fields = ( 'one', 'two', 'three' );
    my @simple_types  = ( DBI::SQL_VARCHAR(), DBI::SQL_INTEGER(), DBI::SQL_TIMESTAMP() );
    my $ti_defined = eval { SPOPS::DBI::TypeInfo->new({
                              database => 'foo',
                              table    => 'bar',
                              fields   => \@simple_fields,
                              types    => \@simple_types }) };
    ok( ! $@, 'Object with fields and types created' );
    is_deeply( [ $ti_defined->get_fields ], \@simple_fields, 'Fields set' );
    is_deeply( [ $ti_defined->get_types ], \@simple_types, 'Types set' );
    is( $ti_defined->get_type( 'one' ), DBI::SQL_VARCHAR(), 'Field one set' );
    is( $ti_defined->get_type( 'two' ), DBI::SQL_INTEGER(), 'Field two set' );
    is( $ti_defined->get_type( 'three' ), DBI::SQL_TIMESTAMP(), 'Field three set' );


    my %simple_map = ( one   => 'char',
                         two   => 'int',
                         three => 'date' );
    my $ti_mapped = eval { SPOPS::DBI::TypeInfo->new({
                              database => 'foo',
                              table    => 'bar',
                              map      => \%simple_map }) };
    ok( ! $@, 'Object with mapped fields and types created' );
    is( scalar $ti_mapped->get_fields, 3, 'Fields mapped set' );
    is( scalar $ti_mapped->get_types, 3, 'Types mapped set' );
    is( $ti_mapped->get_type( 'one' ), DBI::SQL_VARCHAR(), 'Field mapped with fake type one set' );
    is( $ti_mapped->get_type( 'two' ), DBI::SQL_INTEGER(), 'Field mapped with fake type two set' );
    is( $ti_mapped->get_type( 'three' ), DBI::SQL_DATE(), 'Field mapped with fake type three set' );

    my $ti_shortcut =
         eval { SPOPS::DBI::TypeInfo->new({
                         database => 'foo',
                         table    => TEST_TABLE_NAME })->fetch_types( $db ) };
    diag( $@ ) if ( $@ );
    ok( ! $@, 'Object created with shortcut from fetching types' );
    is( scalar $ti_shortcut->get_fields, 4, 'Fields shortcut set' );
    is( scalar $ti_shortcut->get_types, 4, 'Types shortcut set' );
    is( $ti_shortcut->get_type( 'spops_id' ), DBI::SQL_INTEGER(), 'Field shortcut one set' );
    ok( $ti_shortcut->get_type( 'spops_name' ) == DBI::SQL_VARCHAR() ||
        $ti_shortcut->get_type( 'spops_name' ) == DBI::SQL_CHAR(), 'Field shortcut two set' );
    ok( $ti_shortcut->get_type( 'spops_goop' ) == DBI::SQL_VARCHAR() ||
        $ti_shortcut->get_type( 'spops_goop' ) == DBI::SQL_CHAR(), 'Field shortcut three set' );
    is( $ti_shortcut->get_type( 'spops_num' ), DBI::SQL_INTEGER(), 'Field shortcut four set' );

    # Ensure the fields/types as hash is returned ok

    my %map = $ti_shortcut->as_hash;
    is( scalar keys %map, 4, 'Number of fields in hash' );
    is( $map{spops_id}, DBI::SQL_INTEGER(), 'Field/type from hash one' );
    ok( $map{spops_name} == DBI::SQL_VARCHAR() ||
        $map{spops_name} == DBI::SQL_CHAR(), 'Field/type from hash two' );
    ok( $map{spops_goop} == DBI::SQL_VARCHAR() ||
        $map{spops_name} == DBI::SQL_CHAR(), 'Field/type from hash three' );
    is( $map{spops_num}, DBI::SQL_INTEGER(), 'Field/type from hash four' );

    my $added = eval { $ti_shortcut->add_type( 'spops_new', DBI::SQL_DATETIME() ) };
    ok( ! $@, 'New type added' );
    is( $added, DBI::SQL_DATETIME(), 'Return from get_type()' );
    my ( $added_new );
    {
        local $SIG{__WARN__} = sub {}; # get rid of warning from next line
        $added_new = eval { $ti_shortcut->add_type( 'SPOPS_NEW', DBI::SQL_INTEGER() ) };
    }
    ok( ! $@, 'New type to existing added (no error)' );
    is( $added_new, DBI::SQL_DATETIME(), 'Return from get_type() as previous value' );

    # Now some stuff that should fail

    my $ti_fail = eval { SPOPS::DBI::TypeInfo->new({ fields => [ 'a', 'b' ],
                                                      types => [ 'num' ] } ) };
    ok( $@, 'Constructor failed on uneven field/type assignment (good)' );

    $ti_fail = eval { SPOPS::DBI::TypeInfo->new()->fetch_types( $db ) };
    ok( $@, 'Retrieving types from DB failed without table set (good)' );
}
