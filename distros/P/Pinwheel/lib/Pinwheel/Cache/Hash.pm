package Pinwheel::Cache::Hash;

use strict;
use warnings;

sub new
{
    my $class = shift;
    return bless({store => {}}, $class);
}

sub get
{
    my ($self, $key) = @_;
    return $self->{store}{$key};
}

sub set
{
    my ($self, $key, $value, $expires) = @_;
    $self->{store}{$key} = $value;
    return 1;
}

sub remove
{
    my ($self, $key, $time) = @_;
    delete $self->{store}{$key};
}

sub clear
{
    my ($self) = @_;
    $self->{store} = {};
    return 1;
}


1;

__DATA__

=head1 NAME

Pinwheel::Cache::Hash

=head1 DESCRIPTION

Basic in-memory implementation of the Cache::Cache API.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

