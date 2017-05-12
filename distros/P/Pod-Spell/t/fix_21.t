use strict;
use warnings;
use Test::More;

use Pod::Spell;
use Pod::Wordlist;

my $DEBUG = 0;
my $w;

$w = Pod::Wordlist->new(_is_debug => $DEBUG);
$w->learn_stopwords("Ph.D");
is $w->strip_stopwords("Ph.D. John Doe"), "John Doe", "Abbreviation without final dot";

$w = Pod::Wordlist->new(_is_debug => $DEBUG);
$w->learn_stopwords("Ph.D.");
is $w->strip_stopwords("Ph.D. John Doe"), "John Doe", "Abbreviation with final dot";

$w = Pod::Wordlist->new(_is_debug => $DEBUG);
$w->learn_stopwords("anaglyph.pl");
is $w->strip_stopwords("Name: anaglyph.pl"), "Name", "Program name with extension";

done_testing;
