package Praxo::Models;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    SYSTEM USER ASSISTANT TOOL stream_kinds
    content_block tool_call message message_wire message_text message_assistant
    message_tool tool_spec usage usage_plus request response session run_result
    memory_record event action decision
);

use constant {
    SYSTEM => 'system',
    USER => 'user',
    ASSISTANT => 'assistant',
    TOOL => 'tool',
};

my @STREAM_KINDS = qw(values updates messages tasks debug checkpoint);

sub stream_kinds { return @STREAM_KINDS }

sub content_block {
    my (%args) = @_;
    my %block = (type => $args{type} // 'text');
    $block{text} = $args{text} if defined $args{text};
    $block{image_url} = $args{image_url} if defined $args{image_url};
    $block{data} = $args{data} if defined $args{data};
    return \%block;
}

sub tool_call {
    my (%args) = @_;
    return {
        id => $args{id} // '',
        name => $args{name} // '',
        arguments => $args{arguments} // {},
    };
}

sub message {
    my (%args) = @_;
    return {
        role => $args{role} // USER,
        content => $args{content},
        contentBlocks => $args{content_blocks} // [],
        toolCalls => $args{tool_calls} // [],
        toolId => $args{tool_id},
    };
}

sub message_text {
    my ($role, $content) = @_;
    return message(role => $role, content => $content);
}

sub message_assistant {
    my ($content, $tool_calls) = @_;
    return message(role => ASSISTANT, content => $content, tool_calls => $tool_calls // []);
}

sub message_tool {
    my ($content, $tool_id) = @_;
    return message(role => TOOL, content => $content, tool_id => $tool_id);
}

sub message_wire {
    my ($message) = @_;
    my %out = (role => $message->{role});
    $out{content} = $message->{content} if defined $message->{content};
    $out{contentBlocks} = $message->{contentBlocks}
        if ref($message->{contentBlocks}) eq 'ARRAY' && @{ $message->{contentBlocks} };
    $out{toolCalls} = $message->{toolCalls}
        if ref($message->{toolCalls}) eq 'ARRAY' && @{ $message->{toolCalls} };
    $out{toolId} = $message->{toolId} if defined $message->{toolId};
    return \%out;
}

sub tool_spec {
    my (%args) = @_;
    return {
        name => $args{name} // '',
        description => $args{description} // '',
        parameters => $args{parameters},
        risk => $args{risk},
    };
}

sub usage {
    my (%args) = @_;
    return {
        inputTokens => $args{input_tokens} // 0,
        outputTokens => $args{output_tokens} // 0,
        cachedTokens => $args{cached_tokens} // 0,
    };
}

sub usage_plus {
    my ($left, $right) = @_;
    return usage(
        input_tokens => ($left->{inputTokens} // 0) + ($right->{inputTokens} // 0),
        output_tokens => ($left->{outputTokens} // 0) + ($right->{outputTokens} // 0),
        cached_tokens => ($left->{cachedTokens} // 0) + ($right->{cachedTokens} // 0),
    );
}

sub request {
    my (%args) = @_;
    return {
        messages => $args{messages} // [],
        tools => $args{tools} // [],
        toolChoice => $args{tool_choice},
        responseFormat => $args{response_format},
        temperature => $args{temperature} // 0,
    };
}

sub response {
    my (%args) = @_;
    return {
        message => $args{message},
        usage => $args{usage} // usage(),
        finishReason => $args{finish_reason},
    };
}

sub session {
    my (%args) = @_;
    return {
        id => $args{id} // '',
        messages => $args{messages} // [],
    };
}

sub run_result {
    my (%args) = @_;
    return {
        runId => $args{run_id} // '',
        output => $args{output} // '',
        steps => $args{steps} // 0,
        usage => $args{usage} // usage(),
    };
}

sub memory_record {
    my (%args) = @_;
    return {
        id => $args{id} // '',
        frame => $args{frame} // '',
        content => $args{content} // '',
        createdAt => $args{created_at},
    };
}

sub event {
    my (%args) = @_;
    return {
        type => $args{type} // '',
        sessionId => $args{session_id} // '',
        runId => $args{run_id},
        data => $args{data},
    };
}

sub action {
    my (%args) = @_;
    return {
        kind => $args{kind} // '',
        sessionId => $args{session_id} // '',
        toolName => $args{tool_name},
        arguments => $args{arguments},
    };
}

sub decision {
    my (%args) = @_;
    return {
        allowed => $args{allowed} ? 1 : 0,
        reason => $args{reason} // '',
    };
}

1;
