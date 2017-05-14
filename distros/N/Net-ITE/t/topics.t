use Test::More;
plan tests => 5;

use_ok("Net::ITE");

my $ite = Net::ITE->new();
isa_ok($ite,"Net::ITE");

my @list = $ite->topics(TOPIC);

my $count = scalar(@list);
ok($count,"$count topic(s)");

my $topic = $list[rand($count -1)];
isa_ok($topic,"Net::ITE::Topic");

ok($topic->title(),$topic->title());
