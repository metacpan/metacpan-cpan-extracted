#!/usr/bin/perl

use strict;
use warnings;

use Number::Continuation qw(continuation);
use Test::More tests => 8;

my %expected = (
    'scalar' => '1-3, 6-7, 10-12, 14',
    'list'   => [ [1,2,3], [6,7], [10,11,12], [14] ],
);

{
    my $contin = continuation();
    is($contin, '', 'empty set: scalar context');

    my @contin = continuation();
    is_deeply(\@contin, [], 'empty set: list context');
}
{
    my $set = '1 2 3 6 7 10 11 12 14';

    my $contin = continuation($set);
    is($contin, $expected{'scalar'}, 'string set: scalar context');

    my @contin = continuation($set);
    is_deeply(\@contin, $expected{'list'}, 'string set: list context');
}
{
    my @set = (1,2,3,6,7,10,11,12,14);

    my $contin = continuation(@set);
    is($contin, $expected{'scalar'}, 'array set: scalar context');

    my @contin = continuation(@set);
    is_deeply(\@contin, $expected{'list'}, 'array set: list context');
}
{
    my @set = (1,2,3,6,7,10,11,12,14);

    my $contin = continuation(\@set);
    is($contin, $expected{'scalar'}, 'array reference set: scalar context');

    my @contin = continuation(\@set);
    is_deeply(\@contin, $expected{'list'}, 'array reference set: list context');
}
