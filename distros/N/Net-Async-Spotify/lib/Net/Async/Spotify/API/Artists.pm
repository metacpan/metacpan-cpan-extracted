package Net::Async::Spotify::API::Artists;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use mro;
use parent qw(Net::Async::Spotify::API::Generated::Artists);

=encoding utf8

=head1 NAME

Net::Async::Spotify::API::Artists - Package representing Main Spotify Artists API

=head1 DESCRIPTION

Main module for an Autogenerated one L<Net::Async::Spotify::API::Generated::Artists>.
Will hold all extra functionality for Spotify Artists API

=head1 METHODS

=cut

sub new {
    my $self  = (shift)->next::method(@_);
    $self->mapping->{get_an_artists_albums}{response} = ['Album'];
    return $self;
}

1;
