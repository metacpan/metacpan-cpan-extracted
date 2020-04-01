use Test::More;
use MooX::Purple;
use MooX::Purple::G 't/lib';

class Day::Night {
	public nine { return 'crazy' }
};

class Day::Night::Day is Day::Night {};

my $night = Day::Night->new();
is($night->nine, 'crazy');

my $night = Day::Night::Day->new();
is($night->nine, 'crazy');

done_testing();
