package POE::Component::Server::Bayeux::Message;

=head1 NAME

POE::Component::Server::Bayeux::Client::Message - An object representing a single message of a request

=head1 DESCRIPTION

Used internally by L<POE::Component::Server::Bayeux::Request>.

This is the parent class of the different message types (Meta, Service, Publish, by default).
Each message can override or call via SUPER the object methods here.

=cut

use strict;
use warnings;

use Params::Validate qw(validate validate_with);
use base qw(Class::Accessor);

=head1 METHODS

=head2 Accessors

=over 4

Accessors to this objects hashref.

=over 4

=item is_error

=item request

=back

=back

=cut

__PACKAGE__->mk_accessors(qw(
    is_error
    request
));

=head2 Data Accessors

=over 4

These access the named field in the message payload

=over 4

=item channel

=item version

=item minimumVersion

=item supportedConnectionTypes

=item clientId

=item advice

=item connectionType

=item id

=item timestamp

=item data

=item connectionId

=item successful

=item subscription

=item error

=item ext

=back

=back

=cut

# From '3. Message Field Definitions' of the protocol draft
__PACKAGE__->mk_data_accessors(qw(
    channel
    version
    minimumVersion
    supportedConnectionTypes
    clientId
    advice
    connectionType
    id
    timestamp
    data
    connectionId
    successful
    subscription
    error
    ext
));

## Class Methods ###

sub new {
    my $class = shift;

    my %args = validate(@_, {
        request => 1,
        data => 1,
    });

    return bless \%args, $class;
}

## Object Methods ###

=head2 server_config ()

=over 4

Returns the server's args

=back

=cut

sub server_config {
    my ($self) = @_;

    return $self->request->heap->{args};
}

=head2 pre_handle ()

=over 4

Called by the request before handle().  Enables the message to affect the
queueing of the other messages in the request, or do anything else it wants.

=back

=cut

sub pre_handle {
    my ($self) = @_;

    # do nothing
}

=head2 handle ()

=over 4

At a minimum, validates the fields of the message payload.  A message will usually
add a response in this block:

  $message->request->add_response({ successful => 1 });

=back

=cut

sub handle {
    my ($self) = @_;

    $self->validate_fields();
}

=head2 post_handle ()

=over 4

Like pre_handle(), but called after the handle() phase.

=back

=cut

sub post_handle {
    my ($self) = @_;

    # do nothing
}

=head2 validate_fields (%spec)

=over 4

Given a L<Params::Validate> spec, will test the payload for validity.  Failure
causes an error message stored in is_error().

=back

=cut

sub validate_fields {
    my ($self, %spec) = @_;

    %spec = (
        %spec,

        # Globally required
        channel => {
            regex => qr{^\S+$},
        },

        # Globally optional
        id  => 0,
        ext => 0,
    );

    eval { 
        validate_with(
            params => [ %{ $self->{data} } ],
            spec   => \%spec,
            on_fail => sub {
                my $error = shift;
                chomp $error;
                $self->is_error($error);
                die;
            },
            allow_extra => 1,
        )
    };
}

=head1 CLASS METHODS

=head2 new (..)

=over 4

Basic new() call, needs only 'request' and 'data'.

=back

=head2 payload

=over 4

Returns the message payload

=back

=cut

sub payload {
    my $self = shift;
    return $self->{data};
}

=head2 mk_data_accessors (@method_names)

=over 4

Generates object accessor methods for the named methods.  Supplements the generic
methods that are created for all message types.

=back

=cut

sub mk_data_accessors {
    my ($class, @accessors) = @_;

    foreach my $accessor (@accessors) {
        my $method_name = $class . '::' . $accessor;
        my $sub = sub {
            my ($self, $value) = @_;

            if (defined $value) {
                $self->{data}{$accessor} = $value;
                # Chain it
                return $self;
            }
            return $self->{data}{$accessor};
        };

        {
            no strict 'refs';
            *{ $method_name } = $sub;
        }
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
