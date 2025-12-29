use Test::More;
use Number::Finance::Human;
use strict;

$\ = "\n"; $, = "\t";

# print to_human(10050000);
# print to_number("10.05M");
# print to_number("10.05B");
# print to_number("10.05Z");
# print to_number("10.05kg");
# print to_number("10.05Kg");

# print to_number("10%");


my $n = Number::Finance::Human->new("10.05k");


ok($n->to_number == 10050, "to number");
ok($n->to_human eq "10.05k", "to string");


ok( +$n == 10050, "to number overloaded");
ok("$n" eq "10.05k", "to string overloaded");

my $n = Number::Finance::Human->new(10);
my $p = Number::Finance::Human->new("20%");
ok($p->to_number == 0.2, "percentage");
ok($n->to_number == 10, "percentage");
ok(($n * "20%") == 2, "overloaded with string");
ok(Number::Finance::Human->new("10k") > 9000, "overloaded bigger than number");
ok("10k" > "9k", "overloaded bigger than stromgs");


done_testing();

__DATA__
ok($$n;

ok($n->to_number;
ok($n->to_human;

ok(Number::Finance::Human->new("20%")->to_number;

$n = Number::Finance::Human->new(1);

ok($n / "20%";

ok("20%" / $n;

$n++;

ok($n;

ok("10k" > "9k";

ok(Number::Finance::Human->new("10k") > 9000;

# ok("10k"->to_number;
# ok("10k"->to_human;

# print "10k"->to_nfh->to_string;


__DATA__

print $n * Number::Finance::Human->new("20%")->to_number;

print $n * "20%";

print "20%" * $n;

print "20k" + $n;
