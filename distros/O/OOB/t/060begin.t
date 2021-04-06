use Test::More;
use Scalar::Util qw(refaddr);
BEGIN {
	$ENV{OOB_DEBUG} = 1;
}
use OOB;
OOB->foo;
my $message = ['test'];
OOB->foo($message, 'testing');
my %data = OOB->dump();
is_deeply(\%data, {
	'OOB--foo' => {
		refaddr($message) => 'testing'
	}
});
my $data = OOB->dump();
is_deeply($data, {
	'OOB--foo' => {
		refaddr($message) => 'testing'
	}
});
OOB->dump();
1;
done_testing;
