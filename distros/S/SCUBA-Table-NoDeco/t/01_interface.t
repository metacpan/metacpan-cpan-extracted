#!/usr/bin/perl -w
use strict;
use Test::More tests => 10;

my @methods = qw(new list_tables clear table dive group surface 
                 max_time rnt max_depth max_table_depth);

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new();

isnt($sdt,undef,"SDT is defined");
isa_ok($sdt,"SCUBA::Table::NoDeco","Correct class");
can_ok($sdt,@methods);

ok(eq_set([SCUBA::Table::NoDeco->list_tables()], [qw(SSI PADI)]));

is($sdt->max_table_depth(units => "metres"),39,"Maximum SSI depth is 39 metres");
is($sdt->max_table_depth(units => "feet"), 130,"Maximum SSI depth is 130 feet");

my $padi = SCUBA::Table::NoDeco->new(table => "PADI");
isa_ok($padi,"SCUBA::Table::NoDeco");
is($padi->max_table_depth(units => "metres"),42,"Maximum SSI depth is 39 metres");
is($padi->max_table_depth(units => "feet"), 140,"Maximum SSI depth is 130 feet");
