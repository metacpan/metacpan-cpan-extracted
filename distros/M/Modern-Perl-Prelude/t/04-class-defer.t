use v5.30;
use strict;
use warnings;

use Test::More;

my $ret = eval <<'PERL';
    package Local::Prelude::Compat::Smoke;

    use Modern::Perl::Prelude qw(
        -class
        -defer
    );

    class Local::Prelude::Compat::Point {
        field $x :param = 0;
        field $y :param = 0;

        method sum {
            return $x + $y;
        }
    }

    my $sum = Local::Prelude::Compat::Point->new(
        x => 2,
        y => 3,
    )->sum;

    my @trace;
    {
        push @trace, 'enter';
        defer { push @trace, 'defer'; }
        push @trace, 'leave';
    }

    [
        $sum,
        join(',', @trace),
    ];
PERL

ok($ret, 'optional -class and -defer imports compile and run')
    or diag $@;

is($ret->[0], 5, 'class syntax works via -class');
is($ret->[1], 'enter,leave,defer', 'defer syntax works via -defer');

my $ok_no = eval <<'PERL';
    package Local::Prelude::Compat::No;

    use Modern::Perl::Prelude qw(
        -class
        -defer
    );

    no Modern::Perl::Prelude qw(
        -class
        -defer
    );

    1;
PERL

ok($ok_no, 'no Modern::Perl::Prelude accepts -class and -defer options')
    or diag $@;

done_testing;