#!perl -T
use strict;
use Test::More;


my $base_oid = ".1.3.6.1.4.1.32272";
my @cases = (
    [ "$base_oid.1.1", "$base_oid.1.1",  0 ],
    [ "$base_oid.1.1", "$base_oid.1.2", -1 ],
    [ "$base_oid.1.2", "$base_oid.1.1",  1 ],
    [ "$base_oid.1.1", "$base_oid.2.1", -1 ],
    [ "$base_oid.2.1", "$base_oid.1.1",  1 ],
);

plan tests => 1 + 2 * @cases;

use_ok("SNMP::ToolBox");

for my $case (@cases) {
    my ($a, $b, $v) = @$case;
    my $r = eval { by_oid($a, $b) };
    is($@, "", "by_oid('$a', '$b')");
    is($r, $v);
}

