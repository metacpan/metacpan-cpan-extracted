use strict;
use warnings;
use Test::More;
use Pod::Wordlist;

my $p = new_ok 'Pod::Wordlist';

$p->learn_stopwords( 'foo bar baz' );

ok exists $p->wordlist->{foo}, 'stopword added: foo';
ok exists $p->wordlist->{bar}, 'stopword added: bar';
ok exists $p->wordlist->{baz}, 'stopword added: baz';

$p->learn_stopwords( '!foo' );

ok ! exists $p->wordlist->{foo}, 'stopword removed: foo';
ok exists $p->wordlist->{bar}, 'stopword still exists: bar';
ok exists $p->wordlist->{baz}, 'stopword still exists: baz';

done_testing;
