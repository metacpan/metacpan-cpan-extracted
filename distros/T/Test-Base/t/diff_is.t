use Test::Base tests => 1;

SKIP: {
    if ($^O eq 'MSWin32' or $^O eq 'android') {
        skip "$^O doesn't have /tmp", 1;
    }

    unless (Test::Base->have_text_diff) {
        skip 'The autodiffing feature of Test::Base (which rocketh) requires Text-Diff-0.35 and Algorithm-Diff-1.15 (or greater).', 1;
    }

    filters {
        test => [qw(exec_perl_stdout smooth_output)],
        expected => 'smooth_output',
    };
    run_is;

    sub smooth_output {
        s/test-blocks-\d+/test-blocks-321/;
        # XXX Busted across various Test::Simple versions
        # s/at line \d+\)/at line 000)/;
        # s/in (.*) at line (\d+)/at $1 line $2/; # for Test::Simple 0.65
        s/(   )(.*) line (\d+)\./$1at <file> line <number>./;
        s/TAP version 13//;
        s{Looks like you failed (\d+) (tests?) of (\d+)\.}{$1 $2 of $3 failed.};
        s/^\n//gm;
    }
}

__DATA__
=== little diff
--- test
use lib 'lib';
use Test::Base tests => 1;
is('a b c', 'a b x', 'little diff');
--- expected
1..1
not ok 1 - little diff
#   Failed test 'little diff'
#   at <file> line <number>.
#          got: 'a b c'
#     expected: 'a b x'
# Looks like you failed 1 test of 1.


=== big diff
--- SKIP
--- test
use lib 'lib';
use Test::Base tests => 1;
is(<<XXX, <<YYY, 'big diff');
one
two
four
five
XXX
one
two
three
four
YYY
--- expected
1..1
not ok 1 - big diff
# @@ -1,4 +1,4 @@
#  one
#  two
# -three
#  four
# +five
#
#   Failed test 'big diff
# @@ -1,4 +1,4 @@
#  one
#  two
# -three
#  four
# +five
# '
#   in /tmp/test-blocks-321 at line 3.
# Looks like you failed 1 test of 1.


=== diff with space - note: doesn't help point out the extra space (yet)
--- SKIP
--- test
use lib 'lib';
use Test::Base tests => 1;
is(<<XXX, <<YYY, 'diff with space');
one
two
three
XXX
one
two
three
YYY

--- expected
1..1
not ok 1 - diff with space
#   Failed test 'diff with space'
#   in /tmp/test-blocks-321 at line 3.
# @@ -1,3 +1,3 @@
#  one
# -two
# +two
#  three
# Looks like you failed 1 test of 1.


