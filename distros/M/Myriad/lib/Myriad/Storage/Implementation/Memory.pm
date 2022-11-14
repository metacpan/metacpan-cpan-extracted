package Myriad::Storage::Implementation::Memory;

use Myriad::Class extends => 'IO::Async::Notifier', does => [ 'Myriad::Role::Storage', 'Myriad::Util::Defer'];

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Storage::Implementation::Memory - microservice storage abstraction

=head1 SYNOPSIS

=head1 DESCRIPTION

This is intended for use in tests and standalone local services.
There is no persistence, and no shared data across multiple
processes, but the full L<Myriad::Storage> API should be exposed
correctly.

=cut

# Common datastore
has %data;

# FIXME Need to update :Defer for Object::Pad
sub MODIFY_CODE_ATTRIBUTES { }

=head2 get

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=back

Returns a L<Future> which will resolve to the corresponding value, or C<undef> if none.

=cut

async method get : Defer ($k) {
    return $data{$k};
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

async method set : Defer ($k, $v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    return $data{$k} = $v;
}

=head2 getset

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $v >> - the scalar value to set

=back

Note that references are currently B<not> supported - attempts to write an arrayref, hashref
or object will fail.

Returns a L<Future> which will resolve on completion.

=cut

async method getset : Defer ($k, $v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    my $original = delete $data{$k};
    $data{$k} = $v;
    return $original;
}

=head2 incr

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=back

Returns a L<Future> which will resolve to the corresponding incremented value, or C<undef> if none.

=cut

async method incr : Defer ($k) {
    return ++$data{$k};
}

=head2 observe

Observe a specific key.

Returns a L<Ryu::Source> which will emit the current and all subsequent values.

=cut

method observe ($k) {
    die 'no observation';
}


=head2 watch_keyspace

Returns update about keyspace

=cut

async method watch_keyspace {
    die 'no watch_keyspace';
}

=head2 push

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $v >> - the scalar value to set

=back

Returns a L<Future> which will resolve to .

=cut

async method push : Defer ($k, @v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($_) for grep { ref } @v;
    push $data{$k}->@*, @v;
    return 0+$data{$k}->@*;
}

=head2 unshift

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method unshift : Defer ($k, @v) {
    die 'value cannot be a reference for ' . $k . ' - ' . ref($_) for grep { ref } @v;
    unshift $data{$k}->@*, @v;
    return 0+$data{$k}->@*;
}

=head2 pop

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method pop : Defer ($k) {
    return pop $data{$k}->@*;
}

=head2 shift

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method shift : Defer ($k) {
    return shift $data{$k}->@*;
}

=head2 hash_set

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to .

=cut

async method hash_set : Defer ($k, %args) {
    for my $hash_key (sort keys %args) {
        my $v = $args{$hash_key};
        die 'value cannot be a reference for ' . $k . ' hash key ' . $hash_key . ' - ' . ref($v) if ref $v;
    }
    @{$data{$k}}{keys %args} = values %args;
    return 0 + keys %args;
}

=head2 hash_get

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to the scalar value for this key.

=cut

async method hash_get : Defer ($k, $hash_key) {
    return $data{$k}{$hash_key};
}

=head2 hash_add

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> indicating success or failure.

=cut

async method hash_add : Defer ($k, $hash_key, $v) {
    $v //= 1;
    die 'value cannot be a reference for ' . $k . ' - ' . ref($v) if ref $v;
    return $data{$k}{$hash_key} += $v;
}

=head2 hash_keys

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to a list of the keys in no defined order.

=cut

async method hash_keys : Defer ($k) {
    return keys $data{$k}->%*;
}

=head2 hash_values

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to a list of the values in no defined order.

=cut

async method hash_values : Defer ($k) {
    return values $data{$k}->%*;
}

=head2 hash_exists

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to true if the key exists in this hash.

=cut

async method hash_exists : Defer ($k, $hash_key) {
    return exists $data{$k}{$hash_key};
}

=head2 hash_count

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to the count of the keys in this hash.

=cut

async method hash_count : Defer ($k) {
    return 0 + keys $data{$k}->%*;
}

=head2 hash_as_list

Takes the following parameters:

=over 4

=item *

=back

Returns a L<Future> which will resolve to a list of key/value pairs,
suitable for assigning to a hash.

=cut

async method hash_as_list : Defer ($k) {
    return $data{$k}->%*;
}

=head2 orderedset_add

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $s >> - the scalar score value

=item * C<< $m >> - the scalar member value

=back

Note that references are currently B<not> supported - attempts to write an arrayref, hashref
or object will fail.

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_add : Defer ($k, $s, $m) {
    die 'score & member values cannot be a reference for ' . $k . ' - ' . ref($s) . ref($m) if (ref $s or ref $m);
    $data{$k} = {} unless defined $data{$k};
    return $data{$k}->{$s} = $m;
}

=head2 orderedset_remove_member

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $m >> - the scalar member value

=back

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_remove_member : Defer ($k, $m) {
    my @keys_before  = keys $data{$k}->%*;
    $data{$k} = { map { $data{$k}->{$_} !~ /$m/ ? ($_ => $data{$k}->{$_}) : ()  } keys $data{$k}->%* };
    my @keys_after = keys $data{$k}->%*;
    return 0 + @keys_before - @keys_after;
}

=head2 orderedset_remove_byscore

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $min >> - the minimum score to remove

=item * C<< $max >> - the maximum score to remove

=back

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_remove_byscore : Defer ($k, $min, $max) {
    $min = -100000 if $min =~ /-inf/;
    $max = 100000 if $max =~ /\+inf/;
    my @keys_before  = keys $data{$k}->%*;
    $data{$k} = { map { ($_ >= $min and $_ <= $max ) ? () : ($_ => $data{$k}->{$_})  } keys $data{$k}->%* };
    my @keys_after = keys $data{$k}->%*;
    return 0 + @keys_before - @keys_after;

}

=head2 orderedset_member_count

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $min >> - minimum score for selection

=item * C<< $max >> - maximum score for selection

=back

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_member_count : Defer ($k, $min, $max) {
    $min = -100000 if $min =~ /-inf/;
    $max = 100000 if $max =~ /\+inf/;
    return scalar map { ($_ >= $min and $_ <= $max) ? (1) : ()  } keys $data{$k}->%*;
}

=head2 orderedset_members

Takes the following parameters:

=over 4

=item * C<< $k >> - the relative key in storage

=item * C<< $min >> - minimum score for selection

=item * C<< $max >> - maximum score for selection

=back

Returns a L<Future> which will resolve on completion.

=cut

async method orderedset_members : Defer ($k, $min = '-inf', $max = '+inf', $with_score = 0) {
    $min = -100000 if $min =~ /-inf/;
    $max = 100000 if $max =~ /\+inf/;
    return [ map { ($_ >= $min and $_ <= $max ) ? $with_score ? ($data{$k}->{$_}, $_) : ($data{$k}->{$_}) : ()  } sort keys $data{$k}->%* ];
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

