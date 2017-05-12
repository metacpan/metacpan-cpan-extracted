use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

my $redis = Mojo::Redis2->new;
my ($err, $res);

$redis->get(foo => sub { (my $redis, $err, $res) = @_; });
$redis->subscribe(['foo']);

my $basic  = $redis->{connections}{basic};
my $pubsub = $redis->{connections}{pubsub};

$basic->{waiting}  = delete $basic->{queue};
$pubsub->{waiting} = delete $pubsub->{queue};

eval {
  $redis->_read($pubsub, "+OK");
  $redis->_read($basic,  "\r\n\$2\r\n42\r\n");
} or do {
  $err = 'Need to clear protocol';
};

is $err, 'Need to clear protocol', 'Need to clear protocol';

done_testing;
