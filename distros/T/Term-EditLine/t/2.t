use strict;
use warnings;
use utf8;
use Test::More;
use Term::EditLine;

my $el;

sub context;

$ENV{LANG} = 'C';

subtest 'history_get_size' => sub {
    context 'scalar' => sub {
        is(0+$el->history_get_size(), 0);
    };
    context 'list' => sub {
        my ($a, $b) = $el->history_get_size();
        is($a, 0);
        is($b, 0);
    };
    context 'scalar after enter' => sub {
        is(0+$el->history_get_size(), 0);
        $el->history_enter('hoge');
        is(0+$el->history_get_size(), 1);
    };
};

subtest 'history_clear' => sub {
    context 'input and clear' => sub {
        is(0+$el->history_get_size(), 0);
        $el->history_enter('hoge');
        is(0+$el->history_get_size(), 1);
        $el->history_clear();
        is(0+$el->history_get_size(), 0);
    };
};

subtest 'history_get_first' => sub {
    context 'scalar in empty' => sub {
        is(scalar($el->history_get_first()), 'first event not found');
    };
    context 'list in empty' => sub {
        my ($a, $b) = $el->history_get_first();
        is($a, -1);
        is($b, 'first event not found');
    };
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_first()), 'fuga');
    };
};

subtest 'history_get_last' => sub {
    context 'scalar in empty' => sub {
        is(scalar($el->history_get_last()), 'last event not found');
    };
    context 'list in empty' => sub {
        my ($a, $b) = $el->history_get_last();
        is($a, -1);
        is($b, 'last event not found');
    };
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_last()), 'hoge');
    };
};

subtest 'history_get_prev' => sub {
    context 'scalar in empty' => sub {
        is(scalar($el->history_get_prev()), 'empty list');
    };
    context 'list in empty' => sub {
        my ($a, $b) = $el->history_get_prev();
        is($a, -1);
        is($b, 'empty list');
    };
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_prev()), 'no previous event');
        is(scalar($el->history_get_first()), 'fuga');
        is(scalar($el->history_get_prev()), 'no previous event');
    };
};

subtest 'history_get_next' => sub {
    context 'scalar in empty' => sub {
        is(scalar($el->history_get_next()), 'empty list');
    };
    context 'list in empty' => sub {
        my ($a, $b) = $el->history_get_next();
        is($a, -1);
        is($b, 'empty list');
    };
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_next()), 'hoge');
        is(scalar($el->history_get_next()), 'no next event');
    };
};

subtest 'history_get_curr' => sub {
    context 'scalar in empty' => sub {
        is(scalar($el->history_get_curr()), 'empty list');
    };
    context 'list in empty' => sub {
        my ($a, $b) = $el->history_get_curr();
        is($a, -1);
        is($b, 'empty list');
    };
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_curr()), 'fuga');
        is(scalar($el->history_get_curr()), 'fuga');
    };
};

subtest 'history_set' => sub {
    context 'scalar in empty' => sub {
        is(scalar($el->history_set()), -1);
    };
};

subtest 'history_get_prev_str' => sub {
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_prev_str('h')), 'hoge');
    };
};

subtest 'history_get_next_str' => sub {
    context 'scalar after enter' => sub {
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is(scalar($el->history_get_next_str('f')), 'fuga');
    };
};

subtest 'history_save, history_load' => sub {
    context 'save and load' => sub {
        unlink 't/history.dat' if -f 't/history.dat';
        $el->history_enter('hoge');
        $el->history_enter('fuga');
        is($el->history_save('t/history.dat'), 2);

        my $el2 = Term::EditLine->new($0);
        is($el2->history_get_size(), 0);
        $el2->history_load('t/history.dat');
        is($el2->history_get_size(), 2);

        unlink 't/history.dat' if -f 't/history.dat';
    };
};

done_testing;

sub context {
    my ($name, $code) = @_;
    $el = Term::EditLine->new($0);
    goto &Test::More::subtest;
}
