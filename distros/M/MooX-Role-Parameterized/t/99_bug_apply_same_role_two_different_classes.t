#!perl

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use lib 't/lib';
use TheClass;
use TheOtherClass;

use Test::More;
subtest(
    'test attr added by role block' => sub {
        can_ok( 'TheClass',      'foo' );    # succeeds
        can_ok( 'TheClass',      'bar' );    # should works
        can_ok( 'TheOtherClass', 'bam' );    # fails
    }
);

subtest(
    'test normal attr' => sub {
        can_ok( 'TheClass',      'xoxo' );    # should works
        can_ok( 'TheOtherClass', 'xoxo' );    # fails
    }
);

subtest(
    'test methods added by role block' => sub {
        can_ok( 'TheClass',      'xxx' );     # succeeds
        can_ok( 'TheClass',      'yyy' );     # should works
        can_ok( 'TheOtherClass', 'zzz' );     # fails
    }
);

subtest(
    'check objects' => sub {
        my $a = TheClass->new( foo => 1, bar => 2, xoxo => 5 );
        my $b = TheOtherClass->new( bam => 3, xoxo => 6 );

        is $a->foo,  1,       'TheClass attr foo should be 1';
        is $a->bar,  2,       'TheClass attr bar should be 2';
        is $a->xoxo, 5,       'TheClass attr xoxo should be 5';
        is $a->xxx,  'dummy', 'TheClass method xxx should return "dummy"';
        is $a->yyy,  'dummy', 'TheClass method yyy should return "dummy"';

        is $b->bam,  3,       'TheOtherClass attr bam should be 3';
        is $b->xoxo, 6,       'TheOtherClass attr xoxo should be 6';
        is $b->zzz,  'dummy', 'TheOtherClass method zzz should return "dummy"';
    }
);

done_testing;
