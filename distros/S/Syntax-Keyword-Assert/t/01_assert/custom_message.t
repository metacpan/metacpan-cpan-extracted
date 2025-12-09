use Test2::V0;
use Syntax::Keyword::Assert;

use lib 't/lib';
use TestUtil;

subtest 'basic custom message' => sub {
    like dies { assert(0, "Something went wrong") },
        qr/Something went wrong/;
    like dies { assert(undef, "Value is undef") },
        qr/Value is undef/;
    like dies { assert('', "Empty string") },
        qr/Empty string/;
    like dies { assert('0', "String zero") },
        qr/String zero/;
};

subtest 'success cases with custom message' => sub {
    ok lives { assert(1, "This should not appear") };
    ok lives { assert("hello", "This should not appear") };
    ok lives { assert(100, "This should not appear") };
};

subtest 'custom message with numeric comparison' => sub {
    like dies { assert(1 == 0, "1 should equal 0") },
        qr/1 should equal 0/;
    like dies { assert(5 != 5, "5 should not equal 5") },
        qr/5 should not equal 5/;
    like dies { assert(5 < 3, "5 should be less than 3") },
        qr/5 should be less than 3/;
    like dies { assert(2 > 10, "2 should be greater than 10") },
        qr/2 should be greater than 10/;
    like dies { assert(10 <= 5, "10 should be <= 5") },
        qr/10 should be <= 5/;
    like dies { assert(3 >= 10, "3 should be >= 10") },
        qr/3 should be >= 10/;

    # success cases
    ok lives { assert(1 == 1, "This should not appear") };
    ok lives { assert(5 > 3, "This should not appear") };
    ok lives { assert(3 < 5, "This should not appear") };
};

subtest 'custom message with string comparison' => sub {
    like dies { assert("foo" eq "bar", "strings should match") },
        qr/strings should match/;
    like dies { assert("same" ne "same", "strings should differ") },
        qr/strings should differ/;
    like dies { assert("z" lt "a", "z should be lt a") },
        qr/z should be lt a/;
    like dies { assert("a" gt "z", "a should be gt z") },
        qr/a should be gt z/;
    like dies { assert("z" le "a", "z should be le a") },
        qr/z should be le a/;
    like dies { assert("a" ge "z", "a should be ge z") },
        qr/a should be ge z/;

    # success cases
    ok lives { assert("foo" eq "foo", "This should not appear") };
    ok lives { assert("a" lt "b", "This should not appear") };
};

subtest 'lazy evaluation of custom message' => sub {
    subtest 'message not evaluated when condition is true' => sub {
        my $evaluated = 0;
        my $get_msg = sub { $evaluated++; return "should not see this" };

        ok lives { assert(1, $get_msg->()) };
        is $evaluated, 0, "message expression is NOT evaluated when condition is true";
    };

    subtest 'message evaluated when condition is false' => sub {
        my $evaluated = 0;
        my $get_msg = sub { $evaluated++; return "assertion failed!" };

        like dies { assert(0, $get_msg->()) },
            qr/assertion failed!/;
        is $evaluated, 1, "message expression is evaluated when condition is false";
    };

    subtest 'expensive computation skipped when true' => sub {
        my @log;
        my $expensive = sub { push @log, "computed"; return "error msg" };

        ok lives { assert("truthy value", $expensive->()) };
        is scalar(@log), 0, "expensive computation skipped when condition is true";
    };

    subtest 'side effects only on false' => sub {
        my $side_effect_count = 0;
        my $msg_with_side_effect = sub {
            $side_effect_count++;
            return "Side effect triggered $side_effect_count times";
        };

        # Multiple true assertions - side effects should NOT happen
        ok lives { assert(1, $msg_with_side_effect->()) };
        ok lives { assert("yes", $msg_with_side_effect->()) };
        ok lives { assert(100, $msg_with_side_effect->()) };

        is $side_effect_count, 0, "no side effects when all conditions are true";

        # Now a false assertion - side effect SHOULD happen
        like dies { assert(0, $msg_with_side_effect->()) },
            qr/Side effect triggered/;
        is $side_effect_count, 1, "side effect happened on false assertion";
    };
};

subtest 'custom message with variables' => sub {
    subtest 'basic' => sub {
        my $x = 0;
        my $msg = "Variable x is falsy";
        like dies { assert($x, $msg) },
            qr/Variable x is falsy/;

        my $y = undef;
        like dies { assert($y, "Value is undef") },
            qr/Value is undef/;

        my $empty = '';
        like dies { assert($empty, "Empty string") },
            qr/Empty string/;

        # success
        my $z = 1;
        ok lives { assert($z, "This should not appear") };
    };

    subtest 'numeric comparison' => sub {
        my $a = 10;
        my $b = 20;
        like dies { assert($a == $b, "values should be equal(a:$a, b:$b)") },
            qr/values should be equal\(a:10, b:20\)/;

        my $x = 5;
        my $y = 5;
        like dies { assert($x != $y, "$x should not equal $y") },
            qr/5 should not equal 5/;

        like dies { assert($x < 3, "$x should be less than 3") },
            qr/5 should be less than 3/;

        like dies { assert($x > 10, "$x should be greater than 10") },
            qr/5 should be greater than 10/;

        # success
        ok lives { assert($a < $b, "This should not appear") };
        ok lives { assert($b > $a, "This should not appear") };
    };

    subtest 'string comparison' => sub {
        my $str1 = "hello";
        my $str2 = "world";
        like dies { assert($str1 eq $str2, "strings should match") },
            qr/strings should match/;

        my $same = "foo";
        like dies { assert($same ne $same, "$same should differ from itself") },
            qr/foo should differ from itself/;

        my $a = "z";
        my $b = "a";
        like dies { assert($a lt $b, "$a should be lt $b") },
            qr/z should be lt a/;

        # success
        ok lives { assert($str1 ne $str2, "This should not appear") };
        ok lives { assert($b lt $a, "This should not appear") };
    };
};

done_testing;
