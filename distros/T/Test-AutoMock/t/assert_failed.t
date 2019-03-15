use strict;
use warnings;
use Test::Tester import => [qw(check_tests)]; # must be used at first
use Test::AutoMock qw(mock_overloaded manager);
use Test::More import => [qw(done_testing)];

my $mock = mock_overloaded;
$mock->hoge(1, 2);

check_tests sub { manager($mock)->called_with_ok(hoge => [2, 1]) },
    [
        {
            ok => 0,
            name => 'hoge has been called with correct arguments',
            diag => '',
        },
    ];

check_tests sub { manager($mock)->called_ok('foo') },
    [
        {
            ok => 0,
            name => 'foo has been called',
            diag => '',
        },
    ];

check_tests sub { manager($mock)->not_called_ok('hoge') },
    [
        {
            ok => 0,
            name => 'hoge has not been called',
            diag => '',
        },
    ];

done_testing;
