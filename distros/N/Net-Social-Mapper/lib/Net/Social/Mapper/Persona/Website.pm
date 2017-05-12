package Net::Social::Mapper::Persona::Website;

use strict;
use base qw(Net::Social::Mapper::Persona);
use URI;
use Feed::Find;

=head1 NAME

Net::Social::Mapper::Persona::Website - the persona for a website

=head2 SYNOPSIS

See C<Net::Social::Mapper>

=cut
sub _init {
    my $self  = shift;
    $self->{service}  = 'website';
    $self->{name}     = 'Website';
    my $url           = $self->_normalise_url($self->{user}) || return undef;
    $self->{user}     = $url->as_string;
    $self->{user}     =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $self->{homepage} = $self->{user};
    $self->{domain}   = $url->authority;
    return $self;
}

=head2 feeds 

Get the feeds for this website.

=cut
sub feeds {
    my $self  = shift;
    $self->{feeds} = [ $self->mapper->_get_feeds($self->{homepage}) ] unless defined $self->{feeds}; 
    return $self->SUPER::feeds();
}

sub _normalise_url {
    my $self = shift;
    my $url  = shift || return;
    $url     = "http://$url" unless $url =~ m![a-z]+:\/\/!i;
    $url     = URI->new($url);
}

=head2 persona_name

The short canonical name for this persona

=cut
sub persona_name { shift->_do('user', @_) }
1;

