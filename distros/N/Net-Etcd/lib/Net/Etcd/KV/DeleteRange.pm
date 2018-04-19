use utf8;
package Net::Etcd::KV::DeleteRange;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::DeleteRange

=cut

our $VERSION = '0.020';

=head1 DESCRIPTION

DeleteRange deletes the given range from the key-value store. A
delete request increments the revision of the key-value store and
generates a delete event in the event history for every deleted key.

=head1 ACCESSORS

=head2 endpoint

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/kv/deleterange'
);

=head2 key

key is the key, in bytes, to put into the key-value store.

=cut

has key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) },
);

=head2 prev_kv

If prev_kv is set, etcd gets the previous key-value pair before changing it.
The previous key-value pair will be returned in the put response.

=cut

has prev_kv => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
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

1;
