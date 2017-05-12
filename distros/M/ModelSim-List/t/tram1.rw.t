#: tram1.rw.t
#: Working with ram.do.tt to check in simulation list
#:   outputs of ram.v
#: This file was generated from ram.pl.tt
#: ModelSim-List v0.04
#: Copyright (c) 2005 Agent Zhang.
#: 2005-07-03 2005-07-19

use strict;
#use warnings;

use Test::More tests => 179;
use ModelSim::List;

my $list = ModelSim::List->new;
my $dir = '.';
$dir = 't' if -d 't';
ok($list->parse("$dir/tram1.rw.lst"));

is($list->strobe('/ram/mfc', 0), 0, 'tram1.rw: line 6: w \'d1 \'habcd (@ 0 ~ 41)');
is($list->time_of('/ram/mfc', 1, 0, 41), 29, 'tram1.rw: line 6: w \'d1 \'habcd (@ 0 ~ 41)');
is($list->time_of('/ram/mfc', 0, 29, 41), 38, 'tram1.rw: line 6: w \'d1 \'habcd (@ 0 ~ 41)');

is($list->strobe('/ram/mfc', 41), 0, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
is($list->time_of('/ram/mfc', 1, 41, 96), 86, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
is($list->time_of('/ram/mfc', 0, 86, 96), 92, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
like($list->strobe('/ram/bus_data', 41), qr/^z+$/i, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 41, 96), 86, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 86, 96), 92, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');

is($list->strobe('/ram/mfc', 96), 0, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
is($list->time_of('/ram/mfc', 1, 96, 147), 123, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
is($list->time_of('/ram/mfc', 0, 123, 147), 134, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
like($list->strobe('/ram/bus_data', 96), qr/^z+$/i, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 96, 147), 123, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 123, 147), 134, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');

is($list->strobe('/ram/mfc', 147), 0, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
is($list->time_of('/ram/mfc', 1, 147, 210), 173, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
is($list->time_of('/ram/mfc', 0, 173, 210), 193, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
like($list->strobe('/ram/bus_data', 147), qr/^z+$/i, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 147, 210), 173, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 173, 210), 193, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');

is($list->strobe('/ram/mfc', 210), 0, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
is($list->time_of('/ram/mfc', 1, 210, 258), 251, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
is($list->time_of('/ram/mfc', 0, 251, 258), 257, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
like($list->strobe('/ram/bus_data', 210), qr/^z+$/i, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 210, 258), 251, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 251, 258), 257, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');

is($list->strobe('/ram/mfc', 258), 0, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
is($list->time_of('/ram/mfc', 1, 258, 323), 294, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
is($list->time_of('/ram/mfc', 0, 294, 323), 303, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
like($list->strobe('/ram/bus_data', 258), qr/^z+$/i, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
is($list->time_of('/ram/bus_data', qr/^x+$/i, 258, 323), 294, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 294, 323), 303, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');

is($list->strobe('/ram/mfc', 323), 0, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
is($list->time_of('/ram/mfc', 1, 323, 369), 354, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
is($list->time_of('/ram/mfc', 0, 354, 369), 359, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
like($list->strobe('/ram/bus_data', 323), qr/^z+$/i, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
is($list->time_of('/ram/bus_data', qr/^x+$/i, 323, 369), 354, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 354, 369), 359, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');

is($list->strobe('/ram/mfc', 369), 0, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
is($list->time_of('/ram/mfc', 1, 369, 430), 413, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
is($list->time_of('/ram/mfc', 0, 413, 430), 428, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
like($list->strobe('/ram/bus_data', 369), qr/^z+$/i, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
is($list->time_of('/ram/bus_data', qr/^x+$/i, 369, 430), 413, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 413, 430), 428, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');

is($list->strobe('/ram/mfc', 430), 0, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
is($list->time_of('/ram/mfc', 1, 430, 487), 473, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
is($list->time_of('/ram/mfc', 0, 473, 487), 485, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
like($list->strobe('/ram/bus_data', 430), qr/^z+$/i, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
is($list->time_of('/ram/bus_data', qr/^x+$/i, 430, 487), 473, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 473, 487), 485, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');

ok(!defined $list->time_of('/ram/mfc', 1, 487, 544), 'tram1.rw: line 15: r \'d16 !z+ (@ 487 ~ 544)');ok(!defined $list->time_of('/ram/bus_data', qr/[^z]/, 487, 544), 'tram1.rw: line 15: r \'d16 !z+ (@ 487 ~ 544)');

is($list->strobe('/ram/mfc', 544), 0, 'tram1.rw: line 17: w \'d5 \'hfffffffe (@ 544 ~ 600)');
is($list->time_of('/ram/mfc', 1, 544, 600), 576, 'tram1.rw: line 17: w \'d5 \'hfffffffe (@ 544 ~ 600)');
is($list->time_of('/ram/mfc', 0, 576, 600), 580, 'tram1.rw: line 17: w \'d5 \'hfffffffe (@ 544 ~ 600)');

is($list->strobe('/ram/mfc', 600), 0, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
is($list->time_of('/ram/mfc', 1, 600, 666), 632, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
is($list->time_of('/ram/mfc', 0, 632, 666), 648, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
like($list->strobe('/ram/bus_data', 600), qr/^z+$/i, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
is($list->time_of('/ram/bus_data', qr/^f+e$/i, 600, 666), 632, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 632, 666), 648, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');

is($list->strobe('/ram/mfc', 666), 0, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
is($list->time_of('/ram/mfc', 1, 666, 706), 689, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
is($list->time_of('/ram/mfc', 0, 689, 706), 697, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
like($list->strobe('/ram/bus_data', 666), qr/^z+$/i, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
is($list->time_of('/ram/bus_data', qr/^f+e$/i, 666, 706), 689, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 689, 706), 697, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');

is($list->strobe('/ram/mfc', 706), 0, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
is($list->time_of('/ram/mfc', 1, 706, 739), 731, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
is($list->time_of('/ram/mfc', 0, 731, 739), 738, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
like($list->strobe('/ram/bus_data', 706), qr/^z+$/i, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
is($list->time_of('/ram/bus_data', qr/^f+e$/i, 706, 739), 731, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 731, 739), 738, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');

is($list->strobe('/ram/mfc', 739), 0, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
is($list->time_of('/ram/mfc', 1, 739, 797), 785, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
is($list->time_of('/ram/mfc', 0, 785, 797), 794, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
like($list->strobe('/ram/bus_data', 739), qr/^z+$/i, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
is($list->time_of('/ram/bus_data', qr/^f+e$/i, 739, 797), 785, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 785, 797), 794, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');

is($list->strobe('/ram/mfc', 797), 0, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
is($list->time_of('/ram/mfc', 1, 797, 839), 823, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
is($list->time_of('/ram/mfc', 0, 823, 839), 830, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
like($list->strobe('/ram/bus_data', 797), qr/^z+$/i, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 797, 839), 823, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
is($list->time_of('/ram/bus_data', qr/^z+$/i, 823, 839), 830, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');

ok(!defined $list->time_of('/ram/mfc', 1, 839, 893), 'tram1.rw: line 24: w \'d8 !\'b101 (@ 839 ~ 893)');

ok(!defined $list->time_of('/ram/mfc', 1, 893, 943), 'tram1.rw: line 25: r \'d8 !z+ (@ 893 ~ 943)');ok(!defined $list->time_of('/ram/bus_data', qr/[^z]/, 893, 943), 'tram1.rw: line 25: r \'d8 !z+ (@ 893 ~ 943)');

#TODO:
{
    #local $TODO = 'Support for non-event list format is left to Sal++';
    $list->parse("$dir/tram1.rw.lst~");

    is($list->strobe('/ram/mfc', 0), 0, 'tram1.rw: line 6: w \'d1 \'habcd (@ 0 ~ 41)');
    is($list->time_of('/ram/mfc', 1, 0, 41), 29, 'tram1.rw: line 6: w \'d1 \'habcd (@ 0 ~ 41)');
    is($list->time_of('/ram/mfc', 0, 29, 41), 38, 'tram1.rw: line 6: w \'d1 \'habcd (@ 0 ~ 41)');

    is($list->strobe('/ram/mfc', 41), 0, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
    is($list->time_of('/ram/mfc', 1, 41, 96), 86, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
    is($list->time_of('/ram/mfc', 0, 86, 96), 92, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
    like($list->strobe('/ram/bus_data', 41), qr/^z+$/i, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
    is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 41, 96), 86, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 86, 96), 92, 'tram1.rw: line 7: r \'d0 0*abcd (@ 41 ~ 96)');

    is($list->strobe('/ram/mfc', 96), 0, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
    is($list->time_of('/ram/mfc', 1, 96, 147), 123, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
    is($list->time_of('/ram/mfc', 0, 123, 147), 134, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
    like($list->strobe('/ram/bus_data', 96), qr/^z+$/i, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
    is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 96, 147), 123, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 123, 147), 134, 'tram1.rw: line 8: r \'d1 0*abcd (@ 96 ~ 147)');

    is($list->strobe('/ram/mfc', 147), 0, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
    is($list->time_of('/ram/mfc', 1, 147, 210), 173, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
    is($list->time_of('/ram/mfc', 0, 173, 210), 193, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
    like($list->strobe('/ram/bus_data', 147), qr/^z+$/i, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
    is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 147, 210), 173, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 173, 210), 193, 'tram1.rw: line 9: r \'d2 0*abcd (@ 147 ~ 210)');

    is($list->strobe('/ram/mfc', 210), 0, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
    is($list->time_of('/ram/mfc', 1, 210, 258), 251, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
    is($list->time_of('/ram/mfc', 0, 251, 258), 257, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
    like($list->strobe('/ram/bus_data', 210), qr/^z+$/i, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
    is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 210, 258), 251, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 251, 258), 257, 'tram1.rw: line 10: r \'d3 0*abcd (@ 210 ~ 258)');

    is($list->strobe('/ram/mfc', 258), 0, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
    is($list->time_of('/ram/mfc', 1, 258, 323), 294, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
    is($list->time_of('/ram/mfc', 0, 294, 323), 303, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
    like($list->strobe('/ram/bus_data', 258), qr/^z+$/i, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
    is($list->time_of('/ram/bus_data', qr/^x+$/i, 258, 323), 294, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 294, 323), 303, 'tram1.rw: line 11: r \'d4 x+ (@ 258 ~ 323)');

    is($list->strobe('/ram/mfc', 323), 0, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
    is($list->time_of('/ram/mfc', 1, 323, 369), 354, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
    is($list->time_of('/ram/mfc', 0, 354, 369), 359, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
    like($list->strobe('/ram/bus_data', 323), qr/^z+$/i, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
    is($list->time_of('/ram/bus_data', qr/^x+$/i, 323, 369), 354, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 354, 369), 359, 'tram1.rw: line 12: r \'d5 x+ (@ 323 ~ 369)');

    is($list->strobe('/ram/mfc', 369), 0, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
    is($list->time_of('/ram/mfc', 1, 369, 430), 413, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
    is($list->time_of('/ram/mfc', 0, 413, 430), 428, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
    like($list->strobe('/ram/bus_data', 369), qr/^z+$/i, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
    is($list->time_of('/ram/bus_data', qr/^x+$/i, 369, 430), 413, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 413, 430), 428, 'tram1.rw: line 13: r \'d6 x+ (@ 369 ~ 430)');

    is($list->strobe('/ram/mfc', 430), 0, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
    is($list->time_of('/ram/mfc', 1, 430, 487), 473, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
    is($list->time_of('/ram/mfc', 0, 473, 487), 485, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
    like($list->strobe('/ram/bus_data', 430), qr/^z+$/i, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
    is($list->time_of('/ram/bus_data', qr/^x+$/i, 430, 487), 473, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 473, 487), 485, 'tram1.rw: line 14: r \'d7 x+ (@ 430 ~ 487)');

    ok(!defined $list->time_of('/ram/mfc', 1, 487, 544), 'tram1.rw: line 15: r \'d16 !z+ (@ 487 ~ 544)');ok(!defined $list->time_of('/ram/bus_data', qr/[^z]/, 487, 544), 'tram1.rw: line 15: r \'d16 !z+ (@ 487 ~ 544)');

    is($list->strobe('/ram/mfc', 544), 0, 'tram1.rw: line 17: w \'d5 \'hfffffffe (@ 544 ~ 600)');
    is($list->time_of('/ram/mfc', 1, 544, 600), 576, 'tram1.rw: line 17: w \'d5 \'hfffffffe (@ 544 ~ 600)');
    is($list->time_of('/ram/mfc', 0, 576, 600), 580, 'tram1.rw: line 17: w \'d5 \'hfffffffe (@ 544 ~ 600)');

    is($list->strobe('/ram/mfc', 600), 0, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
    is($list->time_of('/ram/mfc', 1, 600, 666), 632, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
    is($list->time_of('/ram/mfc', 0, 632, 666), 648, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
    like($list->strobe('/ram/bus_data', 600), qr/^z+$/i, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
    is($list->time_of('/ram/bus_data', qr/^f+e$/i, 600, 666), 632, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 632, 666), 648, 'tram1.rw: line 18: r \'d4 f+e (@ 600 ~ 666)');

    is($list->strobe('/ram/mfc', 666), 0, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
    is($list->time_of('/ram/mfc', 1, 666, 706), 689, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
    is($list->time_of('/ram/mfc', 0, 689, 706), 697, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
    like($list->strobe('/ram/bus_data', 666), qr/^z+$/i, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
    is($list->time_of('/ram/bus_data', qr/^f+e$/i, 666, 706), 689, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 689, 706), 697, 'tram1.rw: line 19: r \'d5 f+e (@ 666 ~ 706)');

    is($list->strobe('/ram/mfc', 706), 0, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
    is($list->time_of('/ram/mfc', 1, 706, 739), 731, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
    is($list->time_of('/ram/mfc', 0, 731, 739), 738, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
    like($list->strobe('/ram/bus_data', 706), qr/^z+$/i, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
    is($list->time_of('/ram/bus_data', qr/^f+e$/i, 706, 739), 731, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 731, 739), 738, 'tram1.rw: line 20: r \'d6 f+e (@ 706 ~ 739)');

    is($list->strobe('/ram/mfc', 739), 0, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
    is($list->time_of('/ram/mfc', 1, 739, 797), 785, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
    is($list->time_of('/ram/mfc', 0, 785, 797), 794, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
    like($list->strobe('/ram/bus_data', 739), qr/^z+$/i, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
    is($list->time_of('/ram/bus_data', qr/^f+e$/i, 739, 797), 785, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 785, 797), 794, 'tram1.rw: line 21: r \'d7 f+e (@ 739 ~ 797)');

    is($list->strobe('/ram/mfc', 797), 0, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
    is($list->time_of('/ram/mfc', 1, 797, 839), 823, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
    is($list->time_of('/ram/mfc', 0, 823, 839), 830, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
    like($list->strobe('/ram/bus_data', 797), qr/^z+$/i, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
    is($list->time_of('/ram/bus_data', qr/^0*abcd$/i, 797, 839), 823, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');
    is($list->time_of('/ram/bus_data', qr/^z+$/i, 823, 839), 830, 'tram1.rw: line 22: r \'d3 0*abcd (@ 797 ~ 839)');

    ok(!defined $list->time_of('/ram/mfc', 1, 839, 893), 'tram1.rw: line 24: w \'d8 !\'b101 (@ 839 ~ 893)');

    ok(!defined $list->time_of('/ram/mfc', 1, 893, 943), 'tram1.rw: line 25: r \'d8 !z+ (@ 893 ~ 943)');ok(!defined $list->time_of('/ram/bus_data', qr/[^z]/, 893, 943), 'tram1.rw: line 25: r \'d8 !z+ (@ 893 ~ 943)');
}
