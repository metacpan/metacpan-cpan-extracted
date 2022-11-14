package Myriad::Redis::Pending;

use Myriad::Class;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Redis::Pending

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

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

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

