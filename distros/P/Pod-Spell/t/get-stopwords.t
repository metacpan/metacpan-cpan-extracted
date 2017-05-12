use strict;
use warnings;
use Test::More;
use Test::Deep;
use Pod::Wordlist;

my $p = new_ok 'Pod::Wordlist';

$p->learn_stopwords( 'foo bar baz' );

cmp_deeply [ keys( %{ $p->wordlist } ) ],
	superbagof(qw(foo bar baz )),
	'stopwords added'
	;

$p->learn_stopwords( '!foo' );

cmp_deeply [ keys( %{ $p->wordlist } ) ], superbagof(qw( bar baz )),
	'stopwords still exist';

ok ! exists $p->wordlist->{foo}, 'foo was removed';

done_testing;
