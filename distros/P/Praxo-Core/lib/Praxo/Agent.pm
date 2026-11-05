package Praxo::Agent;

use strict;
use warnings;
use Exporter 'import';
use Praxo::Json ();
use Praxo::Models ();
use Praxo::Errors qw(praxo_error error_code);

our @EXPORT_OK = qw(run_agent);

package Praxo::Agent::FuncTool;

sub new {
    my ($class, $name, $description, $function) = @_;
    return bless {
        name => $name // '',
        description => $description // '',
        function => $function,
    }, $class;
}

sub name { $_[0]->{name} }
sub description { $_[0]->{description} }
sub invoke { $_[0]->{function}->($_[1]) }

package Praxo::Agent::ToolRegistry;

sub new {
    my ($class) = @_;
    return bless { tools => {} }, $class;
}

sub register {
    my ($self, $tool) = @_;
    my $name = ref($tool) ? $tool->name : $tool->{name};
    $self->{tools}{$name} = $tool;
    return $tool;
}

sub get {
    my ($self, $name) = @_;
    Praxo::Errors::praxo_error('TOOL_NOT_FOUND', "tool not found: $name")
        unless exists $self->{tools}{$name};
    return $self->{tools}{$name};
}

sub specs {
    my ($self) = @_;
    my @specs = map {
        Praxo::Models::tool_spec(
            name => (ref($_) ? $_->name : $_->{name}),
            description => (ref($_) ? $_->description : $_->{description}),
        )
    } values %{ $self->{tools} };
    return [ sort { $a->{name} cmp $b->{name} } @specs ];
}

package Praxo::Agent::AgentOptions;

sub new {
    my ($class, $model) = @_;
    return bless {
        model => $model,
        tools => undef,
        events => undef,
        policy => undef,
        system_prompt => '',
        context => undef,
        max_steps => 8,
        max_tokens => 0,
        tool_choice => undef,
    }, $class;
}

package Praxo::Agent::StaticModel;

sub new {
    my ($class, $content) = @_;
    return bless { content => $content // '' }, $class;
}

sub generate {
    my ($self, $request) = @_;
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($self->{content}),
    );
}

package Praxo::Agent::Agent;

sub new {
    my ($class, $options) = @_;
    return bless { options => $options }, $class;
}

sub run {
    my ($self, $session, $prompt) = @_;
    my $options = $self->{options};
    my $max_steps = ($options->{max_steps} // 0) > 0 ? $options->{max_steps} : 8;
    my $run_id = 'run-' . int(time() * 1000);
    my @messages = @{ $session->{messages} // [] };
    if (length($options->{system_prompt} // '')) {
        unshift @messages, Praxo::Models::message_text(
            Praxo::Models::SYSTEM, $options->{system_prompt},
        );
    }
    push @messages, Praxo::Models::message_text(Praxo::Models::USER, $prompt // '');
    my $usage = Praxo::Models::usage();
    _emit($options, 'run.started', $session->{id}, $run_id);
    my $step = 0;
    my $result;
    my $ok = eval {
        for $step (1 .. $max_steps) {
            _authorize($options, Praxo::Models::action(
                kind => 'model.generate', session_id => $session->{id},
            ));
            if ($options->{context}) {
                my ($compacted, $context_ok) = $options->{context}->compact(\@messages);
                Praxo::Errors::praxo_error('AGENT_CONTEXT_BUDGET', 'context budget') unless $context_ok;
                @messages = @$compacted;
            }
            my $request = Praxo::Models::request(
                messages => \@messages,
                tools => $options->{tools} ? $options->{tools}->specs() : [],
                tool_choice => $options->{tool_choice},
            );
            my $response = $options->{model}->generate($request);
            $usage = Praxo::Models::usage_plus($usage, $response->{usage} // {});
            my $total = ($usage->{inputTokens} // 0) + ($usage->{outputTokens} // 0);
            Praxo::Errors::praxo_error('AGENT_MAX_TOKENS', 'token budget')
                if ($options->{max_tokens} // 0) > 0 && $total > $options->{max_tokens};
            my $message = $response->{message};
            push @messages, $message;
            my $calls = $message->{toolCalls} // [];
            if (!@$calls) {
                _emit($options, 'run.completed', $session->{id}, $run_id);
                $result = Praxo::Models::run_result(
                    run_id => $run_id,
                    output => $message->{content} // '',
                    steps => $step,
                    usage => $usage,
                );
                last;
            }
            for my $call (@$calls) {
                push @messages, _invoke_tool($options, $call, $run_id, $session->{id});
            }
        }
        if (!$result) {
            Praxo::Errors::praxo_error('AGENT_MAX_STEPS', 'maximum steps');
        }
        1;
    };
    if (!$ok) {
        my $error = $@;
        _emit($options, 'run.failed', $session->{id}, $run_id, {
            error => "$error",
        });
        die $error;
    }
    return $result;
}

sub _invoke_tool {
    my ($options, $call, $run_id, $session_id) = @_;
    _authorize($options, Praxo::Models::action(
        kind => 'tool.invoke', session_id => $session_id,
        tool_name => $call->{name}, arguments => $call->{arguments},
    ));
    Praxo::Errors::praxo_error('TOOL_NOT_FOUND', 'tool is not registered')
        unless $options->{tools};
    my $tool = $options->{tools}->get($call->{name});
    _emit($options, 'tool.call', $session_id, $run_id, {
        name => $call->{name}, arguments => $call->{arguments} // {},
    });
    my $value = $tool->invoke($call->{arguments} // {});
    return Praxo::Models::message_tool(
        Praxo::Json::stringify($value),
        $call->{id} // '',
    );
}

sub _authorize {
    my ($options, $action) = @_;
    return unless $options->{policy};
    my $decision = $options->{policy}->($action);
    Praxo::Errors::praxo_error('POLICY_ERROR', 'policy denied the action')
        unless ref($decision) eq 'HASH' && $decision->{allowed};
}

sub _emit {
    my ($options, $type, $session_id, $run_id, $data) = @_;
    return unless $options->{events};
    $options->{events}->emit(Praxo::Models::event(
        type => $type, session_id => $session_id, run_id => $run_id, data => $data,
    ));
}

package Praxo::Agent;

sub run_agent {
    my ($options, $session, $prompt) = @_;
    return Praxo::Agent::Agent->new($options)->run($session, $prompt);
}

1;
