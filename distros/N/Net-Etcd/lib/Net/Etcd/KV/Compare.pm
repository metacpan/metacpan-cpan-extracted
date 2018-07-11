use utf8;
package Net::Etcd::KV::Compare;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use Data::Dumper;
use JSON;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::KV::Compare

=cut

our $VERSION = '0.021';

=head1 DESCRIPTION

Op


=head1 ACCESSORS

=head2 result

result is logical comparison operation for this comparison.

=cut

has result => (
    is       => 'ro',
);

=head2 target

target is the key-value field to inspect for the comparison.

=cut

has target => (
    is     => 'ro',
);

=head2 key 

key is the subject key for the comparison operation.

=cut

has key => (
    is     => 'ro',
    coerce => sub { return encode_base64( $_[0], '' ) if $_[0] },
);


=head2 version

version is the version of the given key

=cut

has version => (
    is      => 'ro',
);

=head2 create_revision 

create_revision is the creation revision of the given key

=cut

has create_revision => (
    is     => 'ro',
);

=head2 mod_revision 

mod_revision is the last modified revision of the given key.

=cut

has mod_revision => (
    is       => 'ro',
);

=head2 value 

value is the value of the given key, in bytes.

=cut

has value => (
    is     => 'ro',
    coerce => sub { return encode_base64( $_[0], '' ) if $_[0] },
);

1;
