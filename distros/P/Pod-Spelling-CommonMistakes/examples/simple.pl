#!/usr/bin/perl
#
# This file is part of Pod-Spelling-CommonMistakes
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

use Test::More;

BEGIN {
	eval { require Pod::Spelling };
	if ($@){
		plan skip_all => 'requires Pod::Spelling' ;
	}
}

# First, we test without allow_words
ok((-e 'test.pod'), 'Got file');
my $o = Pod::Spelling->new( 'import_speller' => 'Pod::Spelling::CommonMistakes' );
my @r = $o->check_file( 'test.pod' );

is( @r, 0, 'Expected errors' );

done_testing();
