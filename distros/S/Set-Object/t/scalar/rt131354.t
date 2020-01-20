# RT 131354, perl5.28 regression forgetting GMG
use 5.008;
use Set::Object qw/ set /;
use Test::More tests => 2;

my $a = set("a", "b", "c");
my $b = set();
#my @l = @$a; # using @l fixed the 5.28 bug
$added = $b->insert(@$a);
is($added, 3, "Set::Object->insert() [ returned # added ]");
is($b->size(), 3, "Set::Object->size() [ three members ]");
