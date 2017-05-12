use strict;
use warnings;
use Test::More;
use Test::Deep;
use Panda::URI;
my $uri;
my @segments;

$uri = new Panda::URI("https://ya.ru/my/path%2Ffak/cool/mf?a=b");
is($uri->path, '/my/path%2Ffak/cool/mf');
@segments = $uri->path_segments;
cmp_deeply(\@segments, [qw#my path/fak cool mf#]);

$uri = new Panda::URI("https://ya.ru?a=b");
@segments = $uri->path_segments;
cmp_deeply(\@segments, []);

$uri = new Panda::URI("https://ya.ru/?a=b");
@segments = $uri->path_segments;
cmp_deeply(\@segments, []);

$uri = new Panda::URI("https://ya.ru/as/?a=b");
@segments = $uri->path_segments;
cmp_deeply(\@segments, ['as']);

$uri = new Panda::URI("https://ya.ru/as?a=b");
@segments = $uri->path_segments;
cmp_deeply(\@segments, ['as']);

$uri->path_segments(1,2,3,4);
is($uri, "https://ya.ru/1/2/3/4?a=b");

$uri->path_segments('');
is($uri, "https://ya.ru?a=b");

$uri->path_segments('jopa popa', 'pizda/nah');
is($uri, "https://ya.ru/jopa%20popa/pizda%2Fnah?a=b");

done_testing();
