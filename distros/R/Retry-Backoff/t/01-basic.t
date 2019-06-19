#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Retry::Backoff 'retry';

subtest basic => sub {
    my $n = 0;
    retry { $n++ < 1 and die } initial_delay=>0.1;
    is($n, 2);
};

subtest "return values" => sub {
    subtest "success, !wantarray" => sub {
        my $n = 0;
        my $res = retry { $n++ < 1 and die; ("X","Y","Z") } initial_delay=>0.1;
        is($n, 2);
        is($res, "Z");
    };
    subtest "success, wantarray" => sub {
        my $n = 0;
        my @res = retry { $n++ < 1 and die; ("X","Y","Z") } initial_delay=>0.1;
        is($n, 2);
        is_deeply(\@res, ["X","Y","Z"]);
    };
    subtest "failure, !wantarray" => sub {
        my $n = 0;
        my $res = retry { $n++ < 1 and die; ("X","Y","Z") } initial_delay=>0.1, max_attempts=>1;
        is($n, 1);
        is_deeply($res, undef);
    };
    subtest "failure, !wantarray" => sub {
        my $n = 0;
        my @res = retry { $n++ < 1 and die; ("X","Y","Z") } initial_delay=>0.1, max_attempts=>1;
        is($n, 1);
        is_deeply(\@res, []);
    };
};

subtest "param:strategy" => sub {
    my $n = 0;
    retry { $n++ < 1 and die } strategy=>'Constant', delay=>0.1;
    is($n, 2);
};

subtest "param:retry_if" => sub {
    my $n = 0;
    retry { } initial_delay=>0.1, retry_if => sub { $n++ < 1 };
    is($n, 2);
};

subtest "param:on_success" => sub {
    my $n = 0;
    retry { $n++ < 1 and die } initial_delay=>0.1, on_success => sub { $n = 10 };
    is($n, 10);
};

subtest "param:on_failure" => sub {
    my $n = 0;
    my $m = 0;
    retry { $n++ < 1 and die } initial_delay=>0.1, on_failure => sub { $m++ };
    is($n, 2);
    is($m, 1);
};

#XXX
#subtest "param:non_blocking" => sub {
#};

done_testing;
