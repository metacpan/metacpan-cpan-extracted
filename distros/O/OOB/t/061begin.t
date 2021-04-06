use Test::More;
use Scalar::Util qw(refaddr);
BEGIN {
	*CORE::GLOBAL::ref = sub {
		CORE::ref $_[0];
	};
}
use OOB;
OOB->foo;
my $message = ['test'];
OOB->foo($message, 'testing');
is(OOB->foo($message), 'testing');

1;
done_testing;
