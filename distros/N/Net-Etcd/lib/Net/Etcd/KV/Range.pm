use utf8;
package Net::Etcd::KV::Range;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::Range

=cut

our $VERSION = '0.021';

=head1 DESCRIPTION

Range gets the keys in the range from the key-value store.

=head1 ACCESSORS

=head2 endpoint

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
);

=head2 key

key is the first key for the range. If range_end is not given, the request only looks up key.
the key is encoded with base64.  type bytes

=cut

has key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) }
);

=head2 range_end

range_end is the upper bound on the requested range [key, range_end). If range_end is '\0',
the range is all keys >= key. If the range_end is one bit larger than the given key, then
the range requests get the all keys with the prefix (the given key). If both key and
range_end are '\0', then range requests returns all keys. the key is encoded with base64.
type bytes.  NOTE: If range_end is not given, the request only looks up key.

=cut

has range_end => (
    is     => 'ro',
    isa    => Str,
    coerce => sub { return encode_base64( $_[0], '' ) }
);

=head2 prev_key

If prev_kv is set, etcd gets the previous key-value pairs before deleting it. The previous key-value
pairs will be returned in the delete response.  This is only used for delete.

=cut

has prev_key => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);


=head2 limit

limit is a limit on the number of keys returned for the request. type int64

=cut

has limit => (
    is  => 'ro',
    isa => Int,
);

=head2 revision

revision is the point-in-time of the key-value store to use for
the range. If revision is less or equal to zero, the range is over
the newest key-value store. If the revision has been compacted,
ErrCompaction is returned as a response. type int64

=cut

has revision => (
    is  => 'ro',
    isa => Int,
);

=head2 sort_order

sort_order is the order for returned sorted results.

=cut

has sort_order => (
    is  => 'ro',
    isa => Int,
);

=head2 sort_target

sort_target is the key-value field to use for sorting.

=cut

has sort_target => (
    is  => 'ro',
    isa => Str,
);

=head2 serializable

serializable sets the range request to use serializable member-local reads.
Range requests are linearizable by default; linearizable requests have higher
latency and lower throughput than serializable requests but reflect the current
consensus of the cluster. For better performance, in exchange for possible stale
reads, a serializable range request is served locally without needing to reach
consensus with other nodes in the cluster.

=cut

has serializable => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);

=head2 keys_only

keys_only when set returns only the keys and not the values.

=cut

has keys_only => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);

=head2 count_only

count_only when set returns only the count of the keys in the range.

=cut

has count_only => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);

=head2 min_mod_revision

min_mod_revision is the lower bound for returned key mod revisions;
all keys with lesser mod revisions will be filtered away.

=cut

has min_mod_revision => (
    is  => 'ro',
    isa => Int,
);

=head2 max_mod_revision

max_mod_revision is the upper bound for returned key mod revisions;
all keys with greater mod revisions will be filtered away.

=cut

has max_mod_revision => (
    is  => 'ro',
    isa => Int,
);

=head2 min_create_revision

min_create_revision is the lower bound for returned key create revisions;
all keys with lesser create revisions will be filtered away.

=cut

has min_create_revision => (
    is  => 'ro',
    isa => Int,
);

=head2 max_create_revision

max_create_revision is the upper bound for returned key create revisions;
all keys with greater create revisions will be filtered away.

=cut

has max_create_revision => (
    is  => 'ro',
    isa => Int,
);

1;
