use v5.36;
use utf8;
use Test::More;
use lib 'lib';
use Peta::NN::Codec qw(build_vocab window edit_label apply_edit edit2_label apply_edit2 PAD UNKNOWN);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $vocab = build_vocab([ 'abc', 'cab', 'é' ]);
is_deeply($vocab, { a => 2, b => 3, c => 4, 'é' => 5 }, 'vocabulary: sorted characters, numbered from 2');

my @chars = split //, 'abcab';
is_deeply(window(\@chars, 2, 3, $vocab), [ 4, 2, 3 ], 'a window inside the string');
is_deeply(window(\@chars, @chars - 3, 3, $vocab), [ 4, 2, 3 ], 'the last three');
is_deeply(window(\@chars, @chars - 7, 7, $vocab), [ PAD, PAD, 2, 3, 4, 2, 3 ], 'longer than the string: padded in front');
is_deeply(window(\@chars, 0, 7, $vocab), [ 2, 3, 4, 2, 3, PAD, PAD ], 'the first seven: padded behind');
is_deeply(window(\@chars, -1, 3, $vocab), [ PAD, 2, 3 ], 'centred on the first character');
is_deeply(window(\@chars, 3, 3, $vocab), [ 2, 3, PAD ], 'centred on the last character');
is_deeply(window([ split //, 'axb' ], 0, 3, $vocab), [ 2, UNKNOWN, 3 ], 'a character not in the vocabulary');
is_deeply(window([], 0, 2, $vocab), [ PAD, PAD ], 'the empty string');

my @EDITS = (
    [ 'Jelínek', 'Jelínku',  '2:ku' ],
    [ 'Hansard', 'Hansarde', '0:e' ],
    [ 'Irena',   'Ireno',    '1:o' ],
    [ 'same',    'same',     '0:' ],
    [ 'abc',     'xyz',      '3:xyz' ],
    [ 'a:b',     'a:c:d',    '1:c:d' ],     # a colon in the appended text survives
    [ 'abcd',    'ab',       '2:' ],
);
for my $case (@EDITS) {
    my ($in, $out, $label) = @$case;
    is(edit_label($in, $out), $label, "edit_label($in, $out)");
    is(apply_edit($in, $label), $out, "apply_edit($in, $label)");
}
is(apply_edit('Helena', edit_label('Irena', 'Ireno')), 'Heleno', 'an edit learned on one word applies to another');
is(apply_edit('ab', '3:x'), undef, 'an edit that cuts more than there is cannot apply');

# An edit at both ends keeps what input and output share and rewrites around it.
my @BOTH = (
    [ 'chytrý',       'nejchytřejší', '0:nej|2:řejší' ],
    [ 'nejchytřejší', 'chytrý',       '3:|5:rý' ],
    [ 'dobrý',        'lepší',        '0:|5:lepší' ],         # nothing shared: all of it is replaced
    [ 'same',         'same',         '0:|0:' ],
    [ '',             'x',            '0:|0:x' ],
    [ 'abab',         'xabx',         '0:x|2:x' ],            # of two equal stretches, the first in the input
);
for my $case (@BOTH) {
    my ($in, $out, $label) = @$case;
    is(edit2_label($in, $out), $label, "edit2_label($in, $out)");
    is(apply_edit2($in, $label), $out, "apply_edit2($in, $label)");
}
is(apply_edit2('rychlý', edit2_label('chytrý', 'nejchytřejší')), 'nejrychřejší', 'a two-ended edit applies mechanically to another word');
is(apply_edit2('ab', '2:|1:x'), undef, 'a two-ended edit that cuts more than there is cannot apply');

done_testing;
