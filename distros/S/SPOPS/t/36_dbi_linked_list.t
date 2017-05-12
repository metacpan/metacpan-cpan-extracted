# -*-perl-*-

# $Id: 36_dbi_linked_list.t,v 1.4 2003/01/02 05:58:29 lachoy Exp $

use strict;
use constant NUM_TESTS       => 22;

my $TEST_TABLE_NAME = 'linked_list';
my $SPOPS_CLASS     = 'DBILinkedList';
my $TEST_TABLE_SQL  = <<TABLE;
CREATE TABLE $TEST_TABLE_NAME (
  object_id   int not null,
  prev_id     int null,
  next_id     int null,
  entered_on  int,
  primary key( object_id )
)
TABLE

my ( $db, $do_end );

END {
    cleanup( $db, $TEST_TABLE_NAME ) if ( $do_end );
 }

sub DBILinkedList::global_datasource_handle { return $db }

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
           rules_from        => [ 'SPOPS::Tool::DBI::MaintainLinkedList' ],
           field             => [ qw( object_id prev_id next_id entered_on ) ],
           skip_undef        => [ qw( prev_id next_id ) ],
           no_update         => [ qw( object_id ) ],
           id_field          => 'object_id',
           base_table        => $TEST_TABLE_NAME,
           table_name        => $TEST_TABLE_NAME,
           linklist_previous => 'prev_id',
           linklist_next     => 'next_id',
        },
    };
    my $class_init_list = eval { SPOPS::Initialize->process({ config => $spops_config }) };
    ok( ! $@, 'Initialize process run' );
    is( $class_init_list->[0], $SPOPS_CLASS, 'Initialize class' );

    #SPOPS->set_global_debug(2);

    # First see that everything works for the default head locator
    # ('null')

    my ( $item1, $item2, $item3, $item4 );
    eval {
        $item1 = $SPOPS_CLASS->new({ id => 1, entered_on => (time - 50000) })->save();
        $item2 = $SPOPS_CLASS->new({ id => 2, entered_on => (time - 40000) })->save();
        $item3 = $SPOPS_CLASS->new({ id => 3, entered_on => (time - 30000) })->save();
        $item4 = $SPOPS_CLASS->new({ id => 4, entered_on => (time - 20000) })->save();
    };

    # Check modifications in-place
    is( $item2->{prev_id}, 1, "Initial second previous" );
    is( $item3->{prev_id}, 2, "Initial third previous" );
    is( $item4->{prev_id}, 3, "Initial fourth previous" );

    # Check saved modifications
    my ( $new1, $new2, $new3, $new4 );
    eval {
        $new1 = $SPOPS_CLASS->fetch(1);
        $new2 = $SPOPS_CLASS->fetch(2);
        $new3 = $SPOPS_CLASS->fetch(3);
        $new4 = $SPOPS_CLASS->fetch(4);
    };
    is( $new1->{next_id}, 2, "Post first next" );
    is( $new2->{prev_id}, 1, "Post second previous" );
    is( $new2->{next_id}, 3, "Post second next" );
    is( $new3->{prev_id}, 2, "Post third previous" );
    is( $new3->{next_id}, 4, "Post third next" );
    is( $new4->{prev_id}, 3, "Post fourth previous" );
    is( $new4->{next_id}, undef, "Post fourth next" );

    # Check modifications after a remove
    eval { $new3->remove };
    my $rmv2 = $SPOPS_CLASS->fetch(2);
    my $rmv4 = $SPOPS_CLASS->fetch(4);
    is( $rmv2->{next_id}, 4, "Post remove second next" );
    is( $rmv4->{prev_id}, 2, "Post remove fourth previous" );

    # See whether the autogen methods work
    my $rmv2_next = $rmv2->next_in_list;
    my $rmv4_prev = $rmv4->previous_in_list;
    is( $rmv2_next->id, $rmv4->id, "Autogen next method" );
    is( $rmv4_prev->id, $rmv2->id, "Autogen previous method" );
    is( $rmv4->next_in_list, undef, "Autogen next method return undef" );

    # Now change the head locator methods and see how an insert works

    $SPOPS_CLASS->CONFIG->{linklist_head} = 'order';
    $SPOPS_CLASS->CONFIG->{linklist_head_order} = 'entered_on DESC';

    my $ordered5 = $SPOPS_CLASS->new({ id => 5, entered_on => (time - 10000) })->save();
    my $ordered4 = $SPOPS_CLASS->fetch(4);
    is( $ordered4->{next_id}, 5, "Ordered head insert next" );
    is( $ordered5->{prev_id}, 4, "Ordered head insert previous" );

    $SPOPS_CLASS->CONFIG->{linklist_head} = 'value';
    $SPOPS_CLASS->CONFIG->{linklist_head_value} = -1;

    $ordered5->{next_id} = -1;
    eval { $ordered5->save };

    my $value6 = $SPOPS_CLASS->new({ id => 6, entered_on => time })->save();
    my $value5 = $SPOPS_CLASS->fetch(5);

    is( $value5->{next_id}, 6, "Value head insert next" );
    is( $value6->{prev_id}, 5, "Value head insert previous" );
}
