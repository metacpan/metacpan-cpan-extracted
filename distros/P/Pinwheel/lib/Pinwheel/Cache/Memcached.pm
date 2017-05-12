package Pinwheel::Cache::Memcached;

use strict;
use warnings;

use Cache::Memcached;

our @ISA = qw(Cache::Memcached);


sub new
{
    my($class, %options) = @_;

    # Use localhost cache by default
    $options{'servers'} = ['127.0.0.1:11211'] unless ($options{'servers'});

    my $self = $class->SUPER::new(%options);
    bless $self, $class; # Bless into this class

    return $self;
}

sub remove
{
    my $self = shift;
    $self->delete(@_);
}

sub clear
{
    my $self = shift;
    $self->flush_all();
}


1;

__DATA__

=head1 NAME

Pinwheel::Cache::Memcached

=head1 DESCRIPTION

Lightweight subclass of Cache::Memcached to make it implement more of the Cache::Cache API.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

