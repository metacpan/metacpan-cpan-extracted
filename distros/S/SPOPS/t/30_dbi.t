# -*-perl-*-

# $Id: 30_dbi.t,v 3.5 2003/05/10 19:22:41 lachoy Exp $

# Note that this is a good way to see if certain databases support the
# type checking methods of the DBI -- in fact, we might want to add
# some date/datetime items in the table as well to see what happens

use strict;
use Data::Dumper qw( Dumper );

use constant NUM_TESTS       => 62;
use constant TEST_TABLE_NAME => 'spops_test';

my $SPOPS_CLASS = 'DBITest';
my @ID_LIST     = ( 42, 1792, 1588 );

my ( $db, $do_end );

END {
    cleanup( $db, TEST_TABLE_NAME ) if ( $do_end );
 }

# Table definition, just for reference
# CREATE TABLE foo (
#    spops_id    int not null primary key,
#    spops_name  char(20),
#    spops_goop  char(20) not null,
#    spops_num   int default 2
# )

{
    # Grab our DBI routines and be sure we're supposed to run.

    do "t/dbi_config.pl";

    my $config = test_dbi_run();

    $do_end++;

    require Test::More;
    Test::More->import( tests => NUM_TESTS );

    # Ensure we can get to SPOPS::Initialize
    require_ok( 'SPOPS::Initialize' );

    my $driver_name = $config->{DBI_driver};
    my $spops_dbi_driver = get_spops_driver( $config, $driver_name );

    # Create the class using SPOPS::Initialize

    my $spops_config = {
        tester => {
           class        => $SPOPS_CLASS,
           isa          => [ $spops_dbi_driver, 'SPOPS::DBI' ],
           field        => [ qw/ spops_id spops_name spops_goop spops_num / ],
           id_field     => 'spops_id',
           skip_undef   => [ 'spops_num' ],
           sql_defaults => [ 'spops_num' ],
           base_table   => TEST_TABLE_NAME,
           table_name   => TEST_TABLE_NAME,
        },
    };
    my $class_init_list = eval {
        SPOPS::Initialize->process({ config => $spops_config })
    };
    ok( ! $@, 'Initialize process run' );
    is( $class_init_list->[0], $SPOPS_CLASS, 'Initialize class' );

    check_dbd_compliance( $config, $driver_name, $SPOPS_CLASS );

    # Check that class was initialized ok

    is( scalar @{ $SPOPS_CLASS->field_list },
        scalar @{ $spops_config->{tester}{field} },
        "Class initialize set 'field_list' property" );
    is( $SPOPS_CLASS->table_name, TEST_TABLE_NAME,
        "Class initialize set 'table_name' property" );

    # Create a database handle and create our testing table

    $db = get_db_handle( $config );
    create_table( $db, 'simple', TEST_TABLE_NAME );
    my $sql_data_types = get_sql_types( $db, TEST_TABLE_NAME, $driver_name );

    # See whether we get back the right information for various
    # configuration items

    {
        my $base_id_field = $SPOPS_CLASS->id_field;
        my ( $id_field ) = $SPOPS_CLASS->id_field_select;
        is( $id_field, TEST_TABLE_NAME . ".$base_id_field", "ID field for SELECT" );
        my ( $nq_id_field ) = $SPOPS_CLASS->id_field_select({ noqualify => 1 });
        is( $nq_id_field, $base_id_field, "ID field for SELECT (not qualified)" );

        my $id_for_clause = 45;
        my $data_type = $sql_data_types->{ $base_id_field };
        my $quoted = $db->quote( $id_for_clause, $data_type );
        my $id_clause = $SPOPS_CLASS->id_clause( $id_for_clause, undef,
                                                 { db => $db } );
        is( $id_clause, TEST_TABLE_NAME . ".$base_id_field = $quoted", "ID clause" );
        my $nq_id_clause = $SPOPS_CLASS->id_clause( $id_for_clause, 'noqualify',
                                                    { db => $db } );
        #warn "Datatype: [$data_type]; Clauses: [$id_clause] [$nq_id_clause]\n";
        is( $nq_id_clause, "$base_id_field = $quoted", "ID clause" );
    }

    # Create an object

    {
        my $obj = eval { $SPOPS_CLASS->new({ spops_name => 'MyProject',
                                             spops_goop => 'oopie doop',
                                             spops_num  => 241,
                                             spops_id   => 42 } ) };
        ok( ! $@, 'Create object' );

        # Save the object

        eval { $obj->save({ is_add => 1, db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Save object (create)' );
        if ( $@ ) {
            warn "Error saving object: $@\n", Dumper( SPOPS::Error->get ), "\n";
        }
    }

    # Try to fetch an object with an empty ID

    {
        my $obj = eval { $SPOPS_CLASS->fetch( '', { db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Fetch object (empty ID)' );
        is( $obj, undef, 'Fetched object with empty ID is undef' );

        my $obj_u = eval { $SPOPS_CLASS->fetch( undef, { db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Fetch object (undef ID)' );
        is( $obj, undef, 'Fetched object with undef ID is undef' );
    }

    # Fetch an object, then update it

    {
        my $obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db, skip_cache => 1 } ) };
        ok( ! $@, 'Fetch object (perform)' );
        if ( $@ ) {
            warn "Cannot fetch object: $@\n", Dumper( SPOPS::Error->get ), "\n";
        }

        ok( $obj->{spops_name} eq 'MyProject', 'Fetch object (correct data)' );

        $obj->{spops_name} = 'TheirProject';
        $obj->{spops_goop} = 'over there';
        eval { $obj->save({ db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Save object (update)' );
        if ( $@ ) {
            warn "Cannot update object: $@\n", Dumper( SPOPS::Error->get ), "\n";
        }

        my $new_obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db, skip_cache => 1 } ) };
        ok( $new_obj->{spops_name} eq $obj->{spops_name}, 'Fetch object (after update)' );
    }

    # Fetch an object then clone it and save it

    {
        my $obj     = eval { $SPOPS_CLASS->fetch( 42, { db => $db, skip_cache => 1 } ) };
        my $new_obj = eval { $obj->clone({ spops_name => 'YourProject',
                                           spops_goop => 'this n that',
                                           spops_id   => 1792 } ) };
        ok( ! $@, 'Clone object (perform)' );
        ok( $new_obj->{spops_name} ne $obj->{spops_name}, 'Clone object (correct data)');

        eval { $new_obj->save( { is_add => 1, db => $db, skip_cache => 1 } ) };
        ok( ! $@, 'Save object (create, after clone)' );
        if ( $@ ) {
            warn "Cannot save object: $@\n", Dumper( SPOPS::Error->get ), "\n";

        }
    }

    # Create another object, but this time don't define the spops_num
    # field and see if the default comes through. Also pass along an
    # 'insert_alter' statement and see if it worked.

    {
        my $obj = $SPOPS_CLASS->new({ spops_id   => 1588,
                                      spops_goop => 'here we go!',
                                      spops_name => 'AnotherProject' });
        eval { $obj->save({ is_add => 1, db => $db, skip_cache => 1,
                            insert_alter => { spops_goop => "'added -- %s'" } }) };
        ok( ! $@, 'Insert object with default data unspecified' );
        is( $obj->{spops_num}, 2, 'Fetch object (correct data with default)' );

        my $redo_obj = eval { $SPOPS_CLASS->fetch( $obj->id,
                                                   { db => $db, skip_cache => 1 } ) };
        is( $redo_obj->{spops_goop}, "added -- here we go!", 'Insert alter' );
    }

    # Fetch one of the above objects, update by hand one of the values
    # in the table and then refetch that field to see if it works

    {
        my $obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db,
                                                    skip_cache => 1 } ) };
        my $orig = $obj->{spops_name};
        my $new_set  = "Changed for refetch";
        my $sql = 'UPDATE ' . TEST_TABLE_NAME .
                  '   SET spops_name = ? ' .
                  ' WHERE ' . $obj->id_clause( undef, undef, { db => $db }) ;
        my ( $sth );
        eval {
            $sth = $db->prepare( $sql );
            $sth->execute( $new_set );
        };
        ok( ! $@, 'Update for refetch' );
        my $new_return = $obj->refetch( 'spops_name', { db => $db } );
        is( $obj->{spops_name}, $new_set, 'Refetched field match' );
        is( $new_return, $new_set, 'Refetched and returned field match' );
    }

    # Fetch one of the above objects, then update only one field

    {
        my $obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db,
                                                    skip_cache => 1 } ) };
        my $changed = 'One field update';
        $obj->{spops_name} = $changed;
        my $rv = eval { $obj->field_update( 'spops_name', { db => $db } ) };
        diag( "[RV $rv] $@" ) if ( $@ );
        ok( $rv && ! $@, 'Field update (single) execution' );
        is( $obj->{spops_name}, $changed, 'Field update (single) internal match' );
        my $redo_obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db,
                                                         skip_cache => 1 } ) };
        is( $redo_obj->{spops_name}, $obj->{spops_name}, 'Field update (single) external match' );
    }

    # Now try to do a field update with multiple fields
    {
        my $obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db,
                                                    skip_cache => 1 } ) };
        my $changed_text = 'Multi field update';
        my $changed_num  = 1066;
        my $rv = eval { $obj->field_update({ spops_name => $changed_text,
                                             spops_num  => $changed_num },
                                          { db => $db } ) };
        warn $@ if ( $@ );
        ok( $rv && ! $@, 'Field update (multiple) execution' );
        is( $obj->{spops_name}, $changed_text, 'Field update (multiple) internal match' );
        is( $obj->{spops_num}, $changed_num, 'Field update (multiple) internal match' );
        my $redo_obj = eval { $SPOPS_CLASS->fetch( 42, { db => $db,
                                                         skip_cache => 1 } ) };
        is( $redo_obj->{spops_name}, $obj->{spops_name}, 'Field update (multiple) external match' );
        is( $redo_obj->{spops_num}, $obj->{spops_num}, 'Field update (multiple) external match' );
    }

    # Now do a field update with multiple objects (class-level call)
    {
        my $changed_text = 'Multi field update';
        my $rv = eval { $SPOPS_CLASS->field_update( { spops_name => $changed_text },
                                                    { db         => $db,
                                                      where      => 'spops_num > 0' } ) };
        warn $@ if ( $@ );
        ok( $rv, 'Field update (multiple object) execution' );
        my $obj_list = eval { $SPOPS_CLASS->fetch_group({ db => $db, skip_cache => 1 }) };
        warn $@ if ( $@ );
        is( $obj_list->[0]->{spops_name}, $changed_text, 'Field update (multiple object 1) match' );
        is( $obj_list->[1]->{spops_name}, $changed_text, 'Field update (multiple object 2) match' );
        is( $obj_list->[2]->{spops_name}, $changed_text, 'Field update (multiple object 3) match' );
    }

    # Try a class-level field update where we match a single object

    {
        my $changed = 'Class level update';
        my $rv = eval { $SPOPS_CLASS->field_update( { spops_name => $changed },
                                                    { where => 'spops_num = 1066',
                                                      db    => $db } ) };
        warn $@ if ( $@ );
        ok( $rv, 'Field update (multiple object) execution with one match' );
        my $obj_list = eval { $SPOPS_CLASS->fetch_group({ where => 'spops_num = ?',
                                                          value => [ 1066 ],
                                                          db    => $db,
                                                          skip_cache => 1 }) };
        is( $obj_list->[0]{spops_name}, $changed, 'Field update (single object) match' );
    }

    # Try a field update with multiple objects (class-level call)
    # where nothing matches

    {
        my $changed_text = 'Multi field update';
        my $rv = eval { $SPOPS_CLASS->field_update( { spops_name => $changed_text },
                                                    { db    => $db,
                                                      where => 'spops_num < 0' } ) };
        warn $@ if ( $@ );
        is( int( $rv ), 0, 'Field update (multiple object) execution with no match' );
    }

    # Fetch the three objects in the db and be sure we got them all

    {
        my $obj_list = eval { $SPOPS_CLASS->fetch_group({ db => $db, skip_cache => 1 } ) };
        ok( ! $@, 'Fetch group' );
        if ( $@ ) {
            warn "Cannot retrieve objects: $@\n", Dumper( SPOPS::Error->get ), "\n";
        }

        ok( ref $obj_list eq 'ARRAY' && scalar @{ $obj_list } == 3, 'Fetch group (return check)' );
    }

    # Fetch a count of the objects in the database

    {
        my $obj_count = eval { $SPOPS_CLASS->fetch_count({ db => $db }) };
        ok( ! $@, 'Fetch count execution' );
        is( $obj_count, 3, 'Fetch count value' );

        my $skip_obj_count = eval {
            $SPOPS_CLASS->fetch_count({ db            => $db,
                                        skip_security => 1 })
        };
        ok( ! $@, 'Fetch count execution (security skipped)' );
        is( $skip_obj_count, 3, 'Fetch count value (security_skipped)' );
    }

    # Create an iterator and run through the objects

    {
        my $iter = eval { $SPOPS_CLASS->fetch_iterator({ db         => $db,
                                                         skip_cache => 1 }) };
        ok( ! $@, 'Fetch iterator execution' );
        ok( $iter->isa( 'SPOPS::Iterator::DBI' ), 'Iterator returned (fetch_iterator)' );
        my $count = 0;
        $count++ while ( my $obj = $iter->get_next );
        is( $count, 3, 'Iterator fetch count (fetch_iterator)' );
    }

    # Create an iterator from the object IDs then run through them

    {
        my $iter = SPOPS::Iterator::DBI->new({ id_list => \@ID_LIST,
                                               class   => $SPOPS_CLASS,
                                               db      => $db });
        ok( $iter->isa( 'SPOPS::Iterator::DBI' ), 'Iterator returned (ID list)' );
        my $count = 0;
        $count++ while ( my $obj = $iter->get_next );
        is( $count, 3, 'Iterator fetch count (ID list)' );
    }

    # Define an object but pass in a per-object 'no_insert' definition
    {
        my $obj = $SPOPS_CLASS->new({ spops_id => 4001, spops_name => 'FOO!',
                                      spops_goop => 'OOF!', spops_num => 4001 });
        eval { $obj->save({ is_add => 1,
                            no_insert => [ 'spops_name' ],
                            db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Insert object with "no_insert" field specified' );
        isnt( $obj->{spops_name}, 'FOO!', 'Data reset for no_insert field in object' );
        my $new_obj = eval { $SPOPS_CLASS->fetch( 4001, { db => $db,
                                                          skip_cache => 1 }) };
        ok( ! $@, 'Refetch no_insert object' );
        isnt( $new_obj->{spops_name}, 'FOO!', 'Fetched data proper data for no_insert field' );
    }

    # Fetch an object for updating, change a field and ensure it
    # didn't change

    {
        my $obj = eval { $SPOPS_CLASS->fetch( 4001,
                                              { db => $db, skip_cache => 1 }) };
        ok( ! $@, "Fetch object for no_update" );
        my $old_value = $obj->{spops_num};
        $obj->{spops_num} = 5555;
        eval { $obj->save({ no_update => [ 'spops_num' ],
                            db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Update object with "no_update" field specified' );
        my $new_obj = eval { $SPOPS_CLASS->fetch( 4001,
                                                  { db => $db, skip_cache => 1 }) };
        ok( ! $@, 'Refetch no_update object' );
        is( $new_obj->{spops_num}, $old_value, 'Old value not overwritten for no_update field' );
    }

# Future testing ideas:
#  - security
#  - timestamp checking
#  - fetch_group using 'where'

}

