package main;

use 5.010;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

BEGIN {
    eval {
	require Test::CPAN::Changes;
	Test::CPAN::Changes->import();
	1;
    } or do {
	plan	skip_all => 'Unable to load Test::CPAN::Changes';
	exit;
    };
}

changes_file_ok( Changes => { next_token => 'next_release' } );

done_testing;

1;

# ex: set textwidth=72 :
