use strict;
use warnings;
use Test::More;
use Panda::URI qw/uri :const/;

plan skip_all => 'JSON::XS required for this test' unless eval { require JSON::XS; 1};

my $json = JSON::XS->new->utf8->convert_blessed;

my $uri = new Panda::URI;
$uri->scheme('https');
$uri->host('crazypanda.ru');
$uri->path('nonexistent');
$uri->query({a => 1, b => 2});
$uri->hash('jopa');

my $serialized = $json->encode({uri => $uri});
is($serialized, '{"uri":"https://crazypanda.ru/nonexistent?a=1&b=2#jopa"}');

done_testing();
