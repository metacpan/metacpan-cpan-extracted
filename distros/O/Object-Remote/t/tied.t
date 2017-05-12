use strictures 1;
use Test::More;

use lib 't/lib';

use Tie::Array;
use Tie::Hash;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote;
use ORTestTiedRemote;

my @test_data = qw(1 5 10 30 80);
my $test_sum;

map { $test_sum += $_ } @test_data;

my $conn = Object::Remote->connect('-');
my $remote = ORTestTiedRemote->new::on($conn);

isa_ok($remote, 'Object::Remote::Proxy');

my $remote_array = $remote->array;
my $remote_hash = $remote->hash;

is(ref($remote_array), 'ARRAY', 'Array ref is array ref');
is(ref(tied(@$remote_array)), 'Object::Remote::Proxy', 'Array is tied to proxy object');
is_deeply($remote_array, ['another value'], 'Array is initialized properly');

@$remote_array = @test_data;
is($remote->sum_array, $test_sum, 'Sum of array data matches sum of test data');

is(ref($remote_hash), 'HASH', 'Hash ref is hash ref');
is(ref(tied(%$remote_hash)), 'Object::Remote::Proxy', 'Hash is tied to proxy object');
is_deeply($remote_hash, { akey => 'a value' }, 'Hash is initialized properly');

%$remote_hash = ();
do { my $i = 0; map { $remote_hash->{++$i} = $_ } @test_data };
is($remote->sum_hash, $test_sum, 'Sum of hash values matches sum of test data');

done_testing;

