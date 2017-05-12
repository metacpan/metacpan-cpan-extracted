package Tapper::Producer;
# git description: v5.0.0-1-gd41b1d5

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Precondition producers (base class)
$Tapper::Producer::VERSION = '5.0.1';
use warnings;
use strict;

use Moose;


sub produce
{
        my ($self, $job, $precond_hash) = @_;

        my $producer_name = $precond_hash->{producer};

        eval "use Tapper::Producer::$producer_name"; ## no critic (ProhibitStringyEval)
        die "Can not load producer '$producer_name': $@" if $@;

        my $producer = "Tapper::Producer::$producer_name"->new();
        return $producer->produce($job, $precond_hash);
}

1; # End of Tapper::Producer

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Producer - Tapper - Precondition producers (base class)

=head1 Functions

=head2 produce

Get the requested producer, call it and return the new precondition(s)
returned by it.

@param testrunscheduling result object - testrun this precondition belongs to
@param hash ref                        - producer precondition

@return success - hash ref containing list of new preconditions and a
                  new topic (optional)

@throws die()

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
