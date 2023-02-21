use Test::More;

{
	package Real;

	sub new { bless {}, $_[0] }

	sub on {
		return 'okay';
	}

	1;
}

use Mockery;

my $real = Real->new();

is($real->on, 'okay');

my $mockery = Mockery->new();

$mockery->action(
	class => 'Real',
	methods => {
		on => sub {
			return 'not okay'
		}
	}
);

my $real = Real->new();

is($real->on, 'not okay');

$mockery->fake(
	class => 'Not',
	methods => {
		on => sub {
			return 'long long time';
		}
	}
);

my $not = Not->new();

is($not->on, 'long long time');

$mockery->true(
	class => 'Not',
	methods => [qw/on/]
);

is($not->on, 1);

$mockery->false(
	class => 'Not',
	methods => [qw/on/]
);

is($not->on, 0);

done_testing();
