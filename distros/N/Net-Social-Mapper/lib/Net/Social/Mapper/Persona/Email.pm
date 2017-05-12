package Net::Social::Mapper::Persona::Email;

use strict;
use base qw(Net::Social::Mapper::Persona);
use Email::Address;

=head1 NAME

Net::Social::Mapper::Persona::Email - the persona for an email address

=head2 SYNOPSIS 

See C<Net::Social::Mapper>

=cut
sub _init {
    my $self           = shift;
    $self->{service}   = 'email';
    $self->{name}      = 'Email';
    my ($address)      = Email::Address->parse($self->{user});
    $self->{full_name} = $address->name; # might as well try
    $self->{domain}    = $address->host;
    $self->{id}        = $address->user;    
    $self->{user}      = $address->address;
    return $self;
}

=head2 persona_name 

The short canonical name for this persona

=cut
sub persona_name { shift->_do('user', @_) }
1;
