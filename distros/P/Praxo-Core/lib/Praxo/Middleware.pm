package Praxo::Middleware;

use strict;
use warnings;
use Exporter 'import';
use Praxo::Json ();
use Praxo::JsonSchema ();
use Praxo::Errors qw(praxo_error);

our @EXPORT_OK = qw(
    PiiRedactor StructuredOutput CallLimit ToolSelection fallback_model
    redact redact_value structured_apply
);

package Praxo::Middleware::PiiRedactor;

sub new {
    my ($class) = @_;
    return bless {
        rules => [
            [qr/[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/, '[REDACTED:email]'],
            [qr/\b\d{3}-\d{2}-\d{4}\b/, '[REDACTED:ssn]'],
            [qr/\b(?:\d{4}[ -]?){3}\d{4}\b/, '[REDACTED:credit_card]'],
        ],
    }, $class;
}

sub redact {
    my ($self, $text) = @_;
    my $output = $text // '';
    for my $rule (@{ $self->{rules} }) {
        my ($pattern, $replacement) = @$rule;
        $output =~ s/$pattern/$replacement/g;
    }
    return $output;
}

sub redact_value {
    my ($self, $value) = @_;
    return $self->redact($value) if defined($value) && !ref($value);
    if (ref($value) eq 'HASH') {
        return { map { $_ => $self->redact_value($value->{$_}) } keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { $self->redact_value($_) } @$value ];
    }
    return $value;
}

package Praxo::Middleware::StructuredOutput;

sub new {
    my ($class, %args) = @_;
    return bless {
        schema => $args{schema} // {},
        maxRepairs => $args{max_repairs} // 0,
        repairer => $args{repairer},
    }, $class;
}

sub apply {
    my ($self, $text) = @_;
    my $output = $text // '';
    for my $attempt (0 .. $self->{maxRepairs}) {
        my $data = eval { _extract_json($output) };
        if (!$@ && !@{ Praxo::JsonSchema::validate($self->{schema}, $data) }) {
            return ($output, undef);
        }
        last if $attempt == $self->{maxRepairs} && !$self->{repairer};
        last unless $self->{repairer};
        my $repaired = $self->{repairer}->($output);
        last unless defined($repaired) && $repaired =~ /\S/;
        $output = $repaired;
    }
    return (undef, 'AGENT_STRUCTURED_OUTPUT');
}

sub _extract_json {
    my ($text) = @_;
    my $value = $text // '';
    $value =~ s/^\s+|\s+$//g;
    if ($value =~ /^```/) {
        $value =~ s/^```[^\n]*\n//;
        $value =~ s/^`+//;
        $value =~ s/`+\s*$//;
        $value =~ s/^\s+|\s+$//g;
    }
    my $start = index($value, '{');
    my $array = index($value, '[');
    $start = $array if $array >= 0 && ($start < 0 || $array < $start);
    Praxo::Errors::praxo_error('AGENT_STRUCTURED_OUTPUT', 'output does not contain JSON') if $start < 0;
    return Praxo::Json::parse(substr($value, $start));
}

package Praxo::Middleware::CallLimit;

sub new {
    my ($class, %args) = @_;
    return bless {
        modelLimit => $args{model_limit} // 0,
        toolLimit => $args{tool_limit} // 0,
        models => 0,
        tools => 0,
    }, $class;
}

sub before_model {
    my ($self) = @_;
    $self->{models}++;
    Praxo::Errors::praxo_error('AGENT_MODEL_CALL_LIMIT', 'model call limit')
        if $self->{modelLimit} > 0 && $self->{models} > $self->{modelLimit};
}

sub before_tool {
    my ($self) = @_;
    $self->{tools}++;
    Praxo::Errors::praxo_error('AGENT_TOOL_CALL_LIMIT', 'tool call limit')
        if $self->{toolLimit} > 0 && $self->{tools} > $self->{toolLimit};
}

package Praxo::Middleware::ToolSelection;

sub new {
    my ($class, $selected) = @_;
    return bless { selected => { map { $_ => 1 } @{ $selected // [] } } }, $class;
}

sub filter {
    my ($self, $tools) = @_;
    return [ grep { $self->{selected}{ $_->{name} } } @$tools ];
}

sub reject {
    my ($self, $name) = @_;
    Praxo::Errors::praxo_error('AGENT_TOOL_NOT_SELECTED', 'tool not selected')
        unless $self->{selected}{$name};
}

package Praxo::Middleware;

sub redact {
    my ($text) = @_;
    return Praxo::Middleware::PiiRedactor->new->redact($text);
}

sub redact_value {
    my ($value) = @_;
    return Praxo::Middleware::PiiRedactor->new->redact_value($value);
}

sub structured_apply {
    my ($schema, $text, $max_repairs, $repairer) = @_;
    my $output = Praxo::Middleware::StructuredOutput->new(
        schema => $schema,
        max_repairs => $max_repairs // 0,
        repairer => $repairer,
    );
    return $output->apply($text);
}

sub fallback_model {
    my ($fallback) = @_;
    return sub {
        my ($next) = @_;
        return sub {
            my ($request) = @_;
            my $response = eval { $next->($request) };
            return $response unless $@;
            my $error = $@;
            die $error unless $fallback;
            return $fallback->($request);
        };
    };
}

1;
