
use Test::More tests => 1;
use Set::Object qw(weak_set);

my $n = 1;
my $a = \$n;
my $set1 = weak_set();
$set1->insert($a);

pass;
