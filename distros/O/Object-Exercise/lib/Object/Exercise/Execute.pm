#######################################################################
# housekeeping
#######################################################################

package Object::Exercise::Execute;
use v5.20;
no warnings;

use Carp;

use List::Util      qw( first                       );
use Scalar::Util    qw( reftype                     );
use Time::HiRes     qw( gettimeofday tv_interval    );
use YAML::XS        qw( Load                        );

use Test::More;

########################################################################
# package variables
########################################################################

our @CARP_NOT   = ( __PACKAGE__ );

our $VERSION    = '3.02';
$VERSION        = eval "$VERSION";

my @defaultz =
qw
(
    benchmark   0
    break       0
    regex       0

    debug       0
    verbose     0


    continue    1
    finish      1

    export      exercise
);

my %globalz     = @defaultz;

########################################################################
# local utility subs
########################################################################

########################################################################
# deal with flag settings

sub extract_flags
{
    my %flagz   = ();
    my $count   = 0;
    my $found   = 0;

    for( @_ )
    {
        ref $_
        and last;

        ++$count;

        my ( $negate, $name, $value )
        = m{ (no)? (\w+) (?:=)?( .+ )? }x;

        exists $globalz{ $name }
        or do
        {
            note "$_";
            next
        };

        ++$found;

        $flagz{ $name } 
        = $negate
        ? ! ( $value // 1 )
        :   ( $value // 1 )
        ;
    }

    $count
    or return;

    splice @_, 0, $count;

    note "Extracted flags:\n", explain \%flagz
    if $found;

    wantarray
    ?  %flagz
    : \%flagz
}

sub import_flags
{
    %globalz    = ( @defaultz, &extract_flags );

    # hand back the name to export.
    # remainder are left in the global settings.

    delete $globalz{ export }
}

########################################################################
# execute individual tests

my $execute
= sub
{
    # note the lack of pass/fail: all this will do is report errors.
    # any pass/fail handling is dealt with in test_result.

    state $r    = [];
    state $t0   = '';
    state $t1   = '';

    my ( $obj, $test ) = @_;

    my ( $method, @argz ) = @$test;

    # assume that "$return =" is not significant in the benchmark.
    # also assume that nothing in gettimeofday will set $@.

    @$r = ();

    eval 
    {
        $DB::single = 1 if $globalz{ break };

        $t0 = [ gettimeofday ];
        @$r = $obj->$method( @argz );
        $t1 = [ gettimeofday ];
    };
    chomp( my $error = $@ );

    if( $globalz{ benchmark } )
    {
        state $format   = "Benchmark: %0.6f sec\t%s( %s )";

        my $wall        = tv_interval $t0, $t1;

        diag sprintf $format => $wall, $method, explain @argz;
    }

    if( $error )
    {
        note "Error: '$method'\n", explain $error;
    }
    elsif( $globalz{ verbose } )
    {
        note "Clean: '$method'\n", explain $r;
    }

    if( $error && $globalz{ debug } )
    {
        $DB::single = 1;
        0
    }

    ( $error, $r )
};

my $test_result
= sub
{
    my ( $obj, $test, $expect, $message ) = @_;

    my $method  = $test->[0];

    my ( $error, $found ) = $obj->$execute( $test );

    $message    ||= "$method";
    $message    .= " ($error)"
    if $error;

    for my $type ( reftype $expect )
    {
        if( 'CODE' eq $type )
        {
            ok $expect->( $test, $found, $error ), $message;
        }
        elsif( $expect )
        {
            # this may pass if expect is [ undef ] but will
            # report the error text either way.

            if
            (
                ! $type
                and
                $globalz{ regex }
            )
            {
                like    "@$found", qr{$expect}x, $message;
            }
            elsif( 'REGEXP' eq $type )
            {
                like        "@$found", $expect, $message; 
            }
            elsif( 'ARRAY' eq $type )
            {
                is_deeply  $found, $expect, $message; 
            }
            else
            {
                BAIL_OUT
                "Invalid expect: '$type'\n" .  
                explain(  $expect, $found, $message );
            }
        }
        elsif( $error )
        {
            # explicit undef expects an error.
            # zero the string here to avoid rejecting the test
            # in the caller.

            pass "Expected error: '$error'";

            $error  = '';
        }
        else
        {
            # expected error was not returned, this is a failure.

            fail "Unexpected success: '$method' (no error)";
            diag "Return value:\n", explain $found;
        }
    }

    # mainly useful as a boolean value in the caller.

    $error
};

my $process
= sub
{
    my $obj = shift;

    # flattened out test entry is left on the stack.
    # extract any local flags (e.g., verbose for one
    # test only).

    my $localz  = &extract_flags;

    # trailing flags left nothing further to process.

    if( @_ )
    {
        # sane
    }
    else
    {
        diag "Bogus test: contains only local flags\n", explain $localz;
        return
    }

    local @globalz{ keys %$localz } = values %$localz
    if $localz;

    # if there is no expect value then skip the ok check and just
    # run the method.

    my $handler
    = @_> 1
    ? $test_result
    : $execute
    ;

    my $error = $obj->$handler( @_ )
    or return;

    $globalz{ continue }
    or
    die "Error during processing (continue turned off)\n" .
    explain $error;

    return
};

########################################################################
# break up contents of exercise.

sub validate_plan
{
    # entrys are anything that gets run, expects have an 
    # tests value and issue a pass/fail for the test.

    my $entrys  = 0;
    my $tests   = 0;

    for my $fieldz ( @_ )
    {
        ref $fieldz or next;

        my $n   = $#$fieldz;

        my $i   = first { ref $fieldz->[$_] } ( 0 .. $n )
        // next;

        ++$entrys;

        $n > $i     # i.e.,  exists $entry->[ 1 + $i ]
        or next;

        ++$tests;
    }

    $entrys
    or
    BAIL_OUT 'Bogus exercise: no executable entry', explain \@_;

    note "Executing: $entrys entrys ($tests with tests)"
    if $globalz{ verbose };

    return
}

sub prepare_tests
{
    @_ or croak 'Bogus exercise: no tests on the stack';

    if
    (
        1 == @_
        and
        ! ref $_[0]
    )
    {
        if
        (
            'finish'    eq $_[0]
            or 
            'nofinish'  eq $_[0]
        )
        {
            %globalz    = ( %globalz, &extract_flags );
            return
        }
        else 
        {
            # anything else useful requires multiple 
            # entries at this point: the input is YAML.

            my $yaml    = shift;

            note "Non-ref test: assume YAML\n$yaml", 

            my $struct = eval { Load $yaml };

            BAIL_OUT "Invalid YAML: $@"
            if $@;

            @$struct 
            or  BAIL_OUT "Invalid YAML: empty content\n", $yaml;

            @_  = @$struct;
        }
    }
    
    # extract any flags floating at the start and 
    # leave the tests in place.

    %globalz    = ( %globalz, &extract_flags );

    # @_ will be empty at this point if there were only flags.

    if( @_ )
    {
        # there is a plan on the stack

        &validate_plan
    }
    elsif( $globalz{ finish } )
    {
        croak
        "Bogus plan: no tests and finish is true (missing 'nofinish'?)";
    }
    else
    {
        # no plan, no finish => fine.
    }

    # at this point the first 'test' is at the head of the stack.

    return
}


########################################################################
# interface pushed into caller via Object::Exercise
########################################################################

sub exercise
{
    my $obj     = shift;

    # test seqeunce is left on the stack.

    &prepare_tests;

    # at this point the stack may be empty if the inputs were
    # flags (e.g., 'finish', or 'nofinish').

    while( @_ )
    {
        if( my @flagz = &extract_flags )
        {
            %globalz    = ( %globalz, @flagz );

            next
        }

        if( my $entry = shift )
        {
            $obj->$process( @$entry );
        }
        else
        {
            croak "Bogus test: false entry ($entry).";
        }
    }

    done_testing
    if $globalz{ finish };

    return
}

# keep require happy
1
__END__
