package Pinwheel::Cache::Null;

use strict;
use warnings;

sub new
{
    my $class = shift;
    return bless({}, $class);
}

sub get
{
    return undef;
}

sub set
{
    return 0;
}

sub remove
{
    return 0;
}

sub clear
{
    return 1;
}


1;

__DATA__

=head1 NAME

Pinwheel::Cache::Null

=head1 DESCRIPTION

Null cache implementation of the Cache::Cache API (nothing is cached).

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

