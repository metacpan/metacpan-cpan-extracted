package Net::Payjp::Token;

use strict;
use warnings;

use base 'Net::Payjp';

sub create{
    my $self = shift;
    my %p = @_;

    $self->_request(method => 'POST', url => $self->_class_url, param => \%p);
}

sub retrieve{
    my $self = shift;
    my $id = shift;
    $self->id($id) if $id;

    $self->_request(method => 'GET', url => $self->_instance_url);
}

1;
