use strict;
use warnings;
use Test::More import => [qw(is is_deeply done_testing)];
use Test::AutoMock qw(mock_overloaded manager);

my $mock = mock_overloaded;
$mock->automock_hoge;
$mock->_hoge;
$mock->refaddr->blessed->ok->eq_array;
$mock->calls->child->automock_calls->automock_child;
$mock->_call_method->_overload_nomethod;
$mock->new->get_manager;

my @calls = manager($mock)->calls;
is int(@calls), 14;
is_deeply $calls[0], ['automock_hoge', []];
is_deeply $calls[1], ['_hoge', []];
is_deeply $calls[2], ['refaddr', []];
is_deeply $calls[3], ['refaddr->blessed', []];
is_deeply $calls[4], ['refaddr->blessed->ok', []];
is_deeply $calls[5], ['refaddr->blessed->ok->eq_array', []];
is_deeply $calls[6], ['calls', []];
is_deeply $calls[7], ['calls->child', []];
is_deeply $calls[8], ['calls->child->automock_calls', []];
is_deeply $calls[9], ['calls->child->automock_calls->automock_child', []];
is_deeply $calls[10], ['_call_method', []];
is_deeply $calls[11], ['_call_method->_overload_nomethod', []];
is_deeply $calls[12], ['new', []];
is_deeply $calls[13], ['new->get_manager', []];

done_testing;
