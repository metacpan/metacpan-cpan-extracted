use strict;
use warnings;
use Test::AutoMock qw(mock_overloaded manager);
use Test::More import => [qw(is done_testing)];

my $mock = mock_overloaded(
    'hoge->bar' => sub { 1 },
);

is $mock->hoge->bar(10, 20), 1;

manager($mock)->called_with_ok(
    'hoge->bar', [10, 20],
);
manager($mock)->called_ok('hoge->bar');
manager($mock)->not_called_ok('bar');

my $hoge = manager($mock)->child('hoge');
$hoge->called_with_ok(
    'bar', [10, 20],
);
$hoge->not_called_ok('hoge');

done_testing;
