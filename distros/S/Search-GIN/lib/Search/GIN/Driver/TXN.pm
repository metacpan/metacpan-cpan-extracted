use strict;
use warnings;
package Search::GIN::Driver::TXN;

our $VERSION = '0.11';

use Moose::Role;
use Scope::Guard;
use Carp qw(croak);
use namespace::autoclean;

with qw(Search::GIN::Driver);

requires qw(txn_begin txn_commit txn_rollback);

has current_transaction => (
    isa => "Any",
    is  => "rw",
    writer => "set_current_transaction",
    predicate => "has_current_transaction",
    clearer => "clear_current_transaction",
);

sub txn_do {
    my ( $self, $coderef ) = ( shift, shift );

    ref $coderef eq 'CODE' or croak '$coderef must be a CODE reference';

    my ( $txn, $scope_guard );

    if ( $self->has_current_transaction ) {
        my $prev = $self->current_transaction;
        $txn = $self->txn_begin($prev);
        $scope_guard = Scope::Guard->new(sub { $self->set_current_transaction($prev) });
    } else {
        $txn = $self->txn_begin;
        $scope_guard = Scope::Guard->new(sub { $self->clear_current_transaction() });
    }

    my @result;
    my $want_array = wantarray;

    my $err = do {
        local $@;
        eval {
            if ( $want_array ) {
                @result = $coderef->(@_);
            } elsif( defined $want_array ) {
                $result[0] = $coderef->(@_);
            } else {
                $coderef->(@_);
            }

            $self->txn_commit($txn);

            1;
        };

        $@
    };

    if ( !$err ) {
        return $want_array ? @result : $result[0];
    } else {
        my $rollback_exception = do {
            local $@;
            eval { $self->txn_rollback($txn) };
            $@;
        };

        if ($rollback_exception) {
            croak "Transaction aborted: $err, rollback failed: $rollback_exception";
        } else {
            die $err;
        }
    }
}

1;
