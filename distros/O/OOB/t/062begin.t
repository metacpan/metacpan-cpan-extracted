use Test::More;
use Scalar::Util qw(refaddr);
BEGIN {
	*CORE::GLOBAL::ref = sub {
		return CORE::ref $_[0] if ($_[0]);
		return 'STRING';
	};
}
use OOB;
OOB->foo;
my $message = ['test'];
OOB->foo($message, 'testing');
is(OOB->foo($message), 'testing');

my $ref = \&CORE::GLOBAL::ref;
is($ref->($message), 'ARRAY');
is(ref($ref), 'CODE');
1;
done_testing;
