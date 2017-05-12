# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl String-CyclicRotation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 33;
BEGIN { use_ok('String::CyclicRotation', qw(:all)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %right_pairs = (
    'abcde' => 'cdeab',
    'aaa' => 'aaa',
    '' => '',
    'ara' => 'raa',
    'aab' => 'baa',
    'sas' => 'ssa',
    'arar' => 'rara',
    'aabb' => 'abba',
    'sass', 'ssas',
    'bttttttts','tttttttsb'
);

my %wrong_pairs = (
    'u' => '',
    '' => 'asd',
    'dra' => 'raa',
    'pab' => 'aba',
    'bta' => 'aab',
    'scs' => 'ssa'
);

for my $word (keys %right_pairs) {
    is(is_rotation($word, $right_pairs{$word}), 1);
    is(is_rotation($right_pairs{$word}, $word), 1);
}

for my $word (keys %wrong_pairs) {
    is(is_rotation($word, $wrong_pairs{$word}), 0);
    is(is_rotation($wrong_pairs{$word}, $word), 0);
}
