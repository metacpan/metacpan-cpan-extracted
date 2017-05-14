use Test::More;
plan tests => 5;

use constant TOPIC => "test";
use constant URL   => "http://topicexchange.com/t/test/";

use_ok("Net::ITE");

my $ite = Net::ITE->new("Net::ITE.pm");
isa_ok($ite,"Net::ITE");

my $topic = $ite->topic(TOPIC);
isa_ok($topic,"Net::ITE::Topic");

cmp_ok($topic->url(),"eq",URL,$topic->url());

ok($topic->ping({title=>"Hello world",
		 url=>"http://www.aaronland.info/perl/net/ite",
		 "excerpt"=>"This is the network of our disconnect"}));
