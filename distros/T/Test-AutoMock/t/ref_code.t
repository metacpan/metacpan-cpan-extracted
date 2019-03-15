use strict;
use warnings;
use Test::More import => [qw(ok is is_deeply done_testing)];
use Test::AutoMock qw(mock_overloaded manager);

my $mock = mock_overloaded;
my $code = $mock->get_code;
my $ret = $code->();
ok $ret->{result} ? 1 : 0;

my @calls = manager($mock)->calls;
is @calls, 4;
is_deeply $calls[0], ['get_code', []];
is_deeply $calls[1], ['get_code->()', []];
is_deeply $calls[2], ['get_code->()->{result}', []];
is_deeply $calls[3], ['get_code->()->{result}->`bool`', [undef, '']];

done_testing;
