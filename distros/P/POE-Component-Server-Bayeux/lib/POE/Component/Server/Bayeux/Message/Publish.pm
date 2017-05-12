package POE::Component::Server::Bayeux::Message::Publish;

=head1 NAME

POE::Component::Server::Bayeux::Message::Publish - handles non-special channels

=head1 DESCRIPTION

Subclasses L<POE::Component::Server::Bayeux::Message> to implement the non-special channels.  This will usually mean a publish to a channel, so a successfuly handled message will simply be passed to the server via $request->publish(), with a response given back to the requesting client.

=cut

use strict;
use warnings;
use JSON::Any qw(XS);
use base qw(POE::Component::Server::Bayeux::Message);

__PACKAGE__->mk_data_accessors(qw(data));

sub validate_fields {
    my ($self) = @_;

    $self->SUPER::validate_fields(
        data => 1,

        # Optional to require clientId on publish
        ($self->server_config->{AnonPublish} ?
            () : (
            clientId => 1,
        )),
    );
}

sub handle {
    my ($self) = @_;

    # Class handle() will call validate_fields()
    $self->SUPER::handle();
    return $self->handle_error() if $self->is_error();

    # Perform client acl (if client provided)
    my $client;
    if ($self->clientId) {
        $client = $self->request->client($self->clientId);
        $client->message_acl($self);
        return $self->handle_error() if $self->is_error();
    }

    $self->request->publish($self->clientId, $self->channel, $self->data);

    # Optional to respond to a publish
    $self->add_response({
        successful => JSON::XS::true,
    });
}

sub handle_error {
    my ($self, $error) = @_;

    my %response = (
        successful => JSON::XS::false,
        error => $error || $self->is_error || '',
    );

    return $self->add_response(\%response);
}

sub add_response {
    my ($self, $response) = @_;

    foreach my $key (qw(channel clientId id)) {
        $response->{$key} = $self->$key if defined $self->$key;
    }

    $self->request->add_response($response);
}

=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut
 
1;
