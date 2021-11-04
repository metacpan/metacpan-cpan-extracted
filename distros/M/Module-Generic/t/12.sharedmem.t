#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    use lib './lib';
    use_ok( 'Module::Generic::SharedMem' ) || BAIL_OUT( "Unable to load Module::Generic::SharedMem" );
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
    BAIL_OUT( '$SEMOP_ARGS not set somehow!' ) if( !scalar( keys( %$Module::Generic::SharedMem::SEMOP_ARGS ) ) );

    ok( Module::Generic::SharedMem->supported, 'supported' );

    my $shem = Module::Generic::SharedMem->new(
        debug => $DEBUG,
        key => 'test_key',
        size => 2048,
        destroy => 1,
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
    my $s = $shem->open;
    local $SIG{__DIE__} = sub
    {
        diag( "Got error: ", join( '', @_ ), ". Cleaning up shared memory." ) if( $DEBUG );
        $s->unlock;
        $s->remove;
    };
    skip( "Failed to create shared memory object. Your system does not seem to support shared memory: $!", 21 ) if( !defined( $s ) );
    ok( defined( $s ), 'Shared memory object' );

    isa_ok( $s, 'Module::Generic::SharedMem' );
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
    my $result = qx( $^X ./t/12.sharedmem.pl 2>&1 );
    chomp( $result );
    if( $result eq 'ok' )
    {
        pass( 'shared data with separate process' );
    }
    else
    {
        diag( "Failed process with: '$result'" );
        fail( 'shared data with separate process' );
    }
    my $data = $s->read;
    ok( ref( $data ) eq 'HASH', 'shared updated data type' );
    ok( $data->{year} == 2021, 'updated data value' );
    my $data2;
    $s->read( $data2 );
    ok( ref( $data2 ) eq 'HASH', 'different read usage' );
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

done_testing();
