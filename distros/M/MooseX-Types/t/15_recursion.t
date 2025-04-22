use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

## Test case inspired by Stevan Little

BEGIN {
    package MooseX::Types::Test::Recursion;

    use MooseX::Types::Moose qw(Str HashRef);
    use MooseX::Types -declare => [qw(
        RecursiveHashRef
    )];

    ## Define a recursive subtype and Cthulhu save us.
    subtype RecursiveHashRef()
     => as HashRef[Str() | RecursiveHashRef()];
}

{
    package MooseX::Types::Test::Recursion::TestRunner;

    BEGIN {
        use Test::More 0.88;

        ## Grab the newly created test type constraint
        MooseX::Types::Test::Recursion->import(':all');
    };


    ok RecursiveHashRef->check({key=>"value"})
     => 'properly validated {key=>"value"}';

    ok RecursiveHashRef->check({key=>{subkey=>"value"}})
     => 'properly validated {key=>{subkey=>"value"}}';

    ok RecursiveHashRef->check({
        key=>{
            subkey=>"value",
            subkey2=>{
                ssubkey1=>"value3",
                ssubkey2=>"value4"
            }
        }
    }) => 'properly validated deeper recursive values';

    ok ! RecursiveHashRef->check({key=>[1,2,3]})
     => 'Properly invalidates bad value';

    ok ! RecursiveHashRef->check({key=>{subkey=>"value",subkey2=>{ssubkey=>[1,2,3]}}})
     => 'Properly invalidates bad value deeply';
}

done_testing;
