package Shipment::Sendle::API;

use Mouse;

with 'Web::API';

our $VERSION = '0.1';

has 'mode' => (
    is      => 'ro',
    default => 'sandbox',
);

has 'idempotency_key' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return time },
    trigger => sub {
        my ($self, $new_value) = @_;
        $self->header({'Idempotency-Key' => $new_value});
    },
);

sub new_request {
    my $self = shift;
    $self->idempotency_key(time);
    return;
}

has 'commands' => (
    is      => 'rw',
    default => sub {
        {   ping  => {method => 'GET'},
            quote => {
                method             => 'GET',
                default_attributes => {
                    pickup_country   => 'US',
                    delivery_country => 'US',
                    weight_units     => 'lb',
                },
                mandatory => [
                    'pickup_postcode',   'pickup_suburb',
                    'delivery_postcode', 'delivery_suburb',
                    'weight_value',
                ],
            },
            create_order => {
                method             => 'POST',
                path               => 'orders',
                default_attributes => {
                    first_mile_option          => 'drop off',
                    'sender.address.country'   => 'United States',
                    'receiver.address.country' => 'United States',
                },
                mandatory => [
                    'description',
                    'weight.value',
                    'weight.units',
                    'sender.contact.name',
                    'sender.address.address_line1',
                    'sender.address.suburb',
                    'sender.address.postcode',
                    'sender.address.state_name',
                    'receiver.instructions',
                    'receiver.contact.name',
                    'receiver.address.address_line1',
                    'receiver.address.suburb',
                    'receiver.address.postcode',
                    'receiver.address.state_name',
                ],
            },
            view_order => {
                method => 'GET',
                path   => 'orders/:id',
            },
            _label => {
                method => 'GET',
                path   => 'orders/:id/labels/:type',
            },
            track_order => {
                method => 'GET',
                path   => 'tracking/:ref',
            },
            cancel_order => {
                method => 'DELETE',
                path   => 'orders/:id',
            },

        };
    },
);

sub label {
    my ($self, %args) = @_;
    Shipment::Sendle::API->new(
        user    => $self->user,
        api_key => $self->api_key,
        mode    => $self->mode,
        debug   => $self->debug,
        decoder => sub { {} },
    )->_label(id => $args{id}, type => $args{type});
}

sub commands {
    my ($self) = @_;
    return $self->commands;
}

sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $VERSION);
    if ($self->mode eq 'live') {
        $self->base_url('https://api.sendle.com/api');
    }
    else {
        $self->base_url('https://sandbox.sendle.com/api');
    }
    $self->content_type('application/json');
    $self->auth_type('basic');
    $self->header({'Idempotency-Key' => $self->idempotency_key});

    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Sendle::API

=head1 VERSION

version 3.11

=head1 AUTHOR

Andrew Baerg @ <andrew at pullingshots dot ca>

http://pullingshots.ca/

=head1 BUGS

Please contact me directly.

=head1 COPYRIGHT

Copyright (C) 2021 Andrew J Baerg, All Rights Reserved

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Andrew Baerg <baergaj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
