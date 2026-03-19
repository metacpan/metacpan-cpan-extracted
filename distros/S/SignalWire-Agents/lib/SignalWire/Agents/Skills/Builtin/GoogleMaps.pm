package SignalWire::Agents::Skills::Builtin::GoogleMaps;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('google_maps', __PACKAGE__);

has '+skill_name'        => (default => sub { 'google_maps' });
has '+skill_description' => (default => sub { 'Validate addresses and compute driving routes using Google Maps' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $lookup_name = $self->params->{lookup_tool_name} // 'lookup_address';
    my $route_name  = $self->params->{route_tool_name}  // 'compute_route';

    $self->define_tool(
        name        => $lookup_name,
        description => 'Look up and validate an address using Google Maps Geocoding',
        parameters  => {
            type       => 'object',
            properties => {
                address  => { type => 'string', description => 'Address to look up' },
                bias_lat => { type => 'number', description => 'Latitude bias' },
                bias_lng => { type => 'number', description => 'Longitude bias' },
            },
            required => ['address'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Address lookup for: $args->{address}"
            );
        },
    );

    $self->define_tool(
        name        => $route_name,
        description => 'Compute a driving route between two points',
        parameters  => {
            type       => 'object',
            properties => {
                origin_lat => { type => 'number', description => 'Origin latitude' },
                origin_lng => { type => 'number', description => 'Origin longitude' },
                dest_lat   => { type => 'number', description => 'Destination latitude' },
                dest_lng   => { type => 'number', description => 'Destination longitude' },
            },
            required => ['origin_lat', 'origin_lng', 'dest_lat', 'dest_lng'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Route computed from ($args->{origin_lat},$args->{origin_lng}) to ($args->{dest_lat},$args->{dest_lng})"
            );
        },
    );
}

sub get_hints {
    return ['address', 'location', 'route', 'directions', 'miles', 'distance'];
}

sub _get_prompt_sections {
    return [{
        title   => 'Google Maps',
        body    => '',
        bullets => [
            'Use lookup_address to validate and geocode addresses',
            'Use compute_route to get driving directions between two points',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        api_key          => { type => 'string', required => 1, hidden => 1 },
        lookup_tool_name => { type => 'string', default => 'lookup_address' },
        route_tool_name  => { type => 'string', default => 'compute_route' },
    };
}

1;
