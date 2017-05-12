use Test::Chunks;

eval { require Text::Diff; 1 } or
plan skip_all => 'Requires Test::Diff';
plan tests => 3;

filters { 
    test => [qw(exec_perl_stdout smooth_output)],
    expected => 'smooth_output',
};
run_is test => 'expected';

sub smooth_output { 
    local $_ = shift;
    s/test-chunks-\d+/test-chunks-321/;
    s/at line \d+\)/at line 000)/;
    s/^\n//gm;
    return $_;
}

__DATA__
=== little diff
--- test
use lib 'lib';
use Test::Chunks tests => 1;
is('a b c', 'a b x', 'little diff');
--- expected
1..1
not ok 1 - little diff
#     Failed test (/tmp/test-chunks-123 at line 3)
#          got: 'a b c'
#     expected: 'a b x'
# Looks like you failed 1 test of 1.


=== big diff
--- test
use lib 'lib';
use Test::Chunks tests => 1;
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
# +three
#  four
# -five
# 

#     Failed test (/tmp/test-chunks-123 at line 3)
# Looks like you failed 1 test of 1.


=== diff with space - note: doesn't help point out the extra space (yet)
--- test
use lib 'lib';
use Test::Chunks tests => 1;
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
# @@ -1,3 +1,3 @@
#  one
# -two
# +two 
#  three
# 

#     Failed test (/tmp/test-chunks-123 at line 3)
# Looks like you failed 1 test of 1.
