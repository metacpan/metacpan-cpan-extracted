# -*-perl-*-

# $Id: 20_gdbm.t,v 3.0 2002/08/28 01:16:32 lachoy Exp $

use strict;
use constant GDBM_FILE => 'test.gdbm';
use constant NUM_TESTS => 17;

END {
    cleanup();
}

sub cleanup  { unlink GDBM_FILE if ( -f GDBM_FILE ) }

sub new_object {
    eval { GDBMTest->new({ name    => 'MyProject',
                           version => 1.14,
                           url     => 'http://www.cwinters.com/',
                           author  => 'La Choy (lachoy@cwinters.com)' }) };
}

{
    # Check to see if GDBM_File is installed

    eval { require GDBM_File };
    if ( $@ ) {
        print "1..0\n";
        print "Skipping test on this platform\n";
        exit;
    }

    require Test::More;
    Test::More->import( tests => NUM_TESTS );

    # Same with SPOPS::Initialize

    require_ok( 'SPOPS::Initialize' );

    my $spops_config = {
       tester => {
           class      => 'GDBMTest',
           isa        => [ 'SPOPS::GDBM' ],
           field      => [ qw/ name version author url / ],
           create_id  => sub { return join '-', $_[0]->{name}, $_[0]->{version} },
           gdbm_info  => { filename => GDBM_FILE },
       },
    };

    # Initialize class

    my $class_init_list = eval { SPOPS::Initialize->process({ config => $spops_config }) };
    ok( ! $@, "Initialize process run $@" );
    is( $class_init_list->[0], 'GDBMTest', 'Initialize class' );

    # Time for a test drive
    {
        # Make sure we can at least create an object
        my $obj = new_object;
        ok( ! $@, "Create object" );

        # Make sure GDBM_WRCREAT really creates a new file

        cleanup();
        $obj = new_object;
        eval { $obj->save({ perm => 'create' }) };
        ok( ! $@, 'Object saved (create permission)' );
        ok( -w GDBM_FILE, 'File created (create permission)' );

        # Make sure GDBM_WRITE gets changed to GDBM_WRCREAT if the file doesn't exist

        cleanup();
        $obj = new_object;
        eval { $obj->save({ perm => 'write' }) };
        ok( ! $@, 'Object saved (write permission)' );
        ok( -w GDBM_FILE, 'File created (write permission)' );

        # See if it does the Right Thing on its own

        cleanup();
        $obj = new_object;
        eval { $obj->save };
        ok( ! $@, 'Object saved (no permission)' );
        ok( -w GDBM_FILE, 'File created (no permission)' );

    }

    # Fetch an object, then clone it and save it (no cleanup from previous
    {
        my $obj = eval { GDBMTest->fetch( 'MyProject-1.14' ) };
        ok( ! $@, 'Fetch object' );
        is( $obj->{name}, 'MyProject', 'Fetch object (content check)' );

        my $new_obj = eval { $obj->clone({ name => 'YourProject', version => 1.02 }) };
        ok( ! $@, 'Clone object' );
        isnt( $new_obj->{name}, $obj->{name}, 'Clone object (override content)' );

        eval { $new_obj->save };
        ok( ! $@, 'Save object' );
    }

    # Fetch the two objects in the db and be sure we got them all
    {
        my $obj_list = eval { GDBMTest->fetch_group };
        ok( ! $@, 'Fetch group' );
        is( scalar @{ $obj_list }, 2, 'Fetch group (number check)' );
    }
}
