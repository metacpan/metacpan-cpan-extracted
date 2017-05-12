#!perl -T

use strict;
use warnings;

use PPI;
use Test::FailWarnings -allow_deps => 1;
use Test::More;
use Test::Perl::Critic::Policy qw( all_policies_ok );


# PPI v1.218 introduces parsing bugs for .run test files with Perl v5.12 and
# below. As a result, PPI v1.215 is the last version that works with Perl lower
# than v5.14.
if ( ( $PPI::VERSION > 1.215 ) && ( $] < 5.014 ) )
{
	diag( "Using PPI v$PPI::VERSION with Perl v$]." );
	plan( skip_all => 'PPI v1.218 introduces parsing bugs for .run test files with Perl v5.12 and below, skipping' );
}

all_policies_ok(
	-policies => [ 'PreventSQLInjection' ],
);
