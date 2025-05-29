#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG $class );
    $class = 'Module::Generic::Global';
    use Config;
    use Test::More;
    use Module::Generic;
    use Scalar::Util qw( refaddr );
    eval
    {
        require Module::Generic::Global;
        $class->import( ':const' );
    };
    if( $@ )
    {
        BAIL_OUT( "Unable to load $class: $@" );
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
}

use strict;
use warnings;
use utf8;

# my $class = 'Module::Generic::Global';
# use_ok( $class, ':const' ) || BAIL_OUT( "Unable to load $class" );

# NOTE: Constructor
subtest 'Constructor' => sub
{
    # Class-level
    my $repo = $class->new( 'test_ns' => 'Test::Module' );
    isa_ok( $repo, $class, 'Class-level constructor' );
    is( $repo->{_mode}, 'class', 'Class-level mode' );
    like( $repo->{_key}, qr/^Test::Module;\d+$/, 'Class-level key format' );

    # Object-level
    my $obj = bless( {}, 'Test::Module' );
    my $repo2 = $class->new( 'test_ns' => $obj );
    isa_ok( $repo2, $class, 'Object-level constructor' );
    is( $repo2->{_mode}, 'object', 'Object-level mode' );
    my $tid = HAS_THREADS ? threads->tid : '';
    like( $repo2->{_key}, qr/^\d+;\d+;?$tid$/, 'Object-level key format' );
    is( $repo2->{_class_key}, join( ';', 'Test::Module', $$ ), 'Object-level class key' );

    # Invalid inputs
    {
        no warnings;
        local $SIG{__DIE__} = sub{};
        my $bad = $class->new;
        ok( !defined( $bad ), 'No namespace fails' );
        is( $class->error->message, 'No namespace was provided.', 'No namespace error' );

        $bad = $class->new( 'test_ns' => [] );
        ok( !defined( $bad ), 'Invalid context fails' );
        is( $class->error->message, 'Module::Generic::Global->new requires either a class name or an object to be provided.', 'Invalid context error' );
    }
};

# NOTE: Data operations
subtest 'Data operations' => sub
{
    my $repo = $class->new( 'data' => 'Test::Module' );

    # Set/get scalar
    ok( $repo->set( 'hello' ), 'Set scalar' );
    is( $repo->get, 'hello', 'Get scalar' );
    ok( $repo->exists, 'Exists after set' );

    # Set/get reference
    my $data = { foo => 42, bar => [1, 2, 3] };
    ok( $repo->set( $data ), 'Set reference' );
    is_deeply( $repo->get, $data, 'Get reference' );

    # Set/get object
    my $obj = Module::Generic->new( debug => 42 );
    ok( $repo->set( $obj ), 'Set object' );
    my $got = $repo->get;
    isa_ok( $got, 'Module::Generic', 'Get object' );
    # This does not work because the object is frozen and thawed, and thus not the exact same one.
    # is( refaddr( $got ), refaddr( $obj ), 'Same object instance' );
    is( $got->{debug}, $obj->{debug}, 'Same object instance' );

    # Remove
    ok( $repo->remove, 'Remove value' );
    ok( !$repo->exists, 'Not exists after remove' );
    is( $repo->get, undef, 'Get undef after remove' );

    # Clear alias
    ok( $repo->set( 'test' ), 'Set for clear' );
    ok( $repo->clear, 'Clear value' );
    ok( !$repo->exists, 'Not exists after clear' );
};

# NOTE: Error handling
subtest 'Error handling' => sub
{
    my $repo = $class->new( 'errors' => 'Test::Module' );

    # Set error
    {
        no warnings;
        $repo->error( "Test error ", "occurred" );
        my $err = $repo->error;
        isa_ok( $err, 'Module::Generic::Global::Exception', 'Error object' );
        is( $err->message, 'Test error occurred', 'Error message' );
        is( $err->code, 500, 'Error code' );
    }

    # Clear error
    $repo->clear_error;
    is( $repo->error, undef, 'No error after clear' );
};

# NOTE: Locking
subtest 'Locking' => sub
{
    my $repo = $class->new( 'lock' => 'Test::Module' );

    # Non-threaded lock
    {
        my $lock = $repo->lock;
        ok( defined( $lock ), 'Lock acquired in non-threaded env' );
        ok( $repo->set( 'locked' ), 'Set during lock' );
        is( $repo->get, 'locked', 'Get during lock' );
    } # Lock released
    is( $repo->get, 'locked', 'Data persists after lock release' );

    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        require threads::shared;

        my $repo2 = $class->new( 'lock' => 'Test::Module' );
        my $success = 1;
        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid;
                my $lock = $repo2->lock;
                if( !defined( $lock ) )
                {
                    diag( "Thread $tid: Failed to acquire lock" ) if( $DEBUG );
                    return(0);
                }
                local $@;
                eval
                {
                    $repo2->set( "thread_$tid" );
                    my $val = $repo2->get;
                    if( $val ne "thread_$tid" )
                    {
                        diag( "Thread $tid: Got wrong value: $val" ) if( $DEBUG );
                        return(0);
                    }
                };
                if( $@ )
                {
                    diag( "Thread $tid: Error during locked operation: $@" ) if( $DEBUG );
                    return(0);
                }
                return(1);
            });
        } 1..3;

        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }

        ok( $success, 'Thread-safe locking' );
    };
};

# NOTE: Context isolation
subtest 'Context isolation' => sub
{
    my $repo1 = $class->new( 'shared' => 'Test::Module' );
    my $obj = bless( {}, 'Test::Module' );
    my $repo2 = $class->new( 'shared' => $obj );

    ok( $repo1->set( 'class_data' ), 'Set class-level data' );
    ok( $repo2->set( 'object_data' ), 'Set object-level data' );

    is( $repo1->get, 'class_data', 'Class-level isolation' );
    is( $repo2->get, 'object_data', 'Object-level isolation' );

    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        my $repo3 = $class->new( 'shared' => $obj );
        my $thr = threads->create(sub
        {
            my $tid = threads->tid;
            $repo3->set( "thread_$tid" );
            return( $repo3->get );
        });
        my $thread_data = $thr->join;
        like( $thread_data, qr/^thread_\d+$/, 'Child thread sets data' );
        like( $repo2->get, qr/^thread_\d+$/, 'Main thread sees child thread data (same key)' );

        # Test 2: Repository created in child thread for isolation
        my $thr2 = threads->create(sub
        {
            my $tid = threads->tid;
            # Create new repository in child thread
            my $repo4 = $class->new( 'shared' => $obj );
            $repo4->set( "isolated_$tid" );
            return( $repo4->get );
        });
        my $isolated_data = $thr2->join;
        like( $isolated_data, qr/^isolated_\d+$/, 'Child thread sets isolated data' );
        unlike( $repo2->get, qr/^isolated_\d+$/, 'Main thread data unchanged by child thread (different key)' );
    };
};

# NOTE: System context sharing
subtest 'System context sharing' => sub
{
    my $mod1 = Test::Global::Module->new;
    my $mod2 = Test::Global::Other->new;
    my $value = { test => "system_context_$$" . ( HAS_THREADS ? threads->tid : '' ) };
    ok( $mod1->set( $value ), 'Test::Global::Module set value' );
    my $retrieved = $mod2->get;
    is_deeply( $retrieved, $value, 'Test::Global::Other retrieved value' );
    my $repo = Module::Generic::Global->new( global_settings => 'system', debug => $DEBUG );
    ok( $repo->remove, 'Remove system context value' );
    is( $repo->get, undef, 'System context value removed' );
};

# NOTE: System context thread-safety
subtest 'System context thread-safety' => sub
{
    SKIP:
    {
        if( !HAS_THREADS )
        {
            skip( 'Threads not available', 3 );
        }
        require threads;
        my $value = { test => "threaded_system_$$" };
        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $mod = Test::Global::Module->new;
                diag( "Thread $tid setting value" ) if( $DEBUG );
                my $rv = $mod->set( $value );
                if( !defined( $rv ) )
                {
                    diag( "Thread $tid failed to set: ", $mod->error ) if( $DEBUG );
                    return(0);
                }
                my $retrieved = $mod->get;
                if( !is_deeply( $retrieved, $value, "Thread $tid retrieved value" ) )
                {
                    diag( "Thread $tid retrieved incorrect value: ", explain( $retrieved ) ) if( $DEBUG );
                    return(0);
                }
                return(1);
            });
        } 1..5;
        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join;
        }
        ok( $success, 'All threads set and retrieved value successfully' );
        my $mod2 = Test::Global::Other->new;
        my $retrieved = $mod2->get;
        is_deeply( $retrieved, $value, 'Test::Global::Other retrieved value post-threads' );
        my $repo = Module::Generic::Global->new( global_settings => 'system', debug => $DEBUG );
        ok( $repo->remove, 'Remove system context value after threads' );
    };
};

done_testing();

{
    # Need to put the 'package' word and the class name 'Test::Global::Module' on separate lines to hide it from MetaCPAN.
    package
        Test::Global::Module;
    use parent -norequire, qw( Test::Global::Common );
    use strict;
    use warnings;
}

{
    package
        Test::Global::Other;
    use parent -norequire, qw( Test::Global::Common );
    use strict;
}

{
    package
        Test::Global::Common;
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use Module::Generic::Global;
    our $DEBUG = $main::DEBUG;

    sub new { return( bless( {}, ( ref( $_[0] ) || $_[0] ) ) ); }

    sub set
    {
        my $self = shift( @_ );
        $self->{val} = shift( @_ );
        my $repo = Module::Generic::Global->new( global_settings => 'system', debug => $DEBUG ) ||
            die( Module::Generic::Global->error );
        my $rv = $repo->set( $self->{val} );
        return( $self->error( "Failed to set value: " . $repo->error ) ) if( !defined( $rv ) );
        return( $self->{val} );
    }

    sub get
    {
        my $self = shift( @_ );
        my $repo = Module::Generic::Global->new( global_settings => 'system', debug => $DEBUG ) ||
            die( Module::Generic::Global->error );
        my $val = $repo->get;
        return( $val ) if( defined( $val ) );
        return( $self->{val} );
    }
}

__END__
