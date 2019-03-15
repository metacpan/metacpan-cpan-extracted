use strict;
use warnings;
use Test::More import => [qw(isa_ok is is_deeply done_testing)];
use Test::AutoMock qw(mock manager);

my $mock = mock();
# mock.hoge.return_value = 10
(manager $mock)->add_method(hoge => 10);
# mock.foo.side_effect = lambda x: x + 1
(manager $mock)->add_method(foo => sub { $_[0] + 1 });

# call any methods
$mock->abc;
my $def = $mock->def;
$def->ghi;

# call defined methods
is $mock->hoge, 10;
is $mock->foo(100), 101;

# access to child
is manager($mock)->child('def')->mock, $def;
isa_ok manager($mock)->child('jkl')->child('mno')->mock,
       'Test::AutoMock::Mock::Basic';
is manager($mock)->child('hoge'), undef, 'hoge returns 10 instead of a child';

# assert results
my @calls = (manager $mock)->calls;
is @calls, 5;
is_deeply $calls[0], ['abc', []];
is_deeply $calls[1], ['def', []];
is_deeply $calls[2], ['def->ghi', []];
is_deeply $calls[3], ['hoge', []];
is_deeply $calls[4], ['foo', [100]];

# assert sub results
my @def_calls = (manager $mock)->child('def')->calls;
is @def_calls, 1;
is_deeply $def_calls[0], ['ghi', []];

# resets all call records
(manager $mock)->reset;

# assert sub results
my @def_calls_after_reset = (manager $mock)->child('def')->calls;
is @def_calls_after_reset, 0;

# assert results again
my @calls_after_reset = (manager $mock)->calls;
is @calls_after_reset, 0;

done_testing;
