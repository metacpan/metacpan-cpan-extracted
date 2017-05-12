use Test::More;
use Mojo::Redis2;
use Mojo::Redis2::Transaction;

is $Mojo::Redis2::Transaction::VERSION, $Mojo::Redis2::VERSION, 'version';

done_testing;
