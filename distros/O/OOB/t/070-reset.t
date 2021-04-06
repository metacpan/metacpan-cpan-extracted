use Test::More;
use Scalar::Util qw(refaddr);
use OOB qw( OOB_set OOB_get OOB_reset );;
my $message = ['test'];
OOB_set($message, foo => 'testing');
OOB_set($message, bar => OOB_get($message, 'foo'));
is(OOB_get($message, 'bar'), 'testing');

my $removed = OOB_reset($message);
is_deeply($removed, {
	'main--foo' => 'testing',
	'main--bar' => 'testing'
});

1;
done_testing;
