use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://xkcd.com/927/');
my $dom = $t->tx->res->dom->at('img');
is $dom->{src},     '//imgs.xkcd.com/comics/standards.png', 'correct src';
is $dom->{alt},     'Standards',                            'correct alt value (page title)';
like $dom->{title}, qr/\Qmini-USB/,                         'hover text (image title)';

$t->get_ok('/embed.json?url=http://xkcd.com/927/')->json_is('/media_id', '927');

done_testing;
