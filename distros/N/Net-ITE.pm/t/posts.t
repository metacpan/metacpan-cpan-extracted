use Test::More;
plan tests => 7;

use constant TOPIC => "test";
use constant URL   => "http://topicexchange.com/t/test/";

use_ok("Net::ITE");

my $ite = Net::ITE->new();
isa_ok($ite,"Net::ITE");

my $topic = $ite->topic(TOPIC);
isa_ok($topic,"Net::ITE::Topic");

cmp_ok($topic->url(),"eq",URL,$topic->url());

my $posts = $topic->posts();
isa_ok($posts,"Net::ITE::Iterator");

ok($posts->count(),$posts->count()." post(s)");

while (my $item = $posts->next()) {
      print $item->title()."\n";
      print $item->excerpt()."\n";
}

ok(1);
