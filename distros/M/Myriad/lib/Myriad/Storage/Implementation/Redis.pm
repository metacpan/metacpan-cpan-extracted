package Myriad::Storage::Implementation::Redis;

use Myriad::Class does => [
    'Myriad::Role::Storage'
];

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Storage::Implementation::Redis - access to microservice storage via Redis

=head1 DESCRIPTION

This provides an implementation of L<Myriad::Role::Storage> using L<https://redis.io>
as the underlying storage mechanism and transport layer.

See L<Myriad::Role::Storage> for API details.

=cut

use constant STORAGE_PREFIX => 'storage';

# L<Myriad::Transport::Redis> instance to manage the connections.
has $redis;

BUILD (%args) {
    $redis = delete $args{redis} // die 'need a Transport instance';
}

=head2 apply_prefix

Add the storage prefix to the key before sending it to Redis

=cut

method apply_prefix($key) {
    return STORAGE_PREFIX . '.' . $key;
}

=head2 get

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=back

Returns a L<Future> which will resolve to the corresponding value, or C<undef> if none.

=cut

async method get ($k) {
    await $redis->get($self->apply_prefix($k));
}

=head2 set

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $v >> - the scalar value to set

=back

Note that references are currently B<not> supported - attempts to write an arrayref, hashref
or object will fail.

Returns a L<Future> which will resolve on completion.

=cut

async method set ($k, $v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    await $redis->set($self->apply_prefix($k) => $v);
}

=head2 getset

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $v >> - the scalar value to set

=back

Note that references are currently B<not> supported - attempts to write an arrayref, hashref
or object will fail.

Returns a L<Future> which will resolve to the original value on completion.

=cut

async method getset ($k, $v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    return await $redis->getset($self->apply_prefix($k) => $v);
}

=head2 incr

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=back

Returns a L<Future> which will resolve to the corresponding incremented value, or C<undef> if none.

=cut

async method incr ($k) {
    await $redis->incr($self->apply_prefix($k));
}

=head2 observe

Observe a specific key.

Returns a L<Ryu::Source> which will emit the current and all subsequent values.

=cut

method observe ($k) {
    return $redis->subscribe($self->apply_prefix($k));
}

=head2 observe_namespace

Observe and entire namespace.

=cut

async method watch_keyspace ($keyspace) {
    my $sub = await $redis->watch_keyspace($self->apply_prefix($keyspace));
    my $pattern = STORAGE_PREFIX . '\.';
    return $sub->map(sub {
        $_ =~ s/$pattern//;
        return $_;
    });
}

=head2 push

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $v >> - the scalar value to set

=back

Returns a L<Future> which will resolve to .

=cut

async method push ($k, @v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($_) for grep { ref } @v;
    await $redis->rpush($self->apply_prefix($k), @v);
}

=head2 unshift

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method unshift ($k, @v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($_) for grep { ref } @v;
    await $redis->lpush($self->apply_prefix($k), @v);
}

=head2 pop

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method pop ($k) {
    await $redis->rpop($self->apply_prefix($k));
}

=head2 shift

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method shift ($k) {
    await $redis->lpop($self->apply_prefix($k));
}

=head2 hash_set

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method hash_set ($k, $hash_key, $v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    await $redis->hset($k, $self->apply_prefix($hash_key), $v);
}

=head2 hash_get

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to the scalar value for this key.

=cut

async method hash_get ($k, $hash_key) {
    await $redis->hget($k, $self->apply_prefix($hash_key));
}

=head2 hash_add

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> indicating success or failure.

=cut

async method hash_add ($k, $hash_key, $v) {
    $v //= 1;
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    await $redis->hincrby($k, $self->apply_prefix($hash_key), $v);
}

=head2 hash_keys

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to a list of the keys in no defined order.

=cut

async method hash_keys ($k) {
}

=head2 hash_values

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to a list of the values in no defined order.

=cut

async method hash_values ($k) {
}

=head2 hash_exists

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to true if the key exists in this hash.

=cut

async method hash_exists ($k, $hash_key) {
}

=head2 hash_count

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to the count of the keys in this hash.

=cut

async method hash_count ($k) {
}

=head2 hash_as_list

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to a list of key/value pairs,
suitable for assigning to a hash.

=cut

async method hash_as_list ($k) {
}


=head2 orderedset_add

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $s >> - the scalar score to be attached to member

=item * C<< $m >> - the scalar member value

=back

Note that references are B<not> supported - attempts to write an arrayref, hashref
or object will fail.

Redis sorted sets data structure family.
add a scored member value to a storage key

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_add ($k, $s, $m) {
    die 'score & member values cannot be a reference for key:' . $k . ' - ' . ref($m) . ref($s) if (ref $m or ref $s);
    await $redis->zadd($self->apply_prefix($k), $s => $m);
}

=head2 orderedset_remove_member

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $m >> - the scalar member value

=back

Redis sorted sets data structure family.
removes a specific member from ordered set in storage

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_remove_member ($k, $m) {
    await $redis->zrem($self->apply_prefix($k), $m);
}

=head2 orderedset_remove_byscore

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $min >> - the minimum score

=item * C<< $max >> - the max score

=back

Redis sorted sets data structure family.
removes all members with scores between minimum and maximum within an ordered set in storage

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_remove_byscore ($k, $min, $max) {
    await $redis->zremrangebyscore($self->apply_prefix($k), $min => $max);
}

=head2 orderedset_member_count

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $min >> - the minimum score

=item * C<< $max >> - the max score

=back

Redis sorted sets data structure family.
gives the members count within the provided min and max scores in an ordered set.

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_member_count ($k, $min = '-inf', $max = '+inf') {
    await $redis->zcount($self->apply_prefix($k), $min => $max);
}

=head2 orderedset_members

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $min >> - the minimum score

=item * C<< $max >> - the max score

=item * C<< $with_score >> - flag to return members with or without scores

=back

Redis sorted sets data structure family.
gives list of members within the provided min and max scores in an ordered set.

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_members ($k, $min = '-inf', $max = '+inf', $with_score = 0) {
    await $redis->zrange($self->apply_prefix($k), $min => $max, 'BYSCORE', ($with_score ? 'WITHSCORES' : ()));
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

