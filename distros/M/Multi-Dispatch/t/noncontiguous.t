use 5.022;
use warnings;
use strict;

use Test::More;

use Multi::Dispatch;

sub expect_warning {
    my ($expectation) = @_;
    state $encountered;

    my ($package, $file, $line) = caller;
    $line++;

    $expectation =~ s/<LINE>/$line/g;
    $expectation =~ s/<FILE>/$file/g;

    if ($expectation eq -already) {
        fail '\...expected warning not issued' if !$encountered;
        return;
    }
    else {
        pass "Expecting: $expectation";
    }

    $encountered = 0;
    $SIG{__WARN__}
        = sub {
            my ($msg) = @_;
            chomp $msg;
            is $msg, $expectation => '\...expected warning issued';
            $encountered = 1;
        };
}

sub expect_no_warning {
    $SIG{__WARN__} = sub { my ($msg) = @_; fail "Unexpected warning: $msg"; }
}


BEGIN { expect_no_warning }
multi foo () {}

# comment
multi foo ($x) {}

# comment
multi foo ($x, $y) {}

# comment
multi bar () {}

BEGIN { expect_warning q{Isolated variant of multi foo() at <FILE> line <LINE>.} }
multi foo ($x, $y, $z) {}
BEGIN { expect_warning -already }

BEGIN { expect_warning q{Isolated variant of multi bar() at <FILE> line <LINE>.} }
multi bar ($x) {}
BEGIN { expect_warning -already }

{
    no warnings 'Multi::Dispatch::noncontiguous';

    BEGIN { expect_no_warning }
    multi foo (@x) {}
    multi bar (@x) {}
}


use Multi::Dispatch;

BEGIN { expect_no_warning }
multimethod mm () {}
multimethod mm ($x) {}

BEGIN { expect_warning q{Isolated variant of multimethod mm() at <FILE> line <LINE>.} }
multimethod mm ($x) {}
BEGIN { expect_warning -already }


done_testing();

