use Test::More;
use MooX::Purple -prefix => 'Everyday';
use MooX::Purple::G -prefix => 'Everyday', -lib => 't/lib';

role +Bad {
	use Types::Standard qw/Num/;
	validate_subs 
		ten => {
			params => [[Num]]
		};
	
	public ten  {
		return 'worse';
	}
}

class +Night with +Bad {
	public nine { return 'crazy' }
};

class +Day::Night::Day is +Night {};

my $night = Everyday::Night->new();

is($night->nine, 'crazy');
is($night->ten(10), 'worse');

$night = Everyday::Day::Night::Day->new();
is($night->nine, 'crazy');
is($night->ten(10), 'worse');




done_testing();
