use utf8;
package Net::Etcd::KV::Op;

use strict;
use warnings;

use Moo;
use Types::Standard qw(InstanceOf Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use Data::Dumper;
use JSON;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::KV::Op

=cut

our $VERSION = '0.017';

=head1 DESCRIPTION

Op

=head1 ACCESSORS

=head2 request_range

=cut

has request_range => (
    is       => 'ro',
);

=head2 request_put 

=cut

has request_put => (
    is     => 'ro',
);

=head2 request_delete_range 

=cut

has request_delete_range => (
    is     => 'ro',
);

=head2 create

create op

=cut

#TODO this dirty hack should be a perl data object and then make json.

sub create {
    my $self = shift;
    my @op;
    my $put = $self->request_put;
    my $range = $self->request_range;
    my $delete_range = $self->request_delete_range;
    push @op, '{"requestPut":' . $put->json_args . '}' if defined $put;
    push @op, '{"requestRange":' . $range->json_args . '}' if defined $range;
    push @op, '{"requestDeleteRange":' . $delete_range->json_args . '}' if defined $delete_range;
    return @op;
}

1;
