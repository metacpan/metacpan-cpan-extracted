#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Access::Lite;
use Test::More 0.98;

my $pa = Perinci::Access::Lite->new;

subtest "local (pl)" => sub {
    test_riap(
        name   => 'call non-existing entity',
        action => 'call',
        uri    => '/Some/NonExisting/Entity',
        status => 500,
    );
    test_riap(
        name   => 'call func',
        action => 'call',
        uri    => '/Perinci/Examples/gen_array',
        extras => {args=>{len=>1}},
        result => [1],
    );
    test_riap(
        name   => 'call pkg',
        action => 'call',
        uri    => '/Perinci/Examples/',
        status => 501,
    );
    test_riap(
        name   => 'meta func',
        action => 'meta',
        uri    => '/Perinci/Examples/gen_array',
        # XXX test meta result and whether it's normalized and whether args_as/result_naked is modified and their orig also returned in _orig_*
    );
    test_riap(
        name   => 'meta pkg',
        action => 'meta',
        uri    => '/Perinci/Examples/',
        # XXX test meta result and whether it's normalized and whether args_as/result_naked is modified and their orig also returned in _orig_*
    );
    test_riap(
        name   => 'list func',
        action => 'list',
        uri    => '/Perinci/Examples/gen_array',
        status => 501,
    );
    test_riap(
        name   => 'list pkg',
        action => 'list',
        uri    => '/Perinci/Examples/Tx/',
        result => ['check_state'],
    );
};

# XXX test http (needs HTTP::Tiny)
# XXX test http over unix socket (needs HTTP::Tiny::Unix)
# XXX test progress (needs Progres::Any)

done_testing;

sub test_riap {
    my %args = @_;

    subtest $args{name} => sub {
        my $res = $pa->request($args{action}, $args{uri}, $args{extras} // {});
        my $exp_st = $args{status} // 200;
        is($res->[0], $exp_st, "status") or return;
        if (exists $args{envres}) {
            is_deeply($res, $args{envres}, 'envres')
                or diag explain $res;
        }
        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}, 'result')
                or diag explain $res;
        }
    };
}
