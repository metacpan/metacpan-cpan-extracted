
use strict;
use warnings;

use Test::More tests => 45;
BEGIN { require "t/utils.pl" };

use_ok 'Parse::BooleanLogic';

my $p = new Parse::BooleanLogic;

sub test_quoting($$$) {
    my ($m, $s, $qs) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    {
        my $tmp = $p->$m($s);
        is $tmp, $qs;
        $tmp = $p->dq($tmp);
        is $tmp, $s;
    }
    { # test inplace
        my $tmp = $s;
        $p->$m($tmp);
        is $tmp, $qs;
        $p->dq($tmp);
        is $tmp, $s;
    }
}

sub test_q($$)  { return test_quoting 'q',  $_[0], $_[1] }
sub test_qq($$) { return test_quoting 'qq', $_[0], $_[1] }
sub test_fq($$) { return test_quoting 'fq', $_[0], $_[1] }

test_q "test", "'test'";
test_q "te\\'st", "'te\\\\\\'st'";
test_q 'te"st', "'te\"st'";
test_q "test\\", "'test\\\\'";

test_qq "test", '"test"';
test_qq "test\\", '"test\\\\"';
test_qq "te'st", '"te\'st"';
test_qq 'te\\"st', '"te\\\\\\"st"';

test_fq "test", "'test'";
test_fq "te'st", '"te\'st"';
test_fq 'te"st', "'te\"st'";

