#: ModelSim-List.t
#: Test script for the ModelSim::List class
#: ModelSim-List v0.04
#: Copyright (C) 2005 by Agent Zhang.
#: 2005-07-02 2005-07-19

use strict;
#use warnings;

use Test::More tests => 108;
use ModelSim::List;

my $dir;
if (-d 't') {
    $dir = 't';
} else {
    $dir = '.';
}

my $list = ModelSim::List->new;
ok($list);
is(ref($list), 'ModelSim::List');

is($list->parse("$dir/ram_lst/ram_4.lst"), 1);

ok(!defined $list->strobe('/ram/mfc', -0.9));
is($list->strobe('/ram/mfc', 0), 0);
is($list->strobe('/ram/mfc', 0.5), 0);
is($list->strobe('/ram/mfc', 1), 0);
is($list->strobe('/ram/mfc', 1.8), 0);
is($list->strobe('/ram/mfc', 3), 0);
is($list->strobe('/ram/mfc', 5.6), 0);
is($list->strobe('/ram/mfc', 8.4), 0);
is($list->strobe('/ram/mfc', 10.1), 0);
is($list->strobe('/ram/mfc', 10), 0);
is($list->strobe('/ram/mfc', 12.9), 0);
is($list->strobe('/ram/mfc', 13), 1);
is($list->strobe('/ram/mfc', 13.1), 1);
is($list->strobe('/ram/mfc', 14.8), 1);
is($list->strobe('/ram/mfc', 15), 0);
is($list->strobe('/ram/mfc', 16), 0);
is($list->strobe('/ram/mfc', 20), 0);
is($list->strobe('/ram/mfc', 100), 0);

is($list->time_of('/ram/mfc', 1), 13);
is($list->time_of('/ram/mfc', 1, 0), 13);
is($list->time_of('/ram/mfc', 1, 5), 13);
is($list->time_of('/ram/mfc', 1, 12), 13);
is($list->time_of('/ram/mfc', 1, 12.9), 13);
ok(!defined $list->time_of('/ram/mfc', 1, 0, 12.9));
is($list->time_of('/ram/mfc', 1, 0, 13), 13);
is($list->time_of('/ram/mfc', 1, 0, 14), 13);
is($list->time_of('/ram/mfc', 1, 13), 13);
is($list->time_of('/ram/mfc', 1, 13.1), 13.1);
is($list->time_of('/ram/mfc', 1, 15), 33);
is($list->time_of('/ram/mfc', 0, 5, 2), undef);

is($list->time_of('/ram/mfc', 0), 0);
is($list->time_of('/ram/mfc', 0, 1), 1);
is($list->time_of('/ram/mfc', 0, 8), 8);
is($list->time_of('/ram/mfc', 0, 13), 15);
is($list->time_of('/ram/mfc', 0, 14), 15);
is($list->time_of('/ram/mfc', 0, 15), 15);
is($list->time_of('/ram/mfc', 0, 16), 16);

ok(!defined $list->strobe('/ram/bus_data', -2));
is($list->strobe('/ram/bus_data', 0), 'zzzzzzzz');
is($list->strobe('/ram/bus_data', 0.9), 'zzzzzzzz');
is($list->time_of('/ram/bus_data', qr/^z+$/i), 0);
is($list->strobe('/ram/bus_data', 1), '0000ffff');
is($list->time_of('/ram/bus_data', qr/^0+f+$/i), 1);
is($list->strobe('/ram/bus_data', 2), '0000ffff');
is($list->strobe('/ram/bus_data', 3), '0000ffff');
is($list->strobe('/ram/bus_data', 7), '0000ffff');
is($list->strobe('/ram/bus_data', 12), '0000ffff');
is($list->strobe('/ram/bus_data', 19), '0000ffff');
is($list->strobe('/ram/bus_data', 20), 'zzzzzzzz');
is($list->strobe('/ram/bus_data', 21), '0000abcd');

ok(!defined $list->strobe('/ram/bus_rw', -1));
is($list->strobe('/ram/bus_rw', 0), 'HiZ');
is($list->strobe('/ram/bus_rw', 0.9), 'HiZ');
is($list->strobe('/ram/bus_rw', 1), 'St0');

is($list->parse("$dir/tram1.rw.lst"), 1);
ok(!defined $list->time_of('/ram/bus_data', qr/^x+$/i, 882, 941));

#TODO:
{
    #local $TODO = 'Support for non-event list format is left to Sal++';
    is($list->parse("$dir/_ram_lst/ram_4.lst"), 1);
    ok(!defined $list->strobe('/ram/mfc', -0.9));
    is($list->strobe('/ram/mfc', 0), 0);
    is($list->strobe('/ram/mfc', 0.5), 0);
    is($list->strobe('/ram/mfc', 1), 0);
    is($list->strobe('/ram/mfc', 1.8), 0);
    is($list->strobe('/ram/mfc', 3), 0);
    is($list->strobe('/ram/mfc', 5.6), 0);
    is($list->strobe('/ram/mfc', 8.4), 0);
    is($list->strobe('/ram/mfc', 10.1), 0);
    is($list->strobe('/ram/mfc', 10), 0);
    is($list->strobe('/ram/mfc', 12.9), 0);
    is($list->strobe('/ram/mfc', 13), 1);
    is($list->strobe('/ram/mfc', 13.1), 1);
    is($list->strobe('/ram/mfc', 14.8), 1);
    is($list->strobe('/ram/mfc', 15), 0);
    is($list->strobe('/ram/mfc', 16), 0);
    is($list->strobe('/ram/mfc', 20), 0);
    is($list->strobe('/ram/mfc', 100), 0);

    is($list->time_of('/ram/mfc', 1), 13);
    is($list->time_of('/ram/mfc', 1, 0), 13);
    is($list->time_of('/ram/mfc', 1, 5), 13);
    is($list->time_of('/ram/mfc', 1, 12), 13);
    is($list->time_of('/ram/mfc', 1, 12.9), 13);
    is($list->time_of('/ram/mfc', 1, 13), 13);
    is($list->time_of('/ram/mfc', 1, 13.1), 13.1);
    is($list->time_of('/ram/mfc', 1, 15), 33);

    is($list->time_of('/ram/mfc', 0), 0);
    is($list->time_of('/ram/mfc', 0, 1), 1);
    is($list->time_of('/ram/mfc', 0, 8), 8);
    is($list->time_of('/ram/mfc', 0, 13), 15);
    is($list->time_of('/ram/mfc', 0, 14), 15);
    is($list->time_of('/ram/mfc', 0, 15), 15);
    is($list->time_of('/ram/mfc', 0, 16), 16);

    ok(!defined $list->strobe('/ram/bus_data', -2));
    is($list->strobe('/ram/bus_data', 0), 'zzzzzzzz');
    is($list->strobe('/ram/bus_data', 0.9), 'zzzzzzzz');
    is($list->strobe('/ram/bus_data', 1), '0000ffff');
    is($list->strobe('/ram/bus_data', 2), '0000ffff');
    is($list->strobe('/ram/bus_data', 3), '0000ffff');
    is($list->strobe('/ram/bus_data', 7), '0000ffff');
    is($list->strobe('/ram/bus_data', 12), '0000ffff');
    is($list->strobe('/ram/bus_data', 19), '0000ffff');
    is($list->strobe('/ram/bus_data', 20), 'zzzzzzzz');
    is($list->strobe('/ram/bus_data', 21), '0000abcd');

    ok(!defined $list->strobe('/ram/bus_rw', -1));
    is($list->strobe('/ram/bus_rw', 0), 'HiZ');
    is($list->strobe('/ram/bus_rw', 0.9), 'HiZ');
    is($list->strobe('/ram/bus_rw', 1), 'St0');
};
