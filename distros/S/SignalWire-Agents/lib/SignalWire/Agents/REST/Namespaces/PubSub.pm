package SignalWire::Agents::REST::Namespaces::PubSub;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub create_token {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

1;
