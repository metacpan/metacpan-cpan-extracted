package SignalWire::Agents::Skills::Builtin::PlayBackgroundFile;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('play_background_file', __PACKAGE__);

has '+skill_name'        => (default => sub { 'play_background_file' });
has '+skill_description' => (default => sub { 'Control background file playback' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'play_background_file';
    my $files     = $self->params->{files} // [];

    # Build action enum from file keys
    my @actions = ('stop');
    for my $f (@$files) {
        push @actions, "start_$f->{key}" if $f->{key};
    }

    # DataMap-style registration with expressions
    $self->agent->register_swaig_function({
        function    => $tool_name,
        description => "Control background file playback for $tool_name",
        parameters  => {
            type       => 'object',
            properties => {
                action => {
                    type        => 'string',
                    description => 'Playback action',
                    enum        => \@actions,
                },
            },
            required => ['action'],
        },
        data_map => {
            expressions => [
                {
                    string  => '${args.action}',
                    pattern => 'stop',
                    output  => {
                        response => 'Stopping background playback.',
                        action   => [{ stop_background_file => {} }],
                    },
                },
            ],
        },
    });
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        files     => { type => 'array', required => 1, description => 'Array of file objects with key, description, url' },
        tool_name => { type => 'string', default => 'play_background_file' },
    };
}

1;
