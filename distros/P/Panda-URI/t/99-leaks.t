use strict;
use warnings;
use Panda::URI;
use Test::More;

plan skip_all => 'set WITH_LEAKS=1 to enable leaks test' unless $ENV{WITH_LEAKS};

my $ok = eval {
    require BSD::Resource;
    1;
};

plan skip_all => 'FreeBSD System and installed BSD::Resource required to test for leaks' unless $ok;

my $measure = 200;
my $leak = 0;

my @a = 1..100;
undef @a;

for (my $i = 0; $i < 30000; $i++) {
    my $uri = Panda::URI::http->new("http://ya.ru:2345/my/path?p1=v%201&p2=http%3a%2f%2fya.ru&p3=popa%20jopa&p4=&p5&=v6&&p7=v7", 'p4=&p5&=v6&&p7=v7');
    my $a = $uri->query();
    $uri->query(a => 1, "key space" => 2, b => "val space", "" => 'emtpy');
    $uri->query({a => 1, "key space" => 2, b => "val space", multi => [1,2,3], "" => 'emtpy'});
    my $b = $uri->query_string;
    my $c = $uri->host;
    my $d = $uri->location;
    my $e = $uri->port;
    my $arr = $uri->path_segments;
    
    $uri->add_query('asdfassdf=dsfsdfdsfdsf');
    $uri->query();
    $uri->query_string;
    
    $uri->add_query({asdasdas => 'sadfsdfdsfdsfds'});
    $uri->query();
    $uri->query_string;

    my $uri2 = new Panda::URI('http://myme.com/ath?asd=asdxcvxcvsdf#fdgdfgds');
    $uri2->query();
    $uri2->set($uri);

    $uri2->clone->clone->query;
    
    my $aa = Panda::URI::encode_uri_component("val space!\@#\$\%^&*()");
    my $bb = Panda::URI::decode_uri_component($aa);
    
    $uri = new Panda::URI::https("https://ya.ru/my/path?a=b", {c => 'd e'});
    $uri->query();
    $uri->query_string;
    $uri->to_string;
    my $str = $uri.'';
    
    $arr = $uri->path_segments;
    
    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 10000;
}

$leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 100;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);

done_testing();
