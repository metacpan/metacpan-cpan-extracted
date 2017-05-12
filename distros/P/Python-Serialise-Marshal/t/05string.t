use strict;
use Test::More tests => 25;

use Math::Complex;
use_ok('Python::Serialise::Marshal');



#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/string'));

is_deeply($ps->load(), "string", 'a string');
is_deeply($ps->load(), 'string', 'another string');
is_deeply($ps->load(), "string with spaces", 'a string with spaces');
is_deeply($ps->load(), 'string with spaces', 'another string with spaces');
is_deeply($ps->load(), "string with\nnewline", 'newlines a-go-go');
is_deeply($ps->load(), "string with\nnewline", 'again with the new lines');
ok($ps->close());


#testing generating the same data
ok(my $ps = Python::Serialise::Marshal->new('>t/tmp'));

ok($ps->dump("string"), 'write a string');
ok($ps->dump('string'), 'write another string');
ok($ps->dump("string with spaces"), 'write a string with spaces');
ok($ps->dump('string with spaces'), 'write another string with spaces');
ok($ps->dump("string with\nnewline"), 'write newlines a-go-go');
ok($ps->dump("string with\nnewline"), 'write again with the new lines');
ok($ps->close());


#testing python generated data
ok(my $ps = Python::Serialise::Marshal->new('t/tmp'));
is_deeply($ps->load(), "string", 'dogfood a string');
is_deeply($ps->load(), 'string', 'dogfood another string');
is_deeply($ps->load(), "string with spaces", 'dogfood a string with spaces');
is_deeply($ps->load(), 'string with spaces', 'dogfood another string with spaces');
is_deeply($ps->load(), "string with\nnewline", 'dogfood newlines a-go-go');
is_deeply($ps->load(), "string with\nnewline", 'dogfood again with the new lines');
ok($ps->close());
