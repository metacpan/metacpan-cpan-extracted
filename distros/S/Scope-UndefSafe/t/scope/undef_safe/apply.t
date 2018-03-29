use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Scope::UndefSafe qw/apply/;

sub apply_ok {
    my $value = shift;

    my $called = 0;
    my $result = apply {
        is $_, $value;
        $called++;
        undef;
    } $value;

    is $called, 1;
    is $result, $value;
}

subtest undef => sub {
    my $called = 0;
    my $result = apply { $called++ } undef;

    is $called, 0;
    is $result, undef;
};

subtest scalar => sub {
    apply_ok 0;
    apply_ok 1;
    apply_ok '';
    apply_ok 'a';
};

subtest ref => sub {
    apply_ok [];
    apply_ok {};
    apply_ok sub { };
    apply_ok qr//;
};

done_testing;
