use String::Approx 'arindex';
use Test::More tests => 3;

is(arindex("xyz", "abcxyzdefxyz"), 9);

is(arindex("xyz", "abcxyzdefghi"), 3);

is(arindex("xyz", "abcwyzdefghi"), 3);

