use strict;
use warnings;

use Test::More;

use Params::Lazy delayed => '^^^$';
sub delayed {
    my @retvals;
    push @retvals, force($_[1]);
    push @retvals, force($_[0]);
    push @retvals, force($_[2]);

    return @retvals;
}

my @retvals = delayed
                  print("ok 3\n"),
                  \print("ok 2\n"),
                  do { print("ok 4\n"); "from do" },
                  print("ok 1 - This test was fourth in the file, came up first\n");

my $test_builder = Test::More->builder;
$test_builder->current_test(4);

is_deeply(
    \@retvals,
    [\1, 1, "from do"],
    "..and got the right return values"
);


sub test_refcnt {
   my ($code, $expect) = @_;
   my $ret  = force($code);
   
   is(Internals::SvREFCNT($ret), $expect, "correct refcount");
}

sub return_ref { return \1 }

use Params::Lazy test_refcnt => '^$';

test_refcnt("foo", 1);
test_refcnt(return_ref(), 1);

my $foo = \100;
my $bar = \$foo;
test_refcnt($foo, 1);

my @test;
sub test_delay {
    my ($delayed, $results, $test) = @_;
    
    my $x = force($delayed);
    
    if (@$results) {
        is($x, $results->[-1], "");
    }
    
    my @x = force($delayed);
    is_deeply(\@x, $results, "Can handle multiple return values: $test");
    
    my $f = join "", "<", force($delayed), ">\n";
    is(
        $f,
        join("", "<", @$results, ">\n"),
        "returning lists works when used as part of an expression: $test"
    );
    
    return 1..10;
}

use Params::Lazy test_delay => '^$;$';

my @ret1 = test_delay(
    map({ push @test, "map: $_\n"; "map: $_\n" } 1..5),
    [ map "map: $_\n", 1..5 ],
    "map"
);

is_deeply(\@ret1, [1..10], "..and it doesn't corrupt the stack");

#is_deeply(\@tests, )

my @ret2 = test_delay(
    grep(undef, 1..70),
    [  ],
    "grep returning an empty list"
);

is_deeply(\@ret2, [1..10], "..and it doesn't corrupt the stack");


sub empty {}

my @ret3 = test_delay(
    empty(),
    [  ],
    "sub empty {}"
);

is_deeply(\@ret3, [1..10], "..and it doesn't corrupt the stack");

() = test_delay(
    (),
    [  ],
    "()"
);


done_testing;
