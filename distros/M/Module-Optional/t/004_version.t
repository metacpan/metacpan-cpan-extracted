# -*- perl -*-

# t/004_version.t - Test optional module with version number

use Test::More tests => 6;
use strict;

BEGIN { 
#01	
	use_ok( 'Params::Validate::Dummy', qw());
	# Force dummied P::V to be used
#02
	use_ok( 'Module::Optional', 'Params::Validate', 9.99 ); }

#03
can_ok('Params::Validate', 'validate');

#04
can_ok('Params::Validate', 'validate_pos');

my @args = qw(foo bar);

#05
is_deeply([validate_pos(@args, 1,1,1)], \@args, "validate_pos passed thru");

@args = ( foo=>1, bar=>2);

#06
is_deeply([validate(@args, {foo => 1})], \@args, "validate pass thru");
