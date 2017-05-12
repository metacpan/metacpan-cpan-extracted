# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SourceCode-Spellcheck.t'

#########################

use Test::More tests => 15;
BEGIN { use_ok('Sourcecode::Spellchecker') };

# Test that the appropriate methods exist
can_ok('Sourcecode::Spellchecker', qw(new spellcheck));

my $checker = Sourcecode::Spellchecker->new({'hootdog' => 'hotdog'});

my @results = $checker->spellcheck('t/test.cpp');
is(scalar(@results), 7);

is($results[0]->{line}, 4);
is($results[0]->{misspelling}, 'farenheit');
is($results[0]->{correction}, 'Fahrenheit');

is($results[1]->{line}, 12);
is($results[1]->{misspelling}, 'farenheit');
is($results[1]->{correction}, 'Fahrenheit');

is($results[5]->{line}, 31);
is($results[5]->{misspelling}, 'hootdog');
is($results[5]->{correction}, 'hotdog');

is($results[6]->{line}, 35);
is($results[6]->{misspelling}, 'itnroduced');
is($results[6]->{correction}, 'introduced');



