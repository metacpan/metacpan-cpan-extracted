use v5.26;
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

sub _run_eval {
    my ($code) = @_;
    local $@;
    my $ret = eval $code;
    my $err = $@;
    return ($ret, $err);
}

describe 'Modern::Perl::Prelude optional -class/-defer imports' => sub {
    it 'compiles and runs class and defer via flag-style imports' => sub {
        my ($ret, $err) = _run_eval(<<'PERL');
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
            or diag $err;

        is($ret->[0], 5, 'class syntax works via -class');
        is($ret->[1], 'enter,leave,defer', 'defer syntax works via -defer');
    };

    it 'accepts no Modern::Perl::Prelude with -class and -defer options' => sub {
        my ($ok, $err) = _run_eval(<<'PERL');
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

        ok($ok, 'no Modern::Perl::Prelude accepts -class and -defer options')
            or diag $err;
    };
};

done_testing;
