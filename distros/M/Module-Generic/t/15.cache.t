#!perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Test2::IPC;
    use Test2::V0;
    # use Test::More;
    use POSIX ":sys_wait_h";
    $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'Module::Generic::File::Cache' );
};

use strict;
use warnings;

$Module::Generic::File::Cache::DEBUG = $DEBUG;

SKIP:
{
    use strict;
    use warnings;

    my $cache = Module::Generic::File::Cache->new(
        debug => $DEBUG,
        key => 'test_key',
        size => 2048,
        # destroy => 1,
        destroy => 0,
        mode => 0666,
    );

    ok( $cache->create == 0, 'create default value' );
    $cache->create(1);
    ok( $cache->create == 1, 'create updated value' );
    my $exists = $cache->exists;
    if( defined( $exists ) && $exists )
    {
        diag( "Cleaning up previous tests that left the shared cache." ) if( $DEBUG );
        $cache->open->remove;
    }
    ok( defined( $exists ) && !$exists, 'exists' );
    my $s = $cache->open({ mode => 'w' });
    defined( $s ) || do
    {
        diag( "Failed to open shared cache: ", $cache->error ) if( $DEBUG );
    };
    local $SIG{__DIE__} = sub
    {
        diag( "Got error: ", join( '', @_ ), ". Cleaning up shared cache." ) if( $DEBUG );
        $s->unlock;
        $s->remove;
    };
    skip( "Failed to create shared cache object: " . $cache->error, 21 ) if( !defined( $s ) );
    ok( defined( $s ), 'open return value' );

    isa_ok( $s, ['Module::Generic::File::Cache'], 'Shared cache object' );
    my $id = $s->id;
    ok( defined( $id ) && $id =~ /\S+/, "shared cache id is \"$id\"" );
    my $serial = $s->serial;
    ok( defined( $serial ) && $serial =~ /\S+/, "serial is \"$serial\"" );
    my $owner = $s->owner;
    ok( defined( $owner ) && $owner =~ /\S+/, "shared cache owner \"$owner\"" );
    my $test_data = { name => 'John Doe', location => 'Tokyo' };
    my $cache_object = $s->write( $test_data );
    ok( defined( $cache_object ), 'write' );
    ok( overload::StrVal( $s ) eq overload::StrVal( $cache_object ), 'write return value' );
    my $buffer = $s->read;
    ok( defined( $buffer ), 'read no argument' );
    diag( "Error with read: ", $s->error ) if( !defined( $buffer ) );
    ok( ref( $buffer ) eq 'HASH', 'read buffer data integrity' );
    if( ref( $buffer ) eq 'HASH' && $buffer->{name} eq 'John Doe' && $buffer->{location} eq 'Tokyo' )
    {
        pass( 'read data check' );
    }
    else
    {
        fail( 'read data check' );
    }
    
    my $os = lc( $^O );
    if( $os eq 'amigaos' || $os eq 'riscos' || $os eq 'vms' )
    {
        skip( "Your system does not support fork()", 9 );
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
        # Is the child still there?
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
            is( $exit_status, 0, 'sub process shared cache access' );
            my $data = $s->read;
            ok( ref( $data ) eq 'HASH', 'shared updated data type' );
            if( ref( $data ) eq 'HASH' )
            {
                ok( $data->{year} == 2021, 'updated data value' );
            }
            else
            {
                fail( 'updated data value' );
            }
            my $data2;
            $s->read( $data2 );
            ok( ref( $data2 ) eq 'HASH', 'different read usage' );
            if( ref( $data ) eq 'HASH' )
            {
                ok( $data2->{year} == 2021, 'different read data check' );
            }
            else
            {
                fail( 'different read data check' );
            }
            
            my $rv = $s->lock || diag( "Unable to lock: ", $s->error );
            ok( $rv, 'lock' );
            ok( $s->locked, 'locked' );
            if( ref( $data ) eq 'HASH' )
            {
                $data->{test} = 'ok';
                ok( defined( $s->write( $data ) ), 'updated data with lock' );
            }
            else
            {
                fail( 'updated data with lock' );
            }
            ok( defined( $s->unlock ), 'unlock' );
            ok( defined( $s->remove ), 'remove' );
            ok( !$s->exists, 'exists after remove' );
        }
        else
        {
            diag( "Child process with pid '$pid' is already completed." ) if( $DEBUG );
            pass( "sub process exited rapidly" );
        }
    }
    elsif( $pid == 0 )
    {
        my $cache2 = Module::Generic::File::Cache->new(
            debug => $DEBUG,
            create => 0,
            key => 'test_key',
            size => 2048,
            destroy => 0,
            mode => 0666,
        );
        my $c = $cache2->open || do
        {
            diag( "[CHILD] Cannot open: ", $cache2->error ) if( $DEBUG );
            exit(1);
        };
        my $ref = $c->read;
        defined( $ref ) || do
        {
            diag( "[CHILD] read returned undef: ", $c->error ) if( $DEBUG );
            exit(1);
        };
        ref( $ref ) eq 'HASH' || do
        {
            diag( "[CHILD] Shared memory data ($ref) is not an hash reference." ) if( $DEBUG );
            exit(1);
        };
        # $ref = {};
        $ref->{year} = 2021;
        defined( $c->write( $ref ) ) || do
        {
            diag( "Unable to write to shared memory: ", $c->error ) if( $DEBUG );
            exit(1);
        };
        exit(0);
    }
};

done_testing();

__END__

