use strict;
use warnings;
use Test::More import => [qw(is is_deeply done_testing)];
use Test::AutoMock qw(mock_overloaded manager);

my $mock = mock_overloaded(
    methods => {
        'hoge->{bar}->[3]' => sub { 3 },
        'hoge->[2]->{boo}' => 'boo',
        'foo->()->[1]->{boo}->hoge' => sub { 'hoge' },
    },
);

is_deeply [manager($mock)->calls], [],
          q(hasn't been called any methods yet);

is sprintf('%d', $mock->hoge->{bar}[3]), '3';
my $boo = $mock->hoge->[2]{boo};
is "$boo", 'boo';
my $hoge = $mock->foo->()[1]{boo}->hoge;
is "$hoge", 'hoge';

done_testing;
