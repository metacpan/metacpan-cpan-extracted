use Test::More tests => 34;

use Carp;

BEGIN {
use_ok( 'Test::Carp' );
}

diag( "Testing Test::Carp $Test::Carp::VERSION" );

my $carp = sub { Carp::carp('I am /usr/bin/girl here me carp: args are ' . join(' ', @_)) };
my $croak = sub { Carp::croak('goodbye cruel cruel world: args are ' . join(' ', @_)) };

# diag("\nSome of the following tests purposefully work with undefined values.\nWe purposefully don't silence these warnings:\n\tUse of uninitialized value in join or string at ... Carp/Heavy.pm at line ...\n\nThat being the case we encourage you to purposefully ignore and not worry about seeing said warnings.\n\n");

does_carp( $carp ); 
does_carp( $carp, 1,2,3 ); 

does_carp_that_matches($carp,'args are ');
does_carp_that_matches($carp,1,2,3,'args are 1 2 3');

does_carp_that_matches($carp, qr/args are\s+/);
does_carp_that_matches($carp,1,2,3,qr/args are(?:\s\d){3}/);

does_carp_that_matches(sub { carp('') }, '');
does_carp_that_matches(sub { carp('') },1,2,3,'');

does_carp_that_matches(sub { carp(undef) }, undef);
does_carp_that_matches(sub { carp(undef) },1,2,3,undef);

does_carp_that_matches(sub { Carp::carp() });
# ambiguous: We can't tell if '3' is an arg to your coderef or what to look for in the message
# does_carp_that_matches(sub { Carp::carp() },1,2,3);

{
    
    # to test that these are working we need to reverse ok()
    no warnings 'redefine';

    local *Test::Carp::_ok = sub {
        Test::More::ok(!$_[0],$_[1]);  
    };
    
    does_carp( sub {} ); 
    does_carp( sub {}, 1,2,3 ); 

    does_carp_that_matches(sub {},'args are ');
    does_carp_that_matches(sub {},1,2,3,'args are 1 2 3');

    does_carp_that_matches(sub {}, qr/args are\s+/);
    does_carp_that_matches(sub {},1,2,3,qr/args are(?:\s\d){3}/);

    does_carp_that_matches(sub {}, '');
    does_carp_that_matches(sub {},1,2,3,'');

    does_carp_that_matches(sub {}, undef);
    does_carp_that_matches(sub {},1,2,3,undef);

    does_carp_that_matches(sub {});
    # ambiguous: We can't tell if '3' is an arg to your coderef or what to look for in the message
    # does_carp_that_matches(sub { Carp::carp() },1,2,3);
}

does_croak( $croak );
does_croak( $croak, 1,2,3 );

does_croak_that_matches($croak,'args are ');
does_croak_that_matches($croak,1,2,3,'args are 1 2 3');

does_croak_that_matches($croak, qr/args are\s+/);
does_croak_that_matches($croak,1,2,3,qr/args are(?:\s\d){3}/);

does_croak_that_matches(sub { croak('') }, '');
does_croak_that_matches(sub { croak('') },1,2,3,'');

does_croak_that_matches(sub { croak(undef) }, undef);
does_croak_that_matches(sub { croak(undef) },1,2,3,undef); 

does_croak_that_matches(sub { croak() });
# ambiguous: We can't tell if '3' is an arg to your coderef or what to look for in the message
# does_croak_that_matches(sub { Carp::croak() },1,2,3); 

# TODO: 
#  0. Add tests that ensure croak()/confess() stops the code ref at the point it is called
#  1. add more tests for behavior of multiple args being passed to carp/croak - i.e. "@_"
#  2. make it a loop of carp, croak instead of reimplementing the test w/ different names
#  3. add cluck and confess to the loop
