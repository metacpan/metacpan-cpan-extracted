use Test::More tests => 6;

BEGIN{ use_ok('String::Dirify'); }

my($sd) = String::Dirify -> new();

ok($sd -> dirify("\xc0\xe0\xdf\xff\xd4")     eq 'aassyo', 'Test 2: High ASCII chars');
ok($sd -> dirify('!Q@W#E$R%T^Y')             eq 'qwerty', 'Test 3: Punctuation');
ok($sd -> dirify('<html>html&amp;ok</html>') eq 'htmlok', 'Test 4: HTML');
ok($sd -> dirify('<![CDATA[x]]>')            eq 'cdatax', 'Test 5: CDATA');
ok(String::Dirify -> dirify('not.obj')       eq 'notobj', 'Test 6: Object-free');
