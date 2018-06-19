package main;

use 5.006;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

# Mung with manifest constants, since at the time this was written they
# were undefined.

use PPIx::Regexp::Constant();

# Local constants describing the current removal plans for various
# constructs involving un-escaped left curlys. Everything should be done
# in terms of these because we seem to be shooting at a moving target on
# this issue.
use constant REMOVE_NEVER	=> undef;
use constant REMOVE_PHASE_2	=> '5.030';
use constant REMOVE_PHASE_3	=> '5.032';

{

    no warnings qw{ redefine };

    # These get hammered over what was loaded above. At least under
    # 5.26.1, we do NOT want an explicit return(), because it seems to
    # prevent the constant from being inlined. MAYBE we don't care about
    # that during testing, but on the other hand, the testing
    # environment should be as much like the live environment as
    # possible.

    sub PPIx::Regexp::Constant::LITERAL_LEFT_CURLY_REMOVED_PHASE_2 () {
	REMOVE_PHASE_2 }	# As of 2018-06-08 this is the plan

    sub PPIx::Regexp::Constant::LITERAL_LEFT_CURLY_REMOVED_PHASE_3 () {
	REMOVE_PHASE_3 }	# As of 2018-06-08 this is the plan

}

use lib qw{ inc };

use My::Module::Test;

parse	( '/x{/' );	# }
value	( failures => [], 0 );
choose	( child => 1, child => 1 );
class	( 'PPIx::Regexp::Token::Literal' );
content	( '{' );	# }
value	( perl_version_removed => [], REMOVE_PHASE_2 );	# THIS IS THE POINT

parse	( '/ { /x' );	# }
value	( failures => [], 0 );
choose	( child => 1, child => 0 );
class	( 'PPIx::Regexp::Token::Literal' );
content	( '{' );	# }
value	( perl_version_removed => [], REMOVE_NEVER );	# THIS IS THE POINT

parse	( '/ ( { ) /x' );	# }
value	( failures => [], 0 );
choose	( child => 1, child => 0, child => 0 );
class	( 'PPIx::Regexp::Token::Literal' );
content	( '{' );	# }
value	( perl_version_removed => [], REMOVE_PHASE_3 );	# THIS IS THE POINT

done_testing;

1;

# ex: set textwidth=72 :
