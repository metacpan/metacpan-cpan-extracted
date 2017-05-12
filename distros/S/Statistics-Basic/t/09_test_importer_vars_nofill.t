
use t::locale_hack;
use Test;
use Statistics::Basic qw(:all nofill);

plan tests => 1;

my $vector = vector()->set_size(10);
ok($vector->query_size, 0);
