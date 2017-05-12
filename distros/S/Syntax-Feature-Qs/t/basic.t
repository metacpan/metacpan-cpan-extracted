use strict;
use Test::More;
use syntax 'qs';

subtest 'qs' => sub {
    is qs/a test/, 'a test', 'single quotes, single line';

    is qs{ first line
           second line
          }, "first line\nsecond line\n", 'single quotes, multiple lines I';

    is qs{ first line
           second line
}, "first line\nsecond line\n", 'single quotes, multiple lines II';

    is qs{
           first line
           second line}, "\nfirst line\nsecond line", 'single quotes, multiple lines III';

    is qs{ first line
           second line   }, "first line\nsecond line", 'single quotes, multiple lines IV';

    is_deeply ['first', \qs/3/, 'third'], ['first', \3, 'third'], 'As reference';

    is sprintf(qs{
            first: %d
            second: %s     }, '37', 'tests'), "\nfirst: 37\nsecond: tests", 'sprintf-d';

    is qs 2
            34562, qq 2\n34562, 'Spaced and numerical';

    is qs[
            1 2 3 ]."\n", "\n1 2 3\n", 'Precedence';

    is qs " $why @do \this ", q{$why @do \this}, '...';

    done_testing;
};


subtest "qqs" => sub {
    is qqs{ single line }, 'single line', 'single line';

    is qqs{
        one
        two
    }, "\none\ntwo\n", 'Multiple line, leading+trailing';

    my ($foo, $bar) = (21, 23);
    is qqs{
        $foo
        $bar
    }, "\n21\n23\n", 'interpolating';

    is qqs!
        foo
        bar    !, "\nfoo\nbar", 'exclamation delimiter';

    is_deeply [ 23, \qqs/52/, 17 ], [23, \52, 17], 'references';

    is qqs! foo @{[ map "$_\n", qw( bar baz ) ]} qux !,
        "foo bar\nbaz\nqux",
        'embedded expression';

    ok qqs(  main  )->can('is'), 'dereference precedence';

    done_testing;
};

done_testing;

