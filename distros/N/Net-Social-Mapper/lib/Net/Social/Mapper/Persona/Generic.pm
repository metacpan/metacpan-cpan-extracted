package Net::Social::Mapper::Persona::Generic;

use strict;
use base qw(Net::Social::Mapper::Persona);
use Feed::Find;

=head1 NAME

Net::Social::Mapper::Persona::Generic - the persona for a generic service

=head2 SYNOPSIS

See C<Net::Social::Mapper>

=cut

sub _init {
    my $self    = shift;
    my $sitemap = $self->mapper->sitemap;
    my $profile = $sitemap->profile($self->{service}, $self->{user}) || return;
    $self->{$_} = $profile->{$_} for keys %$profile;
    return $self;
}

=head2 feeds

Get the feeds for this website.

=cut
sub feeds {
    my $self = shift;
    $self->{feeds} = [ $self->mapper->_get_feeds($self->{homepage}) ] unless defined $self->{feeds};
    return $self->SUPER::feeds;
}

1;

