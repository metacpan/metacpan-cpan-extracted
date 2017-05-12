use Test::More tests => 3;

BEGIN { use_ok('Osgood::Client'); }

my $client = Osgood::Client->new;
isa_ok($client, 'Osgood::Client', 'isa Osgood::Client');

my $client2 = Osgood::Client->new(url => 'http://foo.bar.com');
isa_ok($client2->url, 'URI');
