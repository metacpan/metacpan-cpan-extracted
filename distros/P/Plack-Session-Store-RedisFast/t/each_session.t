use strict;
use warnings;

use lib::abs qw( ../lib );

use Test::More;

use Plack::Session::Store::RedisFast;

my $store = Plack::Session::Store::RedisFast->new;

my ( $id1, $id2 ) = map { 'sess_id_' . rand() } 1 .. 2;

ok $store->store( $id1, { val => $id1 } ), 'store id1';
ok $store->store( $id2, { val => $id2 } ), 'store id2';

my $found = 0;
ok $store->each_session(
    sub {
        my ( $redis_instance, $redis_prefix, $session_id, $session ) = @_;
        if ( $session_id eq $id1 ) {
            $found++;
            is_deeply $session, { val => $id1 },
              'session id1 is { val => id1 }';
        }
        if ( $session_id eq $id2 ) {
            $found++;
            is_deeply $session, { val => $id2 },
              'session id2 is { val => id2 }';
        }
    }
  ),
  'each_session on stored items';
is $found, 2, 'exactly two session found';

ok $store->remove($id1), 'remove id1';
ok $store->remove($id2), 'remove id2';

ok $store->each_session(
    sub {
        my ( $redis_instance, $redis_prefix, $session_id, $session ) = @_;
        if ( $session_id eq $id1 ) {
            ok 0, 'sessio id1 found, but should be not';
        }
        if ( $session_id eq $id2 ) {
            ok 0, 'session id2 found, but should be not';
        }
    }
  ),
  'each_session on removed items';

done_testing;
