#!perl
#
# This file is part of POE-Component-Client-SimpleFTP
#
# This software is copyright (c) 2014 by Apocalypse.
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
	is_apocalypse_here( {
		
	} );
}
