#!perl

# $Id: Token-error.t,v 1.2 2010/10/12 21:18:13 Paulo Exp $

use strict;
use warnings;

use Test::More;
use File::Spec;

if ( not $ENV{AUTHOR_TESTS} ) {
	my $msg = 'Author test.  Set $ENV{AUTHOR_TESTS} to a true value to run.';
	plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $@ ) {
	my $msg = 'Test::Perl::Critic required to criticise code';
	plan( skip_all => $msg );
}

#my $rcfile = File::Spec->catfile( 't', '.perlcriticrc' );
#Test::Perl::Critic->import( -profile => $rcfile );
Test::Perl::Critic->import( -severity => 5, -verbose => 11 );
all_critic_ok();
