#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
use Test::DataDriven tests => 3;

filters( { data     => [ qw(lines chomp) ],
           filtered => [ qw(lines chomp) ],
           } );

Test::DataDriven->run;

exit 0;

__DATA__

=== Normal filters in plugins
--- data my_filter
a
b
ccc
--- filtered
a my_filter
b my_filter
ccc my_filter

=== Normal filters in plugins (2)
--- data
a my_filter
b my_filter
ccc my_filter
--- filtered my_filter
a
b
ccc

=== Per-block/action filters
--- dataf
a
b
ccc
--- filtered
a my_filter
b my_filter
ccc my_filter

