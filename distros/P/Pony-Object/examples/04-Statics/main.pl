package main;
use Counter;

my $c1 = new Counter;
$c1->inc();             # 1
my $c2 = new Counter;
$c2->inc();             # 2
Counter->new->inc();    # 3
print $c1->get_count(); # 3
