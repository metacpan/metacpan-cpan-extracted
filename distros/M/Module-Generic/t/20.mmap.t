#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $SERIALISER );
    use Errno;
    use Nice::Try;
    use Test2::IPC;
    use Test2::V0;
    use POSIX ":sys_wait_h";
    use Module::Generic::File::Mmap;
    $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $SERIALISER = exists( $ENV{SERIALISER} ) ? $ENV{SERIALISER} : 'storable';
};

use strict;
use warnings;

eval "use Cache::FastMmap 1.57;";
plan( skip_all => "Cache::FastMmap 1.57 required for testing mmap with Cache::FastMmap" ) if( $@ );

SKIP:
{
    use strict;
    use warnings;

    my $cache = Module::Generic::File::Mmap->new(
        debug => $DEBUG,
        key => 'test_key',
        serialiser => $SERIALISER,
        size => 2048,
        # destroy => 1,
        destroy => 0,
        mode => 0666,
    );

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

    skip( "Failed to create shared cache object: " . Module::Generic::File::Mmap->error, 21 ) if( !defined( $s ) );
    isa_ok( $s => ['Module::Generic::File::Mmap'] );

    isa_ok( $s, ['Module::Generic::File::Mmap'], 'Shared cache object' );
    my $test_data = { name => 'John Doe', location => 'Tokyo' };
    my $cache_object = $s->write( $test_data );
    ok( defined( $cache_object ), 'write' );
    ok( overload::StrVal( $s ) eq overload::StrVal( $cache_object ), 'write return value' );
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
    
    my $os = lc( $^O );
    if( $os eq 'amigaos' || $os eq 'riscos' || $os eq 'vms' )
    {
        skip( "Your system does not support fork()", 1 );
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
                ok( ( exists( $data->{year} ) && defined( $data->{year} ) && int( $data->{year} ) == 2021 ), 'updated data value' );
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
                ok( ( exists( $data2->{year} ) && defined( $data2->{year} ) && int( $data2->{year} ) == 2021 ), 'different read data check' );
            }
            else
            {
                fail( 'different read data check' );
            }
            
            # lock is actually a noop
            my $rv = $s->lock || diag( "Unable to lock: ", $s->error );
            ok( $rv, 'lock' );
            # locked is actually a noop too
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
            # unlock is actually a noop too
            ok( defined( $s->unlock ), 'unlock' );
            ok( defined( $s->remove ), 'remove' );
            # ok( !$s->exists, 'exists after remove' );
        }
        else
        {
            diag( "Child process with pid '$pid' is already completed." ) if( $DEBUG );
            pass( "sub process exited rapidly" );
        }
    }
    elsif( $pid == 0 )
    {
        my $cache2 = Module::Generic::File::Mmap->new(
            debug => $DEBUG,
            key => 'test_key',
            serialiser => $SERIALISER,
            mode => 0666,
        );
        my $c = $cache2->open || do
        {
            diag( "[CHILD] cannot open: ", $cache2->error ) if( $DEBUG );
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
            diag( "[CHILD] Unable to write to shared memory: ", $c->error ) if( $DEBUG );
            exit(1);
        };
        exit(0);
    }
};

subtest 'serialisation with cbor' => sub
{
    SKIP:
    {
        eval "use CBOR::XS 1.86;";
        skip( "CBOR::XS 1.86 required for testing serialisation with CBOR", 1 ) if( $@ );
        my $cbor = CBOR::XS->new->allow_sharing;
        my $cache = Module::Generic::File::Mmap->new(
            debug => $DEBUG,
            key => 'test_key',
            serialiser => $SERIALISER,
            size => 2048,
            # destroy => 1,
            destroy => 0,
            mode => 0666,
        ) || die( Module::Generic::File::Mmap->error );
        my $s = $cache->open({ mode => 'w' });
        diag( "Error opening mmap cache file: ", $cache->error ) if( $DEBUG && !defined( $s ) );
        ok( $s, 'mmap cache opened' );
        skip( "Failed to instantiate a mmap object.", 6 ) if( !defined( $s ) );
        ok( $s->write({ name => 'John Doe', location => 'Tokyo' }), 'write to cache mmap' );
        try
        {
            my $serial = $cbor->encode( $s );
            ok( ( defined( $serial ) && length( $serial ) ), 'object serialised' );
            my $obj = $cbor->decode( $serial );
            isa_ok( $obj => ['Module::Generic::File::Mmap'], 'deserialised object is an Module::Generic::File::Mmap object' );
            ok( $s->cache_file eq $obj->cache_file, 'cache mmap file is the same' );
            is( $s->cache_file->length, $obj->cache_file->length, 'cache mmap file has same size as before' );
            my $h = $obj->read;
            is( $h->{name}, 'John Doe', 'stored data matches' );
        }
        catch( $e )
        {
            fail( "Error serialising or deserialising: $e" );
        }
    };
};

subtest 'serialisation with sereal' => sub
{
    SKIP:
    {
        eval "use Sereal 4.023;";
        skip( "Sereal 4.023 required for testing serialisation with Sereal", 1 ) if( $@ );
        my $enc = Sereal::Encoder->new({ freeze_callbacks => 1 });
        my $dec = Sereal::Decoder->new;
        my $cache = Module::Generic::File::Mmap->new(
            debug => $DEBUG,
            key => 'test_key',
            serialiser => $SERIALISER,
            size => 2048,
            # destroy => 1,
            destroy => 0,
            mode => 0666,
        ) || die( Module::Generic::File::Mmap->error );
        my $s = $cache->open({ mode => 'w' });
        ok( $s->write({ name => 'John Doe', location => 'Tokyo' }), 'write to cache mmap' );
        try
        {
            my $serial = $enc->encode( $s );
            ok( ( defined( $serial ) && length( $serial ) ), 'object serialised' );
            my $obj = $dec->decode( $serial );
            isa_ok( $obj => ['Module::Generic::File::Mmap'], 'deserialised object is an Module::Generic::File::Mmap object' );
            ok( $s->cache_file eq $obj->cache_file, 'cache mmap file is the same' );
            is( $s->cache_file->length, $obj->cache_file->length, 'cache mmap file has same size as before' );
            my $h = $obj->read;
            is( $h->{name}, 'John Doe', 'stored data matches' );
        }
        catch( $e )
        {
            fail( "Error serialising or deserialising: $e" );
        }
    };
};

subtest 'serialisation with storable' => sub
{
    SKIP:
    {
        eval "use Storable::Improved v0.1.3;";
        skip( "Storable::Improved v0.1.3 required for testing serialisation with Storable", 1 ) if( $@ );
        my $cache = Module::Generic::File::Mmap->new(
            debug => $DEBUG,
            key => 'test_key',
            serialiser => $SERIALISER,
            size => 2048,
            # destroy => 1,
            destroy => 0,
            mode => 0666,
        ) || die( Module::Generic::File::Mmap->error );
        my $s = $cache->open({ mode => 'w' });
        ok( $s->write({ name => 'John Doe', location => 'Tokyo' }), 'write to cache mmap' );
        try
        {
            my $serial = Storable::Improved::freeze( $s );
            ok( ( defined( $serial ) && length( $serial ) ), 'object serialised' );
            my $obj = Storable::Improved::thaw( $serial );
            isa_ok( $obj => ['Module::Generic::File::Mmap'], 'deserialised object is an Module::Generic::File::Mmap object' );
            ok( $s->cache_file eq $obj->cache_file, 'cache mmap file is the same' );
            is( $s->cache_file->length, $obj->cache_file->length, 'cache mmap file has same size as before' );
            my $h = $obj->read;
            is( $h->{name}, 'John Doe', 'stored data matches' );
        }
        catch( $e )
        {
            fail( "Error serialising or deserialising: $e" );
        }
    };
};

done_testing();

__END__

