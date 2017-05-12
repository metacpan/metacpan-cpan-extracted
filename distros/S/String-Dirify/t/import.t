use Test::More tests => 4;
use String::Dirify ':all';

ok(dirify("\xc0\xe0\xdf\xff\xd4")     eq 'aassyo', 'Test 1: High ASCII chars');
ok(dirify('!Q@W#E$R%T^Y')             eq 'qwerty', 'Test 2: Punctuation');
ok(dirify('<html>html&amp;ok</html>') eq 'htmlok', 'Test 3: HTML');
ok(dirify('<![CDATA[x]]>')            eq 'cdatax', 'Test 4: CDATA');
