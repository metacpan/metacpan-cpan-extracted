#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

#
#   simple import without options
#
is do {
    package TestPlainImport;
    use syntax qw( function );

    fun curry ($f, $n) {
        return fun ($m) { $f->($n, $m) };
    }

    curry(fun ($n, $m) { $n * $m }, 23)->(2);
}, 46, 'plain import';

#
#   import with simply identifier list argument
#
#is do {
#    package TestSimplyNamedImport;
#    use syntax function => [qw( f fun )];
#
#    fun double ($f) { $f->() * 3 }
#
#    double(f { 13 });
#}, 39, 'simply renamed import';

#
#   option map with single name
#
is_deeply do {
    package TestOptionMapName;
    use syntax function => { -as => 'f' };

    f kons ($n, $m) { f ($f) { $f->($n, $m) } }

    f kar ($k) { $k->(f ($n, $m) { $n }) }
    f kdr ($k) { $k->(f ($n, $m) { $m }) }

    my $k = kons(7, 8);
    [kar($k), kdr($k)];
}, [7, 8], 'option map with single name';

#
#   option map with multiple names
#
is do {
    package TestOptionMapManyNames;
    use syntax function => { -as => [qw( foo bar baz )] };

    foo add ($n, $m) { $n->() + $m->() }

    add(bar { 23 }, baz { 42 });
}, 65, 'option map with multiple names';

done_testing;
