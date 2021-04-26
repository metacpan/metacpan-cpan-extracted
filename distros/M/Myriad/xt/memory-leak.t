use strict;
use warnings;

BEGIN {
    # Enforce very small delay on deferred operation for in-process Perl module
    $ENV{MYRIAD_RANDOM_DELAY} = 0.00001;
}
use Future;
use Future::AsyncAwait;
use Test::More;
use Test::MemoryGrowth;
use Myriad::Storage::Implementation::Memory;

use IO::Async::Test;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );
for my $class (qw(Myriad::Storage::Implementation::Memory)) {
    subtest $class => sub {
        $loop->add(
            my $storage = new_ok($class)
        );
        # Cut-down version of the tests for a few
        # methods, just make sure that we don't go
        # crazy with our memory usage
        note 'Memory test, this may take a while';
        no_growth {
            Future->wait_all(
                $storage->set('some_key', 'some_value'),
                $storage->hash_set('some_hash_key', 'key', 'a hash value'),
            )->get;
            Future->wait_all(
                $storage->get('some_key'),
                $storage->hash_get('some_hash_key', 'key'),
            )->get;
            ()
        } calls => 2_000,
          'ensure basic storage operations do not leak memory';
        done_testing;
    };
}
done_testing;

