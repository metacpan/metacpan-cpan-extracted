use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;

use t::Util;
use Scope::UndefSafe qw/let/;

sub let_ok {
    my $value = shift;

    my $called   = 0;
    my $expected = Test::MockObject->new;
    my $actual   = let {
        is $_, $value;
        $called++;
        $expected;
    } $value;

    is $called, 1;
    is $actual, $expected;
}

subtest undef => sub {
    my $called = 0;
    my $actual = let { $called++ } undef;

    is $called, 0;
    is $actual, undef;
};

subtest scalar => sub {
    let_ok 0;
    let_ok 1;
    let_ok '';
    let_ok 'a';
};

subtest ref => sub {
    let_ok [];
    let_ok {};
    let_ok sub { };
    let_ok qr//;
};

done_testing;
