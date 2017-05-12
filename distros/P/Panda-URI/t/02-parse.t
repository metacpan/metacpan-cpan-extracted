use strict;
use warnings;
use Test::More;
use Panda::URI qw/:const/;

my ($uri, $flags);

#basic
test_url();
test_url('http://ya.ru', 'http', '', 'ya.ru', 0, 80);
test_url('https://ya.ru', 'https', '', 'ya.ru', 0, 443);
test_url('http://ya.ru:80', 'http', '', 'ya.ru', 80, 80);
test_url('http://ya.ru/', 'http', '', 'ya.ru', 0, 80, '/');
test_url('http://ya.ru/mypath', 'http', '', 'ya.ru', 0, 80, '/mypath');
test_url('http://ya.ru/mypath/a/b/c', 'http', '', 'ya.ru', 0, 80, '/mypath/a/b/c');
test_url('http://ya.ru?sukastring', 'http', '', 'ya.ru', 0, 80, '', 'sukastring');
$uri = test_url('http://ya.ru?suka%20string+nah', 'http', '', 'ya.ru', 0, 80, '', 'suka%20string+nah');
is($uri->raw_query, 'suka string nah');
test_url('http://ya.ru#my%23frag', 'http', '', 'ya.ru', 0, 80, '', '', 'my%23frag');
test_url('http://ya.ru#my#frag', 'http', '', 'ya.ru', 0, 80, '', '', 'my#frag', 'http://ya.ru#my#frag');
test_url('http://ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', '', 'ya.ru', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');

# user info
test_url('http://user@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user', 'ya.ru', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://user:pass@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user:pass', 'ya.ru', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://user:@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user:', 'ya.ru', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://cool@user@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'cool@user', 'ya.ru', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash', 'http://cool%40user@ya.ru:2345/my/path?p1=v1&p2=v2#myhash');

#IPv4
test_url('http://1.10.100.255:2345/my/path?p1=v1&p2=v2#myhash', 'http', '', '1.10.100.255', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://hi@1.10.100.255:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'hi', '1.10.100.255', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');

#IPv6
test_url('http://[aa:bb:cc:dd::ee:ff]/my/path?p1=v1&p2=v2#myhash', 'http', '', '[aa:bb:cc:dd::ee:ff]', 0, 80, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://[aa:bb:cc:dd::ee:ff]:2345/my/path?p1=v1&p2=v2#myhash', 'http', '', '[aa:bb:cc:dd::ee:ff]', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://user@[aa:bb:cc:dd::ee:ff]:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user', '[aa:bb:cc:dd::ee:ff]', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('http://[aa:bb:cc:dd::ee:ff/my/path?p1=v1&p2=v2#myhash', 'http', '', '[aa:bb:cc:dd::ee:ff', 0, 80, '/my/path', 'p1=v1&p2=v2', 'myhash', 'http://%5Baa%3Abb%3Acc%3Add%3A%3Aee%3Aff/my/path?p1=v1&p2=v2#myhash');

#scheme-relative
test_url('//ya.ru', '', '', 'ya.ru', 0, 0);
test_url('//sss@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', '', 'sss', 'ya.ru', 2345, 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
test_url('//[aa:bb:cc:dd::ee:ff]/my/path?p1=v1&p2=v2#myhash', '', '', '[aa:bb:cc:dd::ee:ff]', 0, 0, '/my/path', 'p1=v1&p2=v2', 'myhash');

#scheme:path case
test_url('mailto:syber@crazypanda.ru', 'mailto', '', '', 0, 0, 'syber@crazypanda.ru');
test_url('mailto:syber@crazypanda.ru?a=b#dada', 'mailto', '', '', 0, 0, 'syber@crazypanda.ru', 'a=b', 'dada');
test_url('a:b:c:d:e:f', 'a', '', '', 0, 0, 'b:c:d:e:f');
test_url('cp:/jopa', 'cp', '', '', 0, 0, '/jopa');

#path case
test_url('ya.ru', '', '', '', 0, 0, 'ya.ru');
test_url('ya.ru/a/b/b', '', '', '', 0, 0, 'ya.ru/a/b/b');

#leading authority euristics
$flags = ALLOW_LEADING_AUTHORITY;
test_url('ya.ru:8080', '', '', 'ya.ru', 8080, 8080, '', '', '', '//ya.ru:8080');
test_url('ya.ru', '', '', 'ya.ru', 0, 0, '', '', '', '//ya.ru');
test_url('ya.ru:', 'ya.ru', '', '', 0, 0);
test_url('ya.ru:80a', 'ya.ru', '', '', 0, 0, '80a');
test_url('ya.ru:8080/a/b', '', '', 'ya.ru', 8080, 8080, '/a/b', '', '', '//ya.ru:8080/a/b');
test_url('ya.ru/a/b', '', '', 'ya.ru', 0, 0, '/a/b', '', '', '//ya.ru/a/b');
test_url('ya.ru:/a/b', 'ya.ru', '', '', 0, 0, '/a/b');
test_url('ya.ru:80a/a/b', 'ya.ru', '', '', 0, 0, '80a/a/b');
$flags = 0;

# junk
test_url('https://jopa.com:123/://asd/?:hello?://yo?u/#lalala://hello/?a=b&jopa=#privet',
         'https', '', 'jopa.com', 123, 123, '/://asd/', ':hello?://yo?u/', 'lalala://hello/?a=b&jopa=#privet',
         'https://jopa.com:123/://asd/?:hello?://yo?u/#lalala://hello/?a=b&jopa=#privet');
test_url("https://jopa.com#a?b?c", 'https', '', 'jopa.com', 0, 443, '', '', 'a?b?c');

#secure
ok(Panda::URI->new("https://ya.ru")->secure);
ok(!Panda::URI->new("http://ya.ru")->secure);
ok(!Panda::URI->new("//ya.ru")->secure);
ok(!Panda::URI->new("ya.ru")->secure);

#path relative
is(Panda::URI->new("http://ya.ru")->relative, "/"); # not empty relative path
is(Panda::URI->new("http://ya.ru?p1=v1&p2=v2#myhash")->relative, '/?p1=v1&p2=v2#myhash');

# equals

# injection
# null byte in uri. should NOT core dump. Stop parsing url on null byte
test_url("http://api.odnokl\x5C\x00\x03\x06\x00\x00\x00\x00\x00\x00\x00\x23\xC3\xABlq\x1B\x00\x02",
         'http', '', 'api.odnokl\\', 0, 80, '', '', '', 'http://api.odnokl%5C');


sub test_url {
    my ($url, $scheme, $uinfo, $host, $expport, $port, $path, $qstr, $frag, $str) = @_;
    $url //= '';
    $flags ||= 0;
    my $uri = Panda::URI->new($url, $flags);

    my $testname = "test url $url";
    $testname .= " (flags=$flags)" if $flags;
    $str //= $url //= '';
    $scheme //= '';
    $uinfo //= '';
    $host //= '';
    $expport //= 0;
    $port //= 0;
    $path //= '';
    $qstr //= '';
    $frag //= '';
        
    is($uri->scheme, $scheme, "$testname (scheme)");
    is($uri->proto, $scheme, "$testname (scheme)");
    is($uri->protocol, $scheme, "$testname (scheme)");
    is($uri->user_info, $uinfo, "$testname (uinfo)");
    is($uri->host, $host, "$testname (host)");
    is($uri->explicit_port, $expport, "$testname (exp port)");
    is($uri->port, $port, "$testname (port)");
    is($uri->explicit_location, $expport ? "$host:$expport" : $host, "$testname (exp location)");
    is($uri->location, "$host:$port", "$testname (location)");
    is($uri->path, $path, "$testname (path)");
    is($uri->query_string, $qstr, "$testname (qstr)");
    is($uri->fragment, $frag, "$testname (frag)");
    is($uri->hash, $frag, "$testname (frag)");
    is($uri, $str, "$testname (tostring)");
    is($uri->to_string, $str, "$testname (tostring)");
    is($uri->as_string, $str, "$testname (tostring)");
    is($uri->url, $str, "$testname (tostring)");
    
    return $uri;
}

done_testing();
