use Test::More 'no_plan';
use Perl6::Builtins;

sub to {
    is scalar(caller), 'main'       => 'Scalar context';

    my @list = caller;

    ok @list == 3                   => 'List context count';
    is $list[0], 'main'             => 'List context package';
    is $list[1], $0                 => 'List context file';
    is $list[2], 999                => 'List context line';

    @list = caller 0;

    ok @list == 10                  => 'List context count';
    is $list[0], 'main'             => 'List context package';
    is $list[1], $0                 => 'List context file';
    is $list[2], 999                => 'List context line';
    is $list[3], 'main::to'         => 'List context subroutine';
    is $list[4], 1                  => 'List context hasargs';
    ok !defined $list[5]            => 'List context wantarray';
    ok !defined $list[6]            => 'List context evaltext';
    ok !defined $list[7]            => 'List context is_require';

    is keys %{caller()}, 10            => 'Hashref count';
    is caller(0)->{package}, 'main'    => 'Hashref context package';
    is caller(0)->{file}, $0           => 'Hashref context file';
    is caller(0)->{line}, 999          => 'Hashref context line';
    is caller(0)->{sub}, 'main::to'    => 'Hashref context subroutine';
    is caller(0)->{args}, 1            => 'Hashref context hasargs';
    ok !defined caller(0)->{want}      => 'Hashref context wantarray';
    ok !defined caller(0)->{eval}      => 'Hashref context evaltext';
    ok !defined caller(0)->{require}   => 'Hashref context is_require';
}

sub from {
# line 999
    to();
}

from();
