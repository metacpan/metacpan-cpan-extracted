package Net::Amazon::MechanicalTurk::Command::AddRetry;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::Command::AddRetry - Adds retry support for MechanicalTurk API calls.

This module adds the addRetry method to the Net::Amazon::MechanicalTurk class.

=head1 SYNOPSIS

    # Tells the MechanicalTurk client to retry API calls for all operations,
    # up to 5 times with 10 second interval delays, any time a ServiceUnavailable 
    # error occurs.

    $mturk->addRetry(
        operations => qr/./i,
        errorCodes => qr/ServiceUnavailable/i,
        maxTries   => 5,
        delay      => 10
    );

=head1 C<addRetry>

addRetry

Add retry for operations based on error codes. The following parameters
are required:

    operations - A regular expression matching the operations the retry should be for.
    errorCodes - A regular expression matching the errorCodes the retry should be for.
    maxTries   - The maximum number of times the operation will be retried, before
                 letting the error propogate.
    delay      - The number of seconds to wait between each retry.  The number may be
                 fractional.

Note: using the qr// operator to pass regular expressions is the preferred method.

=cut 

sub addRetry {
    my $mturk = shift;
    my %params = @_;
    foreach my $param (qw{ errorCodes operations delay maxTries }) {
        if (!exists $params{$param}) {
            Carp::croak("Missing required parameter $param.");
        }
    }
    if ($params{maxTries} < 1) {
        Carp::croak("Invalid value for maxTries $params{maxTries}.");
    }
    $mturk->filterChain->addFilter(\&retryCallFilter, \%params);
}

sub retryCallFilter {
    my ($chain, $targetParams, $retryParams) = @_;
    my ($mturk, $operation, $callParams) = @$targetParams;
    
    if ($operation =~ $retryParams->{operations}) {
        my $count = 0;
        while (1) {
            $count++;
            my $result = eval { $chain->() };
            if ($@) {
                if ($count >= $retryParams->{maxTries}) {
                    die $@;
                }
                my $error = ($mturk->response) ? $mturk->response->errorCode : '';
                if (defined($error) and $error =~ $retryParams->{errorCodes}) {
                    warn "Operation $operation failed with error $error.\n" .
                         "$@\n" .
                         "Will retry after " . $retryParams->{delay} . " seconds.\n";
                    # Work-around to sleep for fractional seconds.
                    select(undef, undef, undef, $retryParams->{delay});
                }
                else {
                    die $@;
                }
            }
            else {
                return $result;
            }
        }
    }
    else {
        return $chain->();
    }
}

return 1;
