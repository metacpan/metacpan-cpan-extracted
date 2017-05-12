## Test case inspired by Stevan Little

BEGIN {
    package MouseX::Types::Test::Recursion;
    
    use Mouse;

    use Mouse::Util::TypeConstraints;
    use MouseX::Types::Mouse qw(Str HashRef);
    use MouseX::Types -declare => [qw(
        RecursiveHashRef
    )];

    ## Define a recursive subtype and Cthulhu save us.
    subtype RecursiveHashRef()
     => as HashRef[Str() | RecursiveHashRef()];
}

{
    package MouseX::Types::Test::Recursion::TestRunner;
    
    BEGIN {
        use Test::More tests=>5;
        use Test::Exception;
        
        ## Grab the newly created test type constraint
        MouseX::Types::Test::Recursion->import(':all');
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






