package main;

use 5.006;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use PPI::Document;
use PPIx::Regexp;

{
    my $doc = PPI::Document->new( 'eg/predump' );
    $doc->index_locations();
    my @re = PPIx::Regexp->extract_regexps( $doc );

    cmp_ok scalar @re, '==', 2, 'Found two regexps';

    is $re[0]->content(), 'qr{ \\s* , \\s* }smx',
	q<First regexp is qr{ \\s* , \\s* }smx>;

    is $re[1]->content(), 's/ \\\\\\\\ /\\\\/smxg',
	q<Second regexp is s/ \\\\\\\\ /\\\\/smxg>;

}

done_testing;

1;

# ex: set textwidth=72 :
