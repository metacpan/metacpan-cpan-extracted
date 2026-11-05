package Praxo::Toolcall;

use strict;
use warnings;
use Exporter 'import';
use Praxo::Json ();

our @EXPORT_OK = qw(parse_toolcall strip_markup parse_input_json);

sub parse_toolcall {
    my ($content) = @_;
    my $call = _parse_json_call($content)
        // _parse_xml($content)
        // _parse_tag($content)
        // _parse_plain($content);
    return undef unless $call;
    $call->{callId} = 'tc-' . int(time() * 1000);
    return $call;
}

sub strip_markup {
    my ($content) = @_;
    my $output = $content;
    $output =~ s/<tool_call\s+name="[^"]+"\s*>.*?(?:<\/tool_call>|$)//sg;
    $output =~ s/<tool_call_invoke>.*?(?:<\/tool_call_invoke>|$)//sg;
    $output =~ s/<[a-zA-Z][\w-]*(?:\.[\w-]+)+>\s*\{.*?(?:<\/[a-zA-Z][\w.-]*>|$)//sg;
    $output =~ s/\n{3,}/\n\n/g;
    $output =~ s/^\s+|\s+$//g;
    return $output;
}

sub parse_input_json {
    my ($raw) = @_;
    my $trimmed = $raw;
    $trimmed =~ s/^\s+|\s+$//g;
    my $value = eval { Praxo::Json::parse($trimmed) };
    return $value if ref($value) eq 'HASH';
    (my $escaped = $raw) =~ s/\\/\\\\/g;
    $escaped =~ s/^\s+|\s+$//g;
    $value = eval { Praxo::Json::parse($escaped) };
    return ref($value) eq 'HASH' ? $value : undef;
}

sub _parse_json_call {
    my ($content) = @_;
    my $value = eval { Praxo::Json::parse($content) };
    return undef unless ref($value) eq 'HASH';
    my $name = $value->{name};
    return undef unless defined($name) && !ref($name) && length($name);
    return {
        name => $name,
        input => ref($value->{input}) eq 'HASH' ? $value->{input} : {},
        operation => $value->{operation} // '',
        resource => $value->{resource} // '',
        risk => $value->{risk} // '',
        reason => $value->{reason} // '',
        idempotency_key => $value->{idempotency_key} // '',
    };
}

sub _parse_xml {
    my ($content) = @_;
    return undef unless $content =~ /<tool_call\s+name="([^"]+)"\s*>\s*(.*?)\s*<\/tool_call>/s;
    my ($name, $raw) = ($1, $2);
    my $input = parse_input_json($raw);
    return undef unless $input;
    return { name => $name, input => $input, operation => '', resource => '',
             risk => '', reason => '', idempotency_key => '' };
}

sub _parse_tag {
    my ($content) = @_;
    return undef unless $content =~ /<([a-zA-Z][\w-]*(?:\.[\w-]+)+)>\s*(\{.*?)\s*(?:<\/[a-zA-Z][\w.-]*>|$)/s;
    my ($name, $raw) = ($1, $2);
    my $input = parse_input_json($raw);
    return undef unless $input;
    return { name => $name, input => $input, operation => '', resource => '',
             risk => '', reason => '', idempotency_key => '' };
}

sub _parse_plain {
    my ($content) = @_;
    return undef unless $content =~ /^\s*([a-zA-Z][\w.-]*)\s+(\{.*\})\s*$/m;
    my ($name, $raw) = ($1, $2);
    return undef unless index($name, '.') >= 0;
    my $input = parse_input_json($raw);
    return undef unless $input;
    return { name => $name, input => $input, operation => '', resource => '',
             risk => '', reason => '', idempotency_key => '' };
}

1;
