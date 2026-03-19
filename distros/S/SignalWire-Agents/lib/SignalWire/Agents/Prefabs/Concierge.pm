package SignalWire::Agents::Prefabs::Concierge;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
extends 'SignalWire::Agents::Agent::AgentBase';

has venue_name           => (is => 'ro', required => 1);
has services             => (is => 'ro', default => sub { [] });
has amenities            => (is => 'ro', default => sub { {} });
has hours_of_operation   => (is => 'ro', default => sub { {} });
has special_instructions => (is => 'ro', default => sub { [] });
has welcome_message      => (is => 'ro', default => sub { undef });

sub BUILD {
    my ($self, $args) = @_;

    $self->name('concierge')  if $self->name eq 'agent';
    $self->route('/concierge') if $self->route eq '/';
    $self->use_pom(1);

    my $welcome = $self->welcome_message
        // "Welcome to ${\$self->venue_name}. How can I assist you today?";

    $self->set_global_data({
        venue_name  => $self->venue_name,
        services    => $self->services,
        amenities   => $self->amenities,
    });

    $self->prompt_add_section(
        'Concierge Role',
        "You are the virtual concierge for ${\$self->venue_name}. $welcome",
        bullets => [
            'Welcome users and explain available services',
            'Answer questions about amenities, hours, and directions',
            'Help with bookings and reservations',
            'Provide personalized recommendations',
        ],
    );

    # Services
    if (@{ $self->services }) {
        $self->prompt_add_section(
            'Available Services',
            '',
            bullets => $self->services,
        );
    }

    # Amenities
    if (%{ $self->amenities }) {
        my @amenity_bullets;
        for my $name (sort keys %{ $self->amenities }) {
            my $info = $self->amenities->{$name};
            my $desc = "$name";
            $desc .= " - Hours: $info->{hours}" if $info->{hours};
            $desc .= " - Location: $info->{location}" if $info->{location};
            push @amenity_bullets, $desc;
        }
        $self->prompt_add_section(
            'Amenities',
            '',
            bullets => \@amenity_bullets,
        );
    }

    # Hours
    if (%{ $self->hours_of_operation }) {
        my @hour_bullets;
        for my $day (sort keys %{ $self->hours_of_operation }) {
            push @hour_bullets, "$day: $self->{hours_of_operation}{$day}";
        }
        $self->prompt_add_section(
            'Hours of Operation',
            '',
            bullets => \@hour_bullets,
        );
    }

    # Special instructions
    if (@{ $self->special_instructions }) {
        $self->prompt_add_section(
            'Special Instructions',
            '',
            bullets => $self->special_instructions,
        );
    }

    # Register check availability tool
    $self->define_tool(
        name        => 'check_availability',
        description => 'Check availability for a service or amenity',
        parameters  => {
            type       => 'object',
            properties => {
                service => { type => 'string', description => 'Service or amenity to check' },
                date    => { type => 'string', description => 'Date to check (optional)' },
            },
            required => ['service'],
        },
        handler => sub {
            my ($a, $raw) = @_;
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Checking availability for $a->{service} at ${\$self->venue_name}",
            );
        },
    );
}

1;
