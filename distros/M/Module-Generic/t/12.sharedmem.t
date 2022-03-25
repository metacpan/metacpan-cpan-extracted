#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test2::IPC;
    use Test2::V0;
    use lib './lib';
    use POSIX ":sys_wait_h";
    use ok( 'Module::Generic::SharedMem' ) || bail_out( "Unable to load Module::Generic::SharedMem" );
    our $IS_SUPPORTED = 1;
    if( !Module::Generic::SharedMem->supported )
    {
        # plan skip_all => 'IPC::SysV not supported on this system';
        $IS_SUPPORTED = 0;
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

SKIP:
{
    skip( 'IPC::SysV not supported on this system', 26 ) if( !$IS_SUPPORTED );
    ok( scalar( keys( %$Module::Generic::SharedMem::SEMOP_ARGS ) ) > 0, 'sempahore parameters' );
    bail_out( '$SEMOP_ARGS not set somehow!' ) if( !scalar( keys( %$Module::Generic::SharedMem::SEMOP_ARGS ) ) );

    ok( Module::Generic::SharedMem->supported, 'supported' );

    my $shem = Module::Generic::SharedMem->new(
        debug => $DEBUG,
        key => 'test_key',
        size => 2048,
        destroy => 0,
        mode => 0666,
    );
    # Clean up

    ok( $shem->create == 0, 'create default value' );
    $shem->create(1);
    ok( $shem->create == 1, 'create updated value' );
    my $exists = $shem->exists;
    # ok( defined( $exists ), 'exists return defined value' );
    # ok( !$shem->exists, 'exists' );
    # Some previous test did not cleanup
    if( defined( $exists ) && $exists )
    {
        diag( "Cleaning up previous tests that left the shared memory." ) if( $DEBUG );
        $shem->open->remove;
    }
    ok( defined( $exists ) && !$exists, 'exists' );
    my $s = $shem->open({ mode => 'w' });
    defined( $s ) || do
    {
        diag( "Failed to open shared memory: ", $shem->error ) if( $DEBUG );
    };
    local $SIG{__DIE__} = sub
    {
        diag( "Got error: ", join( '', @_ ), ". Cleaning up shared memory." ) if( $DEBUG );
        $s->unlock;
        $s->remove;
    };
    skip( "Failed to create shared memory object. Your system does not seem to support shared memory: $!", 21 ) if( !defined( $s ) );
    ok( defined( $s ), 'open return value' );

    isa_ok( $s, ['Module::Generic::SharedMem'], 'Shared memory object' );
    my $id = $s->id;
    ok( defined( $id ) && $id =~ /\S+/, "shared memory id is \"$id\"" );
    my $semid = $s->semid;
    ok( defined( $semid ) && $semid =~ /\S+/, "semaphore id is \"$semid\"" );
    my $owner = $s->owner;
    ok( defined( $owner ) && $owner =~ /\S+/, "shared memory owner \"$owner\"" );
    my $test_data = { name => 'John Doe', location => 'Tokyo' };
    my $shem_object = $s->write( $test_data );
    ok( defined( $shem_object ), 'write' );
    ok( overload::StrVal( $s ) eq overload::StrVal( $shem_object ), 'write return value' );
    my $buffer = $s->read;
    ok( defined( $buffer ), 'read no argument' );
    ok( ref( $buffer ) eq 'HASH', 'read buffer data integrity' );
    if( ref( $buffer ) eq 'HASH' && $buffer->{name} eq 'John Doe' && $buffer->{location} eq 'Tokyo' )
    {
        pass( 'read data check' );
    }
    else
    {
        fail( 'read data check' );
    }

    # Block signal for fork
    my $sigset = POSIX::SigSet->new( POSIX::SIGINT );
    POSIX::sigprocmask( POSIX::SIG_BLOCK, $sigset ) || 
        bail_out( "Cannot block SIGINT for fork: $!" );
    select((select(STDOUT), $|=1)[0]);
    select((select(STDERR), $|=1)[0]);
    my $pid = fork();
    skip( "Unable to fork: $!", 9 ) unless( defined( $pid ) );
    if( $pid )
    {
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK, $sigset ) ||
            bail_out( "Cannot unblock SIGINT for fork: $!" );
        if( kill( 0 => $pid ) || $!{EPERM} )
        {
            diag( "Child process with pid '$pid' is still running, waiting for it to complete." ) if( $DEBUG );
            # Blocking wait
            waitpid( $pid, 0 );
            my $exit_status  = ( $? >> 8 );
            my $exit_signal  = $? & 127;
            my $has_coredump = ( $? & 128 );
            diag( "Child process exited with value $?" ) if( $DEBUG );
            if( WIFEXITED($?) )
            {
                diag( "Child with pid '$pid' exited with bit value '$?' (exit=${exit_status}, signal=${exit_signal}, coredump=${has_coredump})." ) if( $DEBUG );
            }
            else
            {
                diag( "Child with pid '$pid' exited with bit value '$?' -> $!" ) if( $DEBUG );
            }
        }
        else
        {
            diag( "Child process with pid '$pid' is already completed." ) if( $DEBUG );
            pass( "sub process exited rapidly" );
        }
        my $data = $s->read;
        ok( ref( $data ) eq 'HASH', 'shared updated data type' );
        if( ref( $data ) ne 'HASH' )
        {
            skip( 'parent: failed data type returned from child', 9 );
        }
        ok( $data->{year} == 2021, 'updated data value' );
        my $data2;
        $s->read( $data2 );
        ok( ref( $data2 ) eq 'HASH', 'different read usage' );
        if( ref( $data ) ne 'HASH' )
        {
            skip( 'parent: second read returned wrong data type.', 7 );
        }
        ok( $data2->{year} == 2021, 'different read data check' );
        my $rv = $s->lock || diag( "Unable to lock: ", $s->error );
        ok( $rv, 'lock' );
        ok( $s->locked, 'locked' );
        $data->{test} = 'ok';
        ok( defined( $s->write( $data ) ), 'updated data with lock' );
        ok( defined( $s->unlock ), 'unlock' );
        ok( defined( $s->remove ), 'remove' );
        ok( !$s->exists, 'exists after remove' );
    }
    elsif( $pid == 0 )
    {
        # We open it in write mode, but not create, because 80.notes.t will have created for us already
        my $shem2 = Module::Generic::SharedMem->new(
            debug => $DEBUG,
            create => 0,
            key => 'test_key',
            size => 2048,
            destroy => 0,
            mode => 0666,
        );
        # For debugging only
        # $shem->create(1);
        # $shem->destroy(1);
        SKIP:
        {
            my $s2 = $shem2->open;
            ok( $s2, 'child: shared memory opened' );
            if( !$s2 )
            {
                diag( "child: unable to open shared memory: ", $shem2->error );
                skip( "child: failed, unable to open shared memory.", 2 );
            }
            my $ref = $s2->read;
            if( !defined( $ref ) )
            {
                diag( "child: unable to open shared memory: ", $s2->error );
                skip( "child: failed, data retrieved is empty.", 2 );
            }
            ok( ref( $ref ), 'child: data type retrieved -> hash' );
            if( ref( $ref ) ne 'HASH' )
            {
                diag( "child: shared memory data ($ref) is not an hash reference." );
                skip( "child: failed, data retrieved is not hash reference.", 1 );
            }
            # $ref = {};
            $ref->{year} = 2021;
            my $rv = $s2->write( $ref );
            ok( $rv, 'child: wrote back to shared memory' );
            if( !defined( $rv ) )
            {
                diag( "child: unable to write to shared memory: ", $s2->error );
            };
        };
        exit(0);
    }
}

done_testing();

__END__

