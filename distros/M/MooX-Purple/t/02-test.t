use Test::More;
use MooX::Purple;

{
	package Test::Role;
	use Moo::Role;
	has ten => is => 'ro', default => sub {return 'ten'};
}

role Before {
	public eight { return '8' }
};

role World with Test::Role allow qw/Hello/ with qw/Before/ {
	private four { return 'fourth' }
};

class Hello with World allow qw/main/ {
	use Types::Standard qw/Str HashRef ArrayRef Object/;

	attributes
		one => [{ okay => 'one'}],
		[qw/six seven/] => [rw, Str, { default => 'ruling the world' }];

	validate_subs
		two => {
			params => {
				message => [Str, sub {'Hello World'}]
			}
		};

	public two { return $_[1]->{message} }
	public three { return 'lost'; }
	private five { return $_[0]->four }
};

class Night is qw/Hello/ {
	public nine { return 'crazy' }
};

my $hello = Hello->new();
=pod
is_deeply($hello->one, {okay => 'one'});
is($hello->two({}), 'Hello World');
is($hello->three, 'lost');
=cut
is($hello->five, 'fourth');
=pod
eval {$hello->four};
like($@, qr/cannot call private method four from/);
is($hello->six, 'ruling the world');
is($hello->eight, '8');

my $night = Night->new();
is_deeply($night->one, {okay => 'one'});
is($night->two({}), 'Hello World');
is($night->three, 'lost');
is($night->five, 'fourth');
eval {$night->four};
like($@, qr/cannot call private method four from/);
is($night->six, 'ruling the world');
is($night->eight, '8');
is($night->nine, 'crazy');
is($night->ten, 'ten');
=cut
done_testing();
