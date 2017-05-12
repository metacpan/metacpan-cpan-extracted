use strict;
use Test::More;
use syntax qw/qi/;

subtest 'qi' => sub {

    is qi/  /, '  ', 'just spaces - untouched';

    is qi/a test/, 'a test', 'single quotes, single line';

    is qi{ first line
           second line
          }, "first line\n          second line\n         ", 'single quotes, multiple lines I';

    is qi{    first line
           second line
  }, "first line\n       second line\n  ", 'single quotes, multiple lines II';

    is qi{
           first line
               second line}, "\nfirst line\n    second line", 'single quotes, multiple lines III';

    is qi{ first line
           second line   }, "first line\n          second line   ", 'single quotes, multiple lines IV';

    is_deeply ['first', \qi/3/, 'third'], ['first', \3, 'third'], 'As reference';

    is sprintf(qi{
            first: %d
            second: %s     }, '37', 'tests'), "\nfirst: 37\nsecond: tests     ", 'sprintf-d';

    is qi 2
            34562, qq 2\n34562, 'Spaced and numerical';

    is qi[
            1 2 3 ]."\n", "\n1 2 3 \n", 'Precedence';

    is qi " $why @do \this ", q{$why @do \this }, '...';

    done_testing;
};


subtest "qqi" => sub {
    is qqi{ single line }, 'single line ', 'single line';

    is qqi{
        one
            two
    }, "\none\n    two\n    ", 'Multiple line, leading+trailing';

    my ($foo, $bar) = (21, 23);
    is qqi{
        $foo
       $bar
    }, "\n21\n       23\n    ", 'interpolating';

    is qqi!
        foo
        bar    !, "\nfoo\nbar    ", 'exclamation delimiter';

    is_deeply [ 23, \qqi/52/, 17 ], [23, \52, 17], 'references';

    is qqi! foo @{[ map "$_\n", qw( bar baz ) ]} qux !,
        "foo bar\nbaz\nqux ",
        'embedded expression';

    done_testing;
};

done_testing;

