use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://imgur.com/2lXFJK0');
my $dom = $t->tx->res->dom->at('img');
like $dom->{src}, qr{http://i\.imgur\.com/2lXFJK0\.png}, 'correct src';
like $dom->{alt}, qr/\QYay Mojo!/, 'correct title';

$t->get_ok('/embed.json?url=http://imgur.com/2lXFJK0')->json_is('/media_id', '2lXFJK0');

done_testing;
