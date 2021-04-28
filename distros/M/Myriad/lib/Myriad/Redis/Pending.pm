package Myriad::Redis::Pending;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use curry;
use Object::Pad;
use Future::AsyncAwait;

class Myriad::Redis::Pending;

has $redis;
has $stream;
has $group;
has $id;
has $finished;

BUILD (%args) {
    $redis = $args{redis} // die 'need a redis';
    $stream = $args{stream} // die 'need a stream';
    $group = $args{group} // die 'need a group';
    $id = $args{id} // die 'need an id';
    $finished = $redis->loop->new_future->on_done($self->curry::weak::finish);
}

=head2 finished

Returns a L<Future> representing the state of this message - C<done> means that
it has been acknowledged.

=cut

method finished () { $finished }

=head2 finish

Should be called once processing is complete.

This is probably in the wrong place - better to have this as a simple abstract class.

=cut

async method finish () {
    await $redis->xack($stream, $group, $id)
}

1;
