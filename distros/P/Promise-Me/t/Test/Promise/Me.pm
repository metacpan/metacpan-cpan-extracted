package Test::Promise::Me;
use strict;
use warnings;
use vars qw( $DEBUG $DESTROY_SHARED_MEM );
# use Test2::IPC;
use Test2::V0;
use Module::Generic::File qw( file tempfile sys_tmpdir );
use Scalar::Util ();
use Promise::Me qw( :all );
use Time::HiRes;
our $DESTROY_SHARED_MEM = 0;

# Credits:
# <https://stackoverflow.com/questions/6855796/what-else-can-i-do-sleep-when-the-sleep-cant-work-well-with-alarm>
sub sleep_tight
{
    my $end = Time::HiRes::time() + shift( @_ );
    for(;;)
    {
        my $delta = $end - Time::HiRes::time();
        last if( $delta <= 0 );
        select( undef, undef, undef, $delta );
    }
}

sub runtest
{
    my( $medium, $serialiser ) = @_;
    local $Promise::Me::SERIALISER = $serialiser;
    local $Promise::Me::SHARE_MEDIUM = $medium;
    my $pid = $$;
    diag( "[$medium] -> [$serialiser]: Main pid is '$pid'" ) if( $DEBUG );
    my $prom = Promise::Me->new(sub
    {
        my( $resolve, $reject ) = @$_;
        is( ref( $resolve ), 'CODE', 'resolve available in $_' );
        is( ref( $reject ), 'CODE', 'reject available in $_' );
        my $str = 'Test 1';
        diag( "[$medium] -> [$serialiser], [pid = $$] $str" ) if( $DEBUG );
        pass( 'child sub' );
        ok( $$ != $pid, 'code executed in sub process' );
        return( $str );
    }, { debug => $DEBUG, serialiser => $serialiser });
    isa_ok( $prom, ['Promise::Me'], 'promise object' );

    ok( !$prom->is_child, 'main process' );

    $prom->then(sub
    {
        my $val = shift( @_ );
        is( $val, 'Test 1', 'then' );
        diag( "[$medium] -> [$serialiser]: My pid is '$$'" ) if( $DEBUG );
        ok( $$ != $pid, 'then() executed in sub process' );
    });

    Promise::Me->new(sub
    {
        diag( "[$medium] -> [$serialiser]: Dying on purpose..." ) if( $DEBUG );
        die( "Oh my!\n" );
    }, {
        share_auto_destroy => $DESTROY_SHARED_MEM,
        use_cache_file => 1,
        serialiser => $serialiser
    })->then(sub
    {
        diag( "[$medium] -> [$serialiser]: Got here, but should not" ) if( $DEBUG );
        fail( 'should not catch error' );
    })->catch(sub
    {
        like( $_[0], qr/\bOh\s+my\b/, 'catch error' );
    });

    subtest 'concurrency' => sub
    {
        my $tmpdir = sys_tmpdir();
        my $tmpfile = $tmpdir->child( 'module_generic_promise_test.txt' );
        my $f = $tmpfile;
        $f->empty;
        $f->close;
        diag( "[$medium] -> [$serialiser]: CONCURRENCY 1 with parent pid '$$'" ) if( $DEBUG );
        my $result : shared = '';
        my( $truc, %bidule, @chouette );
        $truc = 'Jean';
        %bidule = ( name => 'John', location => 'Paris' );
        @chouette = qw( Pierre Paul Jacques );
        share( $truc, %bidule, @chouette );
        my $p1 = Promise::Me->new(sub
        {
            print( STDERR "Concurrent promise 1 ($$), sleeping.\n" ) if( $DEBUG );
            diag( "Is \$result tied ? ", tied( $result ) ? 'Yes' : 'No', ". Value is -> '$result'" ) if( $DEBUG );
            # sleep(3);
            sleep_tight(3);
            $result .= "concurrency 1\n";
            my $file = $tmpfile->clone;
            diag( "Writing 'concurrency 1' to file $tmpfile and my pid is '$$' vs parent '$pid'" ) if( $DEBUG );
            $file->append( "concurrency 1\n" ) || do
            {
                warn( "Error appending to file $file: ", $file->error, "\n" );
            };
            return( $file );
        }, { debug => $DEBUG, serialiser => $serialiser })->then(sub
        {
            diag( "[$medium] -> [$serialiser], [P1] Parameter received is '", overload::StrVal( $_[0] ), "'" ) if( $DEBUG );
            isa_ok( $_[0], ['Module::Generic::File'], "[P1] PID $$: Value passed to then is an object file" );
        })->catch(sub
        {
            fail( 'concurrency test 1 with error: ' . $_[0] );
        });
    #     })->wait;

        diag( "[$medium] -> [$serialiser], CONCURRENCY 2 with parent pid '$$'" ) if( $DEBUG );
        my $p2 = Promise::Me->new(sub
        {
            print( STDERR "Concurrent promise 2 ($$), sleeping.\n" ) if( $DEBUG );
            # sleep(0.5);
            sleep_tight(0.5);
            $result .= "concurrency 2\n";
            my $file = file( $tmpfile );
            diag( "[$medium] -> [$serialiser]: Appending 'concurrency 2' to $tmpfile and my pid is '$$' vs parent '$pid'" ) if( $DEBUG );
            $file->append( "concurrency 2\n" ) || do
            {
                warn( "Error appending to file $file: ", $file->error, "\n" );
            };
            return( $file );
        }, { debug => $DEBUG, timeout => 2, serialiser => $serialiser })->then(sub
        {
            diag( "[$medium] -> [$serialiser], [P2] Parameter received is '", overload::StrVal( $_[0] ), "'" ) if( $DEBUG );
            diag( "[$medium] -> [$serialiser]: ", overload::StrVal( $_[0] ), " is not a blessed object." ) if( !defined( $_[0] ) || !Scalar::Util::blessed( $_[0] ) );
            isa_ok( $_[0], ['Module::Generic::File'], "[P2] PID $$: Value passed to then #1 is an object file" );
            $_[0];
        })->then(sub
        {
            isa_ok( $_[0], ['Module::Generic::File'], "[P2] PID $$: Value passed to then #2 is an object file" );
        })->catch(sub
        {
            fail( 'concurrency test 2 with error: ' . $_[0] );
        });
        #})->wait;

        diag( "[$medium] -> [$serialiser]: Awaiting promise 1 and 2" ) if( $DEBUG );
        my @res = await( $p1, $p2 );
        diag( "[$medium] -> [$serialiser]: Result now is '$result'" ) if( $DEBUG );
        diag( "[$medium] -> [$serialiser]: await() retuned the following values '", join( "', '", map( ( ref( $_ ) eq 'ARRAY' ? @$_ : $_ ), @res ) ), "'." ) if( $DEBUG );
        is( $result, "concurrency 2\nconcurrency 1\n", 'concurrency' );

        $f = file( $tmpfile );
        my $lines = $f->lines;
        diag( "[$medium] -> [$serialiser]: ", $lines->length, " lines found in $tmpfile -> ", $lines->join( '' )->scalar ) if( $DEBUG );
        is( $lines->join( '' )->scalar, "concurrency 2\nconcurrency 1\n", 'concurrency check' );
        $f->empty;
    };
}

1;

__END__

