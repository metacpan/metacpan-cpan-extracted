#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	if ( not $ENV{PERL_TEST_CRITIC} ) {
		plan skip_all => 'PerlCritic test. Sent $ENV{PERL_TEST_CRITIC} to a true value to run.';
	} else {
		# did we get a severity level?
		if ( length $ENV{PERL_TEST_CRITIC} > 1 ) {
			eval "use Test::Perl::Critic ( -severity => \"$ENV{PERL_TEST_CRITIC}\" );";
		} else {
			eval "use Test::Perl::Critic;";
			#eval "use Test::Perl::Critic ( -severity => 'stern' );";
		}

		if ( $@ ) {
			plan skip_all => 'Test::Perl::Critic required to criticise perl files';
		} else {
			all_critic_ok( 'lib/' );
		}
	}
}
