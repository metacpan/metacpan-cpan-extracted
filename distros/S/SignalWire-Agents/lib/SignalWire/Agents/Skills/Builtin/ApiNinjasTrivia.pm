package SignalWire::Agents::Skills::Builtin::ApiNinjasTrivia;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('api_ninjas_trivia', __PACKAGE__);

has '+skill_name'        => (default => sub { 'api_ninjas_trivia' });
has '+skill_description' => (default => sub { 'Get trivia questions from API Ninjas' });
has '+supports_multiple_instances' => (default => sub { 1 });

my @ALL_CATEGORIES = qw(
    artliterature language sciencenature general fooddrink
    peopleplaces geography historyholidays entertainment
    toysgames music mathematics religionmythology
    sportsleisure
);

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name  = $self->params->{tool_name} // 'get_trivia';
    my $api_key    = $self->params->{api_key} // '';
    my $categories = $self->params->{categories} // [@ALL_CATEGORIES];

    $self->define_tool(
        name        => $tool_name,
        description => "Get trivia questions for $tool_name",
        parameters  => {
            type       => 'object',
            properties => {
                category => {
                    type => 'string',
                    description => 'The trivia category',
                    enum => $categories,
                },
            },
            required => ['category'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Trivia category: $args->{category} (API call would be made with key)"
            );
        },
    );
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        api_key    => { type => 'string', required => 1, hidden => 1 },
        categories => { type => 'array',  default => [@ALL_CATEGORIES] },
        tool_name  => { type => 'string', default => 'get_trivia' },
    };
}

1;
