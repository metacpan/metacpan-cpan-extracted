use Test::More;
plan skip_all => 'Test::Valgrind has false positives';
eval 'use Test::Valgrind';
plan skip_all =>
    'Test::Valgrind is required to test your distribution with valgrind'
    if $@;

use_ok('Search::Tools::Snipper');
my $snipper = Search::Tools::Snipper->new( query => 'three', max_chars => 1 );
my $snip = $snipper->snip('one two three four five');
