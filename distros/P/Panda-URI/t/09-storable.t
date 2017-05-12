use strict;
use warnings;
use Test::More;
use Panda::URI qw/uri :const/;
use Storable qw/freeze thaw dclone/;

my $uri = Panda::URI->new("http://ya.ru/path?a=b&c=d#jjj");
my $f = freeze($uri);
my $c = thaw($f);
is(ref($c), 'Panda::URI');
is($c, "http://ya.ru/path?a=b&c=d#jjj");

$uri = uri("http://ya.ru/path?a=b&c=d#jjj");
$f = freeze($uri);
$c = thaw($f);
is(ref($c), 'Panda::URI::http');
is($c, "http://ya.ru/path?a=b&c=d#jjj");
ok(!eval { $c->scheme('ftp'); 1});

$uri = uri("http://ya.ru/path?a=b&c=d#jjj");
$c = dclone($uri);
is(ref($c), 'Panda::URI::http');
is($c, "http://ya.ru/path?a=b&c=d#jjj");
ok(!eval { $c->scheme('ftp'); 1});

done_testing();
