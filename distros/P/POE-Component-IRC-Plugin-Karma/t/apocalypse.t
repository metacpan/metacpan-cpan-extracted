#!perl
#
# This file is part of POE-Component-IRC-Plugin-Karma
#
# This software is copyright (c) 2011 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
use strict; use warnings;

use Test::More;
eval "use Test::Apocalypse 1.000";
if ( $@ ) {
	plan skip_all => 'Test::Apocalypse required for validating the distribution';
} else {
	# hack for Kwalitee ( zany require format so DZP::AutoPrereq will not pick it up )
	require 'Test/NoWarnings.pm'; require 'Test/Pod.pm'; require 'Test/Pod/Coverage.pm';

	is_apocalypse_here( {
		
	} );
}
