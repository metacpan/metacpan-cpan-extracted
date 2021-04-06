use Test::More;
use Scalar::Util qw(refaddr);
BEGIN {
	*CORE::GLOBAL::bless = sub {
		if ($_[0] && $_[1]) {
			return CORE::bless($_[0], $_[1]);
		}
		return 'HASH';
	};
}
use OOB;
OOB->foo;
my $message = ['test'];
OOB->foo($message, 'testing');
is(OOB->foo($message), 'testing');

my $ref = \&CORE::GLOBAL::bless;
my $obj = $ref->($ref->({}, 'Test'));

ok(1);
done_testing;

1;
