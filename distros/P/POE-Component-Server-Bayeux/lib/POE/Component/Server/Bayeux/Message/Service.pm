package POE::Component::Server::Bayeux::Message::Service;

=head1 NAME

POE::Component::Server::Bayeux::Message::Service - handles /service/ channels

=head1 DESCRIPTION

Subclasses L<POE::Component::Server::Bayeux::Message> to implement the /service/* channels.
Does nothing by itself, as the Bayeux protocol doesn't define any specific services.  Implements named services from the server config 'Services' - see the docs there.

=cut

use strict;
use warnings;
use base qw(POE::Component::Server::Bayeux::Message);

__PACKAGE__->mk_accessors(qw(method handler));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # Extract and save the service method and handler

    my ($method) = $self->channel =~ m{^/service/(.+)$};
    if (! $method) {
        $self->request->error("Must provide service method");
        return;
    }
    my $handler = $method;

    my $known_methods = $self->server_config->{Services};

    # Allow for generic _handler handler
    if (! $known_methods->{$method} && $known_methods->{_handler}) {
        $handler = '_handler';
    }
    elsif (! $known_methods->{$method}) {
        $self->request->error("Invalid service method $method");
        return;
    }

    $self->method($method);
    $self->handler($handler);

    return $self;
}

sub handle {
    my ($self) = @_;

    # Class handle() will call validate_fields()
    $self->SUPER::handle();

    my @responses;

    if (! $self->is_error) {
        my $service_definition = $self->server_config->{Services}{ $self->handler };
        if (ref $service_definition && ref $service_definition eq 'CODE') {
            my @result;
            eval {
                @result = $service_definition->($self);
            };
            if (my $ex = $@) {
                my $text;
                if (ref($ex) && $ex->can('error')) {
                    $text = $ex->error;
                }
                else {
                    $text = $ex . '';
                }
                $self->is_error("Failed to execute method '".$self->handler."' coderef: $text");
            }
            push @responses, @result if @result;
        }
    }

    if ($self->is_error) {
        push @responses, {
            successful => JSON::XS::false,
            error => $self->is_error,
        };
    }

    foreach my $response (@responses) {
        $response->{channel} ||= $self->channel;
        $response->{id} ||= $self->id if $self->id;
        $self->request->add_response($response);
    }
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
