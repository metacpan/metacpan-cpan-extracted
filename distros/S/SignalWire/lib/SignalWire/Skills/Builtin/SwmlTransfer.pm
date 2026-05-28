package SignalWire::Skills::Builtin::SwmlTransfer;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('swml_transfer', __PACKAGE__);

has '+skill_name'        => (default => sub { 'swml_transfer' });
has '+skill_description' => (default => sub { 'Transfer calls between agents based on pattern matching' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name   = $self->params->{tool_name}   // 'transfer_call';
    my $description = $self->params->{description}  // 'Transfer call based on pattern matching';
    my $param_name  = $self->params->{parameter_name} // 'transfer_type';
    my $transfers   = $self->params->{transfers}    // {};

    my @patterns = keys %$transfers;

    # Build DataMap expressions from transfer patterns
    my @expressions;
    for my $pattern (@patterns) {
        my $cfg = $transfers->{$pattern};
        my $url = $cfg->{url} // $cfg->{address} // '';
        push @expressions, {
            string  => "\${args.$param_name}",
            pattern => $pattern,
            output  => {
                response => $cfg->{message} // "Transferring to $pattern",
                action   => [{ swml_transfer => $url }],
            },
        };
    }

    $self->agent->register_swaig_function({
        function    => $tool_name,
        description => $description,
        parameters  => {
            type       => 'object',
            properties => {
                $param_name => {
                    type        => 'string',
                    description => $self->params->{parameter_description} // 'The transfer destination',
                },
            },
            required => [$param_name],
        },
        data_map => { expressions => \@expressions },
    });
}

sub get_hints {
    my ($self) = @_;
    my @hints = ('transfer', 'connect', 'speak to', 'talk to');
    for my $pattern (keys %{ $self->params->{transfers} // {} }) {
        push @hints, split(/[\s_-]+/, $pattern);
    }
    return \@hints;
}

sub _get_prompt_sections {
    my ($self) = @_;
    my $transfers = $self->params->{transfers} // {};
    my @destinations = map { "- $_" } keys %$transfers;
    return [
        {
            title   => 'Transferring',
            body    => "Available transfer destinations:\n" . join("\n", @destinations),
        },
        {
            title   => 'Transfer Instructions',
            body    => 'When the user wants to be transferred, use the transfer tool.',
        },
    ];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        transfers             => { type => 'object', required => 1 },
        description           => { type => 'string' },
        parameter_name        => { type => 'string', default => 'transfer_type' },
        parameter_description => { type => 'string' },
        default_message       => { type => 'string' },
    };
}

1;
