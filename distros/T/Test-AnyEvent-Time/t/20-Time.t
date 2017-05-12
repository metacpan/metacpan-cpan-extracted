
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More tests => 81;

BEGIN {
    use_ok('AnyEvent::Strict');
    use_ok('Test::AnyEvent::Time');
}

sub timer {
    my ($time) = @_;
    return undef if !defined($time);
    return sub {
        my ($cv) = @_;
        my $w; $w = AnyEvent->timer(
            after => $time,
            cb => sub {
                undef $w;
                $cv->send();
            }
        );
    };
}

sub multi_timer {
    my (@times) = @_;
    return sub {
        my ($cv) = @_;
        foreach my $time (@times) {
            $cv->begin();
            my $w; $w = AnyEvent->timer(
                after => $time,
                cb => sub {
                    undef $w;
                    $cv->end();
                }
            );
        }
    };
}

sub call_time_cmp {
    my ($is_ok, $got_time, $op, $ref_time, $timeout, $desc, $after) = @_;
    my $ret;
    my $exp_desc = defined($desc) ? " - $desc" : "";
    if($is_ok) {
        test_out "ok 1$exp_desc";
    }else {
        test_out "not ok 1$exp_desc";
    }
    if(defined($timeout)) {
        $timeout = undef if $timeout eq 'undef';
        test_fail(+1) if !$is_ok;
        $ret = time_cmp_ok timer($got_time), $op, $ref_time, $timeout, $desc;
    }else {
        test_fail(+1) if !$is_ok;
        $ret = time_cmp_ok timer($got_time), $op, $ref_time, $desc;
    }
    $after->() if defined($after);
    test_test $exp_desc;
    is($ret, $is_ok, "return value: $is_ok");
}

sub check_ok {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(1, $got_time, $op, $ref_time, $timeout, $desc);
}

sub test_err_wrong_time {
    my ($op, $ref_time) = @_;
    test_err qr!# +'[^']+' *\n!;
    test_err qr!# +$op *\n!;
    test_err qr!# +'$ref_time' *\n?!;
}

sub test_err_timeout {
    my ($timeout) = @_;
    test_err qr!# +Timeout \($timeout sec\) *\n!;
}

sub test_err_invalid {
    test_err qr!# +Invalid arguments\. *\n!;
}

sub check_wrong_time {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(
        0, $got_time, $op, $ref_time, $timeout, $desc, sub {
            test_err_wrong_time($op, $ref_time);
        }
    );
}

sub check_timeout {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(
        0, $got_time, $op, $ref_time, $timeout, $desc, sub {
            test_err_timeout($timeout);
        }
    );
}

sub check_invalid {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(
        0, $got_time, $op, $ref_time, $timeout, $desc, sub {
            test_err_invalid();
        }
    );
}

note("-- OK cases");
check_ok 0.2, "<", 0.4, undef, "<, no timeout";
check_ok 1, ">=", 0.4, undef, ">=, no timeout";
check_ok 0.3, "<=", 1, 2, "<=, timeout(2)";
check_ok 0.7, ">", 0.5, 1, ">, timeout(1)";
check_ok 0.4, "<", 0.6, "undef", "<, timeout(undef)";
check_ok 0.3, ">", 0.1, "undef", ">, timeout(undef)";
check_ok 0.2, ">", 0.1;
check_ok 0.3, "<", 1;

test_out("ok 1 - multi timers");
time_cmp_ok(multi_timer(0, 0.3, 0.2, 1, 0.6, 0.1, 0.2), "<", 1.2, "multi timers");
test_test("multi timers");

note("-- NOT OK cases");
check_wrong_time 0.2, ">", 0.4, undef, ">, no timeout";
check_wrong_time 1, "<=", 0.4, undef, "<=, no timeout";
check_wrong_time 0.3, ">=", 1, 2, ">=, timeout(2)";
check_wrong_time 0.7, "<", 0.5, 1, "<, timeout(1)";
check_wrong_time 0.4, ">", 0.6, "undef", ">, timeout(undef)";
check_wrong_time 0.3, "<", 0.1, "undef", "<, timeout(undef)";
check_wrong_time 0.2, "<", 0.1;
check_wrong_time 0.3, ">", 1;

note("-- Timeout cases");
check_timeout 0.4, ">=", 0.1, 0.3, ">=";
check_timeout 0.5, ">", 1, 0.2, ">";
check_timeout 0.2, "<", 0.4, 0.1, "<";
check_timeout 1, "<=", 5, 0.3, "<=";

note("-- Invalid arguments");
check_invalid;
check_invalid 1;
check_invalid undef, ">", 0.4;
check_invalid 1, undef, 0.2;
check_invalid 5, "==";
check_invalid undef, "<", 3, 2.5;

my $ret;

note("-- time_between_ok");
test_out("ok 1 - between");
$ret = time_between_ok(timer(0.6), 0.3, 0.8, "between");
test_test("time_between_ok: ok");
ok($ret);
test_out("ok 1");
$ret = time_between_ok(timer(0.2), 0, 0.4);
test_test("time_between_ok: ok (no desc)");
ok($ret);

test_out("not ok 1 - too long");
test_fail(+1);
$ret = time_between_ok(timer(5), 0.2, 0.6, "too long");
test_err_timeout(0.6);
test_test("time_between_ok: not ok: too long");
ok(!$ret);

test_out("not ok 1 - too short");
test_fail(+1);
$ret = time_between_ok(timer(0), 0.4, 0.8, "too short");
test_err_wrong_time(">", 0.4);
test_test("time_between_ok: not ok: too short");
ok(!$ret);

test_out("not ok 1");
test_fail(+1);
$ret = time_between_ok();
test_err_invalid();
test_test("time_between_ok: not ok: invalid");
ok(!$ret);

test_out("not ok 1");
test_fail(+1);
$ret = time_between_ok(3, 0.5);
test_err_invalid();
test_test("time_between_ok: not ok: invalid");
ok(!$ret);

note("-- time_within_ok");
test_out("ok 1 - within");
$ret = time_within_ok(timer(0.4), 0.6, "within");
test_test("time_within_ok: ok, with desc");
ok($ret);
test_out("ok 1");
$ret = time_within_ok(timer(0.2), 1.2);
test_test("time_within_ok: ok, without desc");
ok($ret);

test_out("not ok 1 - too long");
test_fail(+1);
$ret = time_within_ok(timer(10), 0.2, "too long");
test_err_timeout(0.2);
test_test("time_within_ok: not ok, with desc");
ok(!$ret);

test_out("not ok 1");
test_fail(+1);
$ret = time_within_ok(multi_timer(0.1, 0, 0.2, 0.6, 0.3, 0.8), 0.5);
test_err_timeout(0.5);
test_test("time_within_ok: not ok, without desc, multi timer");
ok(!$ret);

test_out("not ok 1");
test_fail(+1);
$ret = time_within_ok(timer(4), 0.5);
test_err_timeout(0.5);
test_test("time_within_ok: not ok, without desc");
ok(!$ret);

test_out("not ok 1");
test_fail(+1);
$ret = time_within_ok(timer(2));
test_err_invalid();
test_test("time_within_ok: not ok, invalid");
ok(!$ret);

test_out("not ok 1 - hoge");
test_fail(+1);
$ret = time_within_ok(undef, undef, "hoge");
test_err_invalid();
test_test("time_within_ok: not ok, invalid with desc");
ok(!$ret);
