use strict;
use warnings;
use Test::More;
use Panda::URI qw/:const/;

my ($uri, $leading);

$uri = Panda::URI->new('http://ya.ru:2345/my/path?p1=v1&p2=v2#myhash');

$uri->scheme('https');
is($uri->scheme, 'https');
is($uri, 'https://ya.ru:2345/my/path?p1=v1&p2=v2#myhash');

$uri->scheme('');
is($uri->scheme, '');
is($uri, '//ya.ru:2345/my/path?p1=v1&p2=v2#myhash');

$uri->host('jopa.com');
is($uri->host, 'jopa.com');
is($uri, '//jopa.com:2345/my/path?p1=v1&p2=v2#myhash');

$uri->scheme('https');
$uri->port(1000);
is($uri->explicit_port, 1000);
is($uri->port, 1000);
is($uri, 'https://jopa.com:1000/my/path?p1=v1&p2=v2#myhash');

$uri->port(0);
is($uri->explicit_port, 0);
is($uri->port, 443);
is($uri, 'https://jopa.com/my/path?p1=v1&p2=v2#myhash');

$uri->path('/new/path/nah/');
is($uri->path, '/new/path/nah/');
is($uri, 'https://jopa.com/new/path/nah/?p1=v1&p2=v2#myhash');

$uri->path('');
is($uri->path, '');
is($uri, 'https://jopa.com?p1=v1&p2=v2#myhash');

$uri->query_string('mama=papa&jopa=popa');
is($uri->query_string, "mama=papa&jopa=popa");
is($uri, 'https://jopa.com?mama=papa&jopa=popa#myhash');

$uri->query_string("");
is($uri->query_string, "");
is($uri, 'https://jopa.com#myhash');

$uri->fragment('suka-sosi-her');
is($uri->fragment, 'suka-sosi-her');
is($uri, 'https://jopa.com#suka-sosi-her');

$uri->fragment("");
is($uri->fragment, "");
is($uri, 'https://jopa.com');

$uri = new Panda::URI("http://ya.ru/my/path?p1=v1&p2=v2#myhash");
$uri->location('mail.ru:8000');
is($uri, "http://mail.ru:8000/my/path?p1=v1&p2=v2#myhash");
is($uri->host, 'mail.ru');
is($uri->explicit_port, 8000);
is($uri->location, 'mail.ru:8000');

$uri->location('vk.com:');
is($uri, "http://vk.com/my/path?p1=v1&p2=v2#myhash");
is($uri->explicit_port, 0);
is($uri->port, 80);

$uri = new Panda::URI("//ya.ru:2345/my/path?p1=v1&p2=v2#myacnhor");
is($uri->proto, "");

$uri = new Panda::URI;
$uri->proto('http');
is($uri->proto, 'http');
$uri->host('ya.ru');
is($uri, 'http://ya.ru');

done_testing();
