use utf8;
package Net::Etcd::KV::Txn;

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

Net::Etcd::KV::Txn

=cut

our $VERSION = '0.018';

=head1 DESCRIPTION

Txn processes multiple requests in a single transaction. A txn request increments
the revision of the key-value store and generates events with the same revision for
every completed request. It is not allowed to modify the same key several times
within one txn.
From google paxosdb paper: Our implementation hinges around a powerful primitive which
we call MultiOp. All other database operations except for iteration are implemented as
a single call to MultiOp. A MultiOp is applied atomically and consists of three components:

  1. A list of tests called guard. Each test in guard checks a single entry in the database.
  It may check for the absence or presence of a value, or compare with a given value. Two
  different tests in the guard may apply to the same or different entries in the database.
  All tests in the guard are applied and MultiOp returns the results. If all tests are true,
  MultiOp executes t op (see item 2 below), otherwise it executes f op (see item 3 below).
  
  2. A list of database operations called t op. Each operation in the list is either an insert,
  delete, or lookup operation, and applies to a single database entry. Two different operations
  in the list may apply to the same or different entries in the database. These operations are
  executed if guard evaluates to true.
  
  3. A list of database operations called f op. Like t op, but executed if guard evaluates to false.

=head1 ACCESSORS

=head2 endpoint

    /v3alpha/kv/txn

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/kv/txn'
);

=head2 compare

compare is a list of predicates representing a conjunction of terms. If the comparisons
succeed, then the success requests will be processed in order, and the response will
contain their respective responses in order. If the comparisons fail, then the failure
requests will be processed in order, and the response will contain their respective
responses in order.

=cut

has compare => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

=head2 success

success is a list of requests which will be applied when compare evaluates to true.

=cut

has success => (
    is     => 'ro',
    isa    => ArrayRef,
);

=head2 failure

failure is a list of requests which will be applied when compare evaluates to false.

=cut

has failure => (
    is     => 'ro',
    isa    => ArrayRef,
);

=head1 PUBLIC METHODS

=head2 create

create txn

=cut

#TODO hack alert

sub create {
    my $self = shift;
    my $compare = $self->compare;
    my $success = $self->success;
    my $failure = $self->failure;

    my $txn ='"compare":[' . join(',',@$compare) . '],';
    $txn .= '"success":[' . join(',', @$success) . ']' if defined $success;
    $txn .= ',' if defined $success and defined $failure;
    $txn .= '"failure":[ ' . join(',', @$failure) . ']' if defined $failure;
    $self->{json_args} = '{'  . $txn . '}';
#   print STDERR Dumper($self);
    $self->request;
    return $self;
}

1;
