use strict;
use warnings;
use Test::AutoMock qw(mock_overloaded manager);
use Test::More import => [qw(is done_testing)];

my $mock = mock_overloaded;

# define operators, hashes, arrays
manager($mock)->add_method('`+`' => 10);
manager($mock)->add_method('{key}' => 'value');
manager($mock)->add_method('[0]' => 'zero');

# call overloaded operators
is($mock + 5, 10);
is($mock->{key}, 'value');
is($mock->[0], 'zero');

# varify calls
manager($mock)->called_with_ok('`+`', [5, '']);
manager($mock)->called_ok('{key}');
manager($mock)->called_ok('[0]');

done_testing;
