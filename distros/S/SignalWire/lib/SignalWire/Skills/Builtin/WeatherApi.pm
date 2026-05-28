package SignalWire::Skills::Builtin::WeatherApi;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('weather_api', __PACKAGE__);

has '+skill_name'        => (default => sub { 'weather_api' });
has '+skill_description' => (default => sub { 'Get current weather information from WeatherAPI.com' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'get_weather';
    my $api_key   = $self->params->{api_key}   // '';
    my $unit      = $self->params->{temperature_unit} // 'fahrenheit';

    my $temp_field = $unit eq 'celsius' ? 'temp_c' : 'temp_f';
    my $feels_field = $unit eq 'celsius' ? 'feelslike_c' : 'feelslike_f';
    my $unit_label  = $unit eq 'celsius' ? 'C' : 'F';

    # Honor WEATHER_API_BASE_URL env var so the audit fixture
    # (audit_skills_dispatch.py) can redirect us at a local HTTP server.
    # When unset we use the canonical
    # https://api.weatherapi.com/v1/current.json URL. Either way the
    # `current.json` path component is preserved (the audit's
    # expected_path_substring is `current.json`).
    my $base = $ENV{WEATHER_API_BASE_URL};
    my $url;
    if ($base) {
        $base =~ s{/+$}{};
        $url = "$base/v1/current.json?key=${api_key}&q=\${lc:enc:args.location}&aqi=no";
    } else {
        $url = "https://api.weatherapi.com/v1/current.json?key=${api_key}&q=\${lc:enc:args.location}&aqi=no";
    }

    $self->agent->register_swaig_function({
        function    => $tool_name,
        description => 'Get current weather information for any location',
        parameters  => {
            type       => 'object',
            properties => {
                location => { type => 'string', description => 'Location to get weather for' },
            },
            required => ['location'],
        },
        data_map => {
            webhooks => [{
                method => 'GET',
                url    => $url,
                output => {
                    response => "Temperature: \${current.${temp_field}}${unit_label}, "
                              . "Feels like: \${current.${feels_field}}${unit_label}, "
                              . "Condition: \${current.condition.text}, "
                              . "Humidity: \${current.humidity}%, "
                              . "Wind: \${current.wind_mph} mph",
                },
            }],
        },
    });
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        api_key          => { type => 'string', required => 1, hidden => 1 },
        tool_name        => { type => 'string', default => 'get_weather' },
        temperature_unit => { type => 'string', enum => ['fahrenheit', 'celsius'], default => 'fahrenheit' },
    };
}

1;
