use warnings;
use strict;

use Test::More;
use Number::Phone::NANP::Vanity;

# new
my $v = Number::Phone::NANP::Vanity->new(number => '4169990122');
isa_ok $v, 'Number::Phone::NANP::Vanity';

# from_string
$v = Number::Phone::NANP::Vanity->from_string('+1-416-999-0122');
isa_ok $v, 'Number::Phone::NANP::Vanity';
is $v->number, '4169990122', 'number is 4169990122';

# number
is $v->number, '4169990122', 'number';

# number_formatted
is $v->number_formatted, '416-999-0122', 'number_formatted';

# keypad_layout
is $v->keypad_layout->{A}, 2, 'A => 2';
is $v->keypad_layout->{X}, 9, 'X => 9';

# npa
is $v->npa, '416', 'npa';

# nxx
is $v->nxx, '999', 'nxx';

# nxx_sub
is $v->nxx_sub, '9990122', 'nxx_sub';

# sub
is $v->sub, '0122', 'sub';

# sub1
is $v->sub1, '01', 'sub1';

# sub2
is $v->sub2, '22', 'sub2';

# score
is_deeply $v->score, {}, 'default score is {}';
ok $v->_add_to_score(test => [1, 'test msg']), 'added to score';
is_deeply $v->score, { test => [1, 'test msg' ] }, 'new score';

# total_score
ok $v->_add_to_score(test2 => [3, 'test msg']), 'added to score again';
is $v->_total_score, 4, 'total score is now 4';

#
# RULE HELPERS
#

# _do_digits_repeat
ok $v->_do_digits_repeat('00'), '_do_digits_repeat: 00: true';
ok $v->_do_digits_repeat('9999'), '_do_digits_repeat: 9999: true';
ok ! $v->_do_digits_repeat('12'), '_do_digits_repeat: 12: false';

# _word_to_digits

is $v->_word_to_digits('test'), '8378', 'TEST => 8378';

#
# RULES
#

my @dict = qw/NUM TEST FLOWERS BAD_/;
my @rules = (
    "8008000122|npa_eq_nxx|1",
    "6134100122|npa_eq_nxx|0",
    "6137779834|nxx_repeats|2",
    "6137709834|nxx_repeats|0",
    "6137777777|nxx_sub_repeats|5",
    "6137777778|nxx_sub_repeats|0",
    "6131245555|sub_repeats|3",
    "6131245251|sub_repeats|0",
    "6131252209|sub1_repeats|1",
    "6131252109|sub1_repeats|0",
    "6131252199|sub2_repeats|1",
    "6131252191|sub2_repeats|0",
    "6132480404|sub1_eq_sub2|1",
    "6132480405|sub1_eq_sub2|0",
    "6132451234|sub_is_sequential_asc|1",
    "6132451233|sub_is_sequential_asc|0",
    "6132345678|nxx_sub_is_sequential_asc|3",
    "6132345677|nxx_sub_is_sequential_asc|0",
    "6138765432|nxx_sub_is_sequential_desc|2",
    "6138765433|nxx_sub_is_sequential_desc|0",
    "6138565656|last_three_pairs_repeat|2",
    "6138565650|last_three_pairs_repeat|0",
    "6134642346|matches_dictionary|0",
    "6134642686|matches_dictionary|1|^Matches word \"NUM\" for 1 point\$",
    "6134648378|matches_dictionary|2|for 2 points",
    "6133569377|matches_dictionary|5",
    "6132333322|digit_repeats|3|Digit 3 repeats 4 times for 3 points",
    "6132333222|digit_repeats|4|Digit 3 repeats 3 times for 2 points. Digit 2",
    "6135558125|digit_repeats|0", # does not count, because nxx has its own rule
);

foreach my $rule (@rules) {
    my ($num, $name, $score, $desc) = split('\|', $rule);
    
    my $method = "_rule_$name";
    my $r = Number::Phone::NANP::Vanity->new(
        number     => $num,
        dictionary => \@dict,
    );
    my @res = ($r->$method);
    is $res[0], $score, "rule: $name [$num]: $score";
    
    if ($desc) {
        like $res[1], qr/$desc/, "desc: $desc";
    }
}

# custom coderef rules
$v = Number::Phone::NANP::Vanity->new(number => '6132580112');
isa_ok $v, 'Number::Phone::NANP::Vanity';
ok $v->add_rule(sub { 10 }), 'Added dummy rule that returns 10';
is $v->calculate_score, 10, 'Got 10 points';

done_testing();
