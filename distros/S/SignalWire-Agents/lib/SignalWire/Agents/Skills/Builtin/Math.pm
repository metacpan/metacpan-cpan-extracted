package SignalWire::Agents::Skills::Builtin::Math;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('math', __PACKAGE__);

has '+skill_name'        => (default => sub { 'math' });
has '+skill_description' => (default => sub { 'Perform basic mathematical calculations' });
has '+supports_multiple_instances' => (default => sub { 0 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;

    $self->define_tool(
        name        => 'calculate',
        description => 'Perform a mathematical calculation with basic operations (+, -, *, /, %, **)',
        parameters  => {
            type       => 'object',
            properties => {
                expression => { type => 'string', description => 'Mathematical expression to evaluate' },
            },
            required => ['expression'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::Agents::SWAIG::FunctionResult;
            my $expr = $args->{expression} // '';

            # Safe evaluation: only allow numbers and basic operators
            if ($expr =~ /^[\d\s\+\-\*\/\%\.\(\)\^]+$/) {
                $expr =~ s/\^/**/g;  # Convert ^ to **
                my $result = eval { no strict; no warnings; eval $expr };
                if (defined $result && !$@) {
                    return SignalWire::Agents::SWAIG::FunctionResult->new(
                        response => "The result of $args->{expression} is $result"
                    );
                }
            }
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Could not evaluate expression: $args->{expression}"
            );
        },
    );
}

sub _get_prompt_sections {
    return [{
        title   => 'Mathematical Calculations',
        body    => '',
        bullets => [
            'Use the calculate tool for math operations',
            'Supports +, -, *, /, %, and ** (exponentiation)',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
    };
}

1;
