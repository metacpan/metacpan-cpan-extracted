# -*-perl-*-

# $Id: 37_dbi_lazy_load.t,v 1.1 2003/02/21 05:41:29 lachoy Exp $

use strict;
use constant NUM_TESTS => 19;
use Data::Dumper qw( Dumper );

my $TEST_TABLE_NAME = 'lazy_load';
my $SPOPS_CLASS     = 'DBILazyLoad';
my $TEST_TABLE_SQL  = <<TABLE;
CREATE TABLE $TEST_TABLE_NAME (
  Object_id    int not null,
  title        varchar(30) not null,
  description  varchar(255) null,
  primary key( Object_id )
)
TABLE

my ( $db, $do_end );

my $long = join( "\n",
                 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam',
                 'nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat',
                 'volutpat. Ut wisi enim ad minim veniam, quis nostrud exercitation',
                 'ulliam corper suscipit lobortis nisl ut aliquip...' );

END {
    cleanup( $db, $TEST_TABLE_NAME ) if ( $do_end );
 }

sub DBILazyLoad::global_datasource_handle { return $db }

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
    create_table( $db, $TEST_TABLE_SQL, $TEST_TABLE_NAME );

    # Create the class using SPOPS::Initialize

    my $spops_config = {
        tester => {
           class             => $SPOPS_CLASS,
           isa               => [ $spops_dbi_driver, 'SPOPS::DBI' ],
           field             => [ qw( Object_id title description ) ],
           no_update         => [ qw( Object_id ) ],
           id_field          => 'Object_id',
           base_table        => $TEST_TABLE_NAME,
           table_name        => $TEST_TABLE_NAME,
           column_group      => { summary => [ qw( Object_id title ) ] },
        },
    };
    my $class_init_list = eval { SPOPS::Initialize->process({ config => $spops_config }) };
    ok( ! $@, 'Initialize process run' );
    is( $class_init_list->[0], $SPOPS_CLASS, 'Initialize class' );

    # First just jam some data in there

    $SPOPS_CLASS->new({ Object_id => 1, title => 'First',
                        description => $long })->save();
    $SPOPS_CLASS->new({ Object_id => 2, title => 'Second',
                        description => $long })->save();
    $SPOPS_CLASS->new({ Object_id => 3, title => 'Third',
                        description => $long })->save();
    $SPOPS_CLASS->new({ Object_id => 4, title => 'Fourth',
                        description => $long })->save();

    # Now try to fetch it back out grouped

    my $items = eval { $SPOPS_CLASS->fetch_group({ column_group => 'summary' }) };
    ok( ! $@, "Call to fetch_group with column_group" );
    is( scalar @{ $items }, 4, "Number of items fetched" );
    is( $items->[0]->{description}, $long, "First description retrieved" );
    is( $items->[0]->{Object_id}, 1, "First ID checked" );
    is( $items->[1]->{description}, $long, "Second description retrieved" );
    is( $items->[1]->{Object_id}, 2, "Second ID checked" );
    is( $items->[2]->{description}, $long, "Third description retrieved" );
    is( $items->[2]->{Object_id}, 3, "Third ID checked" );
    is( $items->[3]->{description}, $long, "Fourth description retrieved" );
    is( $items->[3]->{Object_id}, 4, "Fourth ID checked" );

    my $constrained = eval { $SPOPS_CLASS->fetch_group({
                                   column_group => 'summary',
                                   where => 'object_id >= 2 AND object_id <= 3' }) };
    ok( ! $@, "Call to fetch_group (constrained) with column group" );
    is ( scalar @{ $constrained }, 2, "Number of constrained items fetched" );
    is( $constrained->[0]->{description}, $long, "First constrained description retrieved" );
    is( $constrained->[0]->{Object_id}, 2, "First constrained ID checked" );
    is( $constrained->[1]->{description}, $long, "Second constrained description retrieved" );
    is( $constrained->[1]->{Object_id}, 3, "Second constrained ID checked" );
}
