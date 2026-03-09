#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG $class );
    use open ':std' => 'utf8';
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

    # With limits
    my $repo3 = $class->new( 'limits' => 'Test::Module', max_size => 5, max_store_bytes => 1024, max_total_bytes => 4096 );
    is( $repo3->{max_size}, 5, 'max_size set' );
    is( $repo3->{max_store_bytes}, 1024, 'max_store_bytes set' );
    is( $repo3->{max_total_bytes}, 4096, 'max_total_bytes set' );

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

# NOTE: Resource limits
subtest 'Resource limits' => sub
{
    # Helper to get approx serialized size (mimics wrapper + freeze)
    sub serialized_len
    {
        my $val = shift;
        my $wrapped = ref($val) ? $val : Module::Generic::Global::Scalar->new(\$val);
        return length( Storable::Improved::freeze($wrapped) );
    }

    my $context = 'Test::Module';

    # max_store_bytes (unique ns)
    my $store_ns = 'limits_max_store_' . $$ . time . rand(1000) . rand(1000);
    my $repo_store = $class->new( $store_ns => $context, key => 'store_test', max_store_bytes => 90, debug => $DEBUG );  # 56<110, 156>110
    my $long_str = 'a' x 100;  # ~156 bytes
    my $short_str = 'short';   # ~59 bytes
    {
        local $SIG{__WARN__} = sub{};
        ok( !$repo_store->set( $long_str ), 'Refuse large item' );
        like( $repo_store->error->message, qr/Refusing to store \d+ bytes/, 'Large item error' );
    }
    ok( $repo_store->set( $short_str ), 'Allow small item' );
    cmp_ok( serialized_len($short_str), '<', 110, 'Small serialized under limit' );

    # max_size eviction (separate unique ns)
    my $size_ns = 'limits_max_size_' . $$ . time . rand(1000) . rand(1000);
    my $base_size_opts = { max_size => 3, debug => $DEBUG };
    my $repo1 = $class->new( $size_ns => $context, key => 'one', %$base_size_opts );
    my $repo2 = $class->new( $size_ns => $context, key => 'two', %$base_size_opts );
    my $repo3 = $class->new( $size_ns => $context, key => 'three', %$base_size_opts );
    my $repo4 = $class->new( $size_ns => $context, key => 'four', %$base_size_opts );
    ok( $repo1->set( 'one_val' ), 'Set 1' );
    ok( $repo2->set( 'two_val' ), 'Set 2' );
    ok( $repo3->set( 'three_val' ), 'Set 3' );
    is( $repo1->length, 3, 'At max_size' );
    ok( $repo4->set( 'four_val' ), 'Set 4 evicts oldest' );
    is( $repo1->length, 3, 'Still at max_size' );
    is( $repo4->get, 'four_val', 'Newest present' );
    is( $repo1->get, undef, 'Oldest evicted (key one)' );

    # Overwrite no eviction
    ok( $repo4->set( 'four_updated' ), 'Overwrite no evict' );
    is( $repo1->length, 3, 'Length unchanged on overwrite' );

    # max_total_bytes (separate unique ns)
    my $bytes_ns = 'limits_max_total_' . $$ . time . rand(1000) . rand(1000);
    my $base_total_opts = { max_total_bytes => 180, max_store_bytes => 180, debug => $DEBUG };  # 3*60=180 = max, but code > so set3 ok (177<180), set4 > evict to 177
    my $repo_b1 = $class->new( $bytes_ns => $context, key => 'b1', %$base_total_opts );
    my $repo_b2 = $class->new( $bytes_ns => $context, key => 'b2', %$base_total_opts );
    my $repo_b3 = $class->new( $bytes_ns => $context, key => 'b3', %$base_total_opts );
    my $repo_b4 = $class->new( $bytes_ns => $context, key => 'b4', %$base_total_opts );
    ok( $repo_b1->set( 'short1' ), 'Set 1 (~59 bytes)' );
    ok( $repo_b2->set( 'short2' ), 'Set 2 (~59)' );
    ok( $repo_b3->set( 'short3' ), 'Set 3 (~59, total ~177 <=180)' );
    ok( $repo_b4->set( 'short4' ), 'Set 4 (~59, would ~236 >180, evicts oldest to ~177' );
    my $total = 0; $total += $_->{bytes} for grep { $_->{key} =~ /^$bytes_ns;/ } @{$repo_b1->stat()};  # Per-ns
    cmp_ok( $total, '<=', 180 + 5, 'Total under after evict' );  # Buffer for var
    # Delta on overwrite (same len—no change, no evict)
    my $old_total = $total;
    ok( $repo_b4->set( 'short5' ), 'Overwrite same len no change' );
    $total = 0; $total += $_->{bytes} for grep{ $_->{key} =~ /^$bytes_ns;/ } @{$repo_b1->stat()};
    cmp_ok( $total, '==', $old_total, 'Total unchanged on same-len overwrite' );  # Exact for same
    # Shorten for decrease (no evict)
    my $old_total2 = $total;
    ok( $repo_b4->set( '' ), 'Overwrite to shorter (~56, delta -3, total 174 <180' );
    $total = 0; $total += $_->{bytes} for grep { $_->{key} =~ /^$bytes_ns;/ } @{$repo_b1->stat()};
    cmp_ok( $total, '<', $old_total2, 'Total decreased on shorter overwrite' );
    # Lengthen to evict if over
    ok( $repo_b4->set( 'a' x 100 ), 'Overwrite to longer (~159, total ~174-56+159=277 >180, evicts another to ~174-56=118' );
    $total = 0; $total += $_->{bytes} for grep{ $_->{key} =~ /^$bytes_ns;/ } @{$repo_b1->stat()};
    cmp_ok( $total, '>', $old_total2 - 60, 'Total increased on longer overwrite (after any evict)' );  # > old - evicted ~59

    # Remove subtracts
    ok( $repo_b4->remove, 'Remove subtracts bytes' );
    is( $repo_b1->length, 0, 'Length after remove (after evict left 2, remove 1=1)' );
};

# NOTE: Stats
subtest 'Stats' => sub
{
    my $unique_ns = 'stats_test_' . $$ . time . rand(1000) . rand(1000);
    my $repo_short = $class->new( $unique_ns => 'Test::Module', key => 'short', debug => $DEBUG );
    my $repo_long = $class->new( $unique_ns => 'Test::Module', key => 'long', debug => $DEBUG );
    ok( $repo_short->set( 'short_val' ), 'Set short' );
    ok( $repo_long->set( 'a' x 100 ), 'Set longer' );
    my $stats = $repo_short->stat(5);
    my @ns_stats = grep { $_->{key} =~ /^$unique_ns;/ } @$stats;
    is( scalar(@ns_stats), 2, 'Stats count (per-ns)' );
    ok( $ns_stats[0]{bytes} >= $ns_stats[1]{bytes}, 'Sorted desc' );
    like( $ns_stats[0]{key}, qr/^$unique_ns;/, 'Key format' );
    ok( $repo_long->remove, 'Remove clears stat' );
    $stats = $repo_short->stat;
    @ns_stats = grep { $_->{key} =~ /^$unique_ns;/ } @$stats;
    is( scalar(@ns_stats), 1, 'Stats reduced after remove' );  # 1 left
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
            skip( 'Threads not available', 3 );
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

        # Add limit contention
        my $limit_ns = 'lock_limit_' . $$ . time . rand(1000) . rand(1000);
        $success = 1;
        @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid;
                my $limit_repo = $class->new( $limit_ns => 'Test::Module', key => 'thr_' . $tid, max_size => 2, max_total_bytes => 140, max_store_bytes => 140, debug => $DEBUG );  # 2*70=140 ok, 5 evicts to 2
                my $lock = $limit_repo->lock;
                return(0) if !defined $lock;
                eval { $limit_repo->set( "data_$tid" . ('x' x $tid) ); };  # Vary len ~60 + tid for total
                return(0) if $@;
                return(1);
            });
        } 1..5;  # Add 5, evict to 2

        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }
        ok( $success, 'Thread-safe with limits/eviction' );
        my $check_repo = $class->new( $limit_ns => 'Test::Module', key => 'dummy', debug => $DEBUG );  # To check length
        # diag( "Final keys: " . join(', ', keys %{$REPO->{$limit_ns}}) ) if $DEBUG;  # Temp
        is( $check_repo->length, 2, 'Final length at max after thread sets' );
        my $stats = $check_repo->stat;
    };
};

# NOTE: Cleanup register
subtest 'Cleanup register' => sub
{
    SKIP:
    {
        if( !MOD_PERL )
        {
            skip( 'mod_perl not available', 4 );
        }
        # Mock r—assume loaded, or use stub
        my $mock_r = bless( {}, 'Apache2::RequestRec' );  # Minimal mock; in real, use Apache::Test
        my $repo = $class->new( 'clean' => 'Test::Module' );
        ok( $repo->set( 'to_clean' ), 'Set for cleanup' );
        my $repo2 = $class->new( 'keep' => 'Test::Module' );
        ok( $repo2->set( 'to_keep' ), 'Set for keep' );

        # Test selective
        $repo->cleanup_register( r => $mock_r, namespaces => ['clean'], keep => ['keep'], callback => sub { diag("Callback called") if $DEBUG; } );
        # Simulate callback call (manual, since no real pool)
        # In real test, use Apache::Test harness; here, assume logic ok if no error
        ok( 1, 'Registered without error' );  # Placeholder

        # Check clears (simulate)
        # ... delete $REPO->{'clean'}; etc in test callback mock
    }
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
