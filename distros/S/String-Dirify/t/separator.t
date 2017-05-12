use Test::More tests => 3;
use String::Dirify 'dirify';

ok(dirify("  \xc0\xe0\xdf\xff\xd4", 1)       eq '_aassyo', 'Test 1: High ASCII chars');
ok(dirify('  !Q@W#E$R%T^Y', '_')             eq '_qwerty', 'Test 2: Punctuation');
ok(dirify('  <html>html&amp;ok</html>', 'x') eq 'xhtmlok', 'Test 3: HTML');
