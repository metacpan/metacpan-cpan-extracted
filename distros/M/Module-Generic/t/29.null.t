#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Config;
    use Test::More;
    use Wanted;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
}

use strict;
use warnings;
use utf8;

my $class = 'Module::Generic::Null';
use_ok( $class ) || BAIL_OUT( "Unable to load $class" );

subtest 'Basic functionality' => sub
{
    my $error = bless( { message => "Test error" }, 'Module::Generic::Exception' );
    # my $null = $class->new( wants => 'OBJECT' );
    my $null = $class->new;
    isa_ok( $null, $class, 'Object creation' );
    # is( $null->has_error->message, "Test error", 'has_error stores error object' );

    # Object context (chaining)
    my $chained = $null->fake->method->chain;
    is( $chained, undef, 'Chaining ultimately returns undef' );

    # Stringification
    {
        no warnings;
        is( "$null", '', 'Stringification returns empty string' );
    }

    # Boolean context
    ok( !$null, 'Boolean context returns false' );

    # Equality comparison
    ok( $null eq '', 'eq empty string' );
    ok( $null ne 'value', 'ne non-empty string' );
    my $other_null = $class->new;
    ok( $null ne $other_null, 'ne another null object' );
};

subtest 'Context handling' => sub
{
    my $null = $class->new;

    my $contextise = sub
    {
        my $expect = shift( @_ );
        local $@;
        if( $expect eq 'object' )
        {
            eval
            {
                $null->fake_method->other_method;
            };
            if( $@ )
            {
                diag( "Error calling null object in object context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'hash' )
        {
            eval
            {
                my $rv = $null->fake_method->{dummy};
            };
            if( $@ )
            {
                diag( "Error calling null object in hash context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'array' )
        {
            eval
            {
                my $rv = $null->fake_method->[0];
            };
            if( $@ )
            {
                diag( "Error calling null object in array context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'code' )
        {
            eval
            {
                my $rv = $null->fake_method->();
            };
            if( $@ )
            {
                diag( "Error calling null object in code context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'glob' )
        {
            eval
            {
                print( $null->fake_method, '' );
            };
            if( $@ )
            {
                diag( "Error calling null object in glob context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'scalar ref' )
        {
            eval
            {
                my $val = ${$null->fake_method};
            };
            if( $@ )
            {
                diag( "Error calling null object in scalar ref context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'boolean' )
        {
            eval
            {
                my $bool = !!$null->fake_method;
            };
            if( $@ )
            {
                diag( "Error calling null object in boolean context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'scalar' )
        {
            eval
            {
                my $val = $null->fake_method;
            };
            if( $@ )
            {
                diag( "Error calling null object in scalar context: $@" );
                return(0);
            }
            return(1);
        }
        elsif( $expect eq 'list' )
        {
            eval
            {
                my @val = $null->fake_method;
            };
            if( $@ )
            {
                diag( "Error calling null object in list context: $@" );
                return(0);
            }
            return(1);
        }
        else
        {
            diag( "Unknown context." );
            return(0);
        }
    };

    ok( $contextise->( 'scalar' ), 'context set to scalar' );
    ok( $contextise->( 'object' ), 'context set to object' );
    ok( $contextise->( 'code' ), 'context set to code' );
    ok( $contextise->( 'hash' ), 'context set to hash' );
    ok( $contextise->( 'array' ), 'context set to array' );
    ok( $contextise->( 'glob' ), 'context set to glob' );
    ok( $contextise->( 'scalar ref' ), 'context set to scalar ref' );
    ok( $contextise->( 'boolean' ), 'context set to boolean' );
    ok( $contextise->( 'list' ), 'context set to list' );

};

subtest 'Context with wants option' => sub
{
    my $null = $class->new( wants => 'ARRAY' );
    my $array_ref = $null->fake;
    is( ref( $array_ref ), 'ARRAY', 'Wants ARRAY returns array ref' );

    $null = $class->new( wants => 'HASH' );
    my $hash_ref = $null->fake;
    is( ref( $hash_ref ), 'HASH', 'Wants HASH returns hash ref' );

    $null = $class->new( wants => 'CODE' );
    my $code_ref = $null->fake;
    is( ref( $code_ref ), 'CODE', 'Wants CODE returns code ref' );

    $null = $class->new( wants => 'REFSCALAR' );
    my $scalar_ref = $null->fake;
    is( ref( $scalar_ref ), 'SCALAR', 'Wants REFSCALAR returns scalar ref' );

    $null = $class->new( wants => 'SCALAR' );
    my $scalar = $null->fake;
    is( $scalar, undef, 'Wants SCALAR returns undef' );

    $null = $class->new( wants => 'LIST' );
    my @list = $null->fake;
    is_deeply( \@list, [], 'Wants LIST returns empty list' );
};

subtest 'Thread-safe operations' => sub
{
    no warnings 'once';
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        require threads::shared;

        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $null = Module::Generic::Null->new( wants => 'OBJECT' );
                my $chained = $null->fake->method->chain;
                if( !defined( $chained ) || ref( $chained ) ne 'Module::Generic::Null' )
                {
                    diag( "Thread $tid: Chaining failed: ", $chained ) if( $DEBUG );
                    return(0);
                }
                local $@;
                eval{ my $dummy = $null->array->dummy };
                if( $@ )
                {
                    diag( "Thread $tid: Array context failed: ", $@ ) if( $DEBUG );
                    return(0);
                }
                return(1);
            });
        } 1..5;

        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }

        ok( $success, 'All threads handled null object successfully' );
    };
};

done_testing();

__END__
