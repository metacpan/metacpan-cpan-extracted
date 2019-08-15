use Test::More;
use MooX::Purple;
use MooX::Purple::G 't/lib';

role Before {
	public seven { return '7' }
};

role World allow Hello with Before {
	private six { 'six' }
};

class Hello with qw/World/ allow qw/main/ use Scalar::Util qw/reftype/ use qw/JSON/ {
	use Types::Standard qw/Str HashRef ArrayRef Object/;

	attributes
		one => [{ okay => 'one'}],
		[qw/two three/] => [rw, Str, { default => 'the world is flat' }];

	validate_subs
		four => {
			params => {
				message => [Str, sub {'four'}]
			}
		};

	public four { return $_[1]->{message} }
	private five { return $_[0]->six }
	public ten { reftype bless {}, 'Flat::World' }
	public eleven { encode_json { flat => "world" } }
};

class Night is qw/Hello/ {
	public nine { return 'nine' }
};

test_file('Before.pmc');
test_file('World.pmc');
test_file('Hello.pmc');
test_file('Night.pmc');

sub test_file {
	my $file = shift;
	my $expected = read_file(sprintf('t/lib/out/%s', $file));
	my $got = read_file(sprintf('t/lib/%s', $file));
	is($got, $expected, $gut);
}

sub read_file {
	open my $fh, '<', $_[0];
	my $source = do { local $/; <$fh> };
	close $fh;
	return $source;
}

ok(1);
done_testing();


