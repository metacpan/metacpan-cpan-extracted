#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Praxo::Json ();
use Praxo::Models ();
use Praxo::Toolcall ();
use Praxo::JsonSchema ();
use Praxo::Plugin ();
use Praxo::Runtime ();
use Praxo::Middleware ();
use Praxo::Agent ();

my $ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..', '..', '..'));

sub check {
    my ($condition, $message) = @_;
    die "$message\n" unless $condition;
}

package RecordingSink;

sub new { bless { types => [] }, shift }
sub emit { my ($self, $event) = @_; push @{ $self->{types} }, $event->{type} }
sub types { $_[0]->{types} }

package ScriptedModel;

sub new { bless { steps => $_[1], next => 0 }, shift }

sub generate {
    my ($self, $request) = @_;
    die "script exhausted\n" if $self->{next} >= @{ $self->{steps} };
    my $step = $self->{steps}[ $self->{next}++ ];
    my @calls = map {
        Praxo::Models::tool_call(
            id => $_->{id} // '',
            name => $_->{name} // '',
            arguments => $_->{arguments} // {},
        )
    } @{ $step->{toolCalls} // [] };
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($step->{content} // '', \@calls),
        usage => Praxo::Models::usage(
            input_tokens => $step->{inputTokens} // 0,
            output_tokens => $step->{outputTokens} // 0,
        ),
    );
}

package main;

sub run_toolcall {
    my ($input, $expect) = @_;
    my $operation = Praxo::Json::string($input, 'operation') // '';
    my $content = Praxo::Json::string($input, 'content') // '';
    if ($operation eq 'strip') {
        my $got = Praxo::Toolcall::strip_markup($content);
        check($got eq (Praxo::Json::string($expect, 'text') // ''), "strip: got $got");
        return;
    }
    my $call = Praxo::Toolcall::parse_toolcall($content);
    if (Praxo::Json::bool($expect, 'nil')) {
        check(!defined $call, 'expected nil');
        return;
    }
    check(defined $call, 'expected a tool call');
    check($call->{name} eq (Praxo::Json::string($expect, 'name') // ''),
        "name: got $call->{name}");
    my $expected = Praxo::Json::get($expect, 'input');
    $expected = {} unless defined $expected;
    check(Praxo::Json::equals($call->{input}, $expected), 'input mismatch');
}

sub run_jsonschema {
    my ($input, $expect) = @_;
    my $errors = Praxo::JsonSchema::validate(
        Praxo::Json::get($input, 'schema'),
        Praxo::Json::get($input, 'data'),
    );
    my @paths = sort map { $_->{path} } @$errors;
    my @expected = sort map { "$_" } @{ Praxo::Json::array($expect, 'errorPaths') };
    check((@$errors ? 0 : 1) == Praxo::Json::bool($expect, 'valid'), 'valid mismatch');
    check(join("\0", @paths) eq join("\0", @expected), 'errorPaths: got ' . join(', ', @paths));
}

sub run_plugin {
    my ($input, $expect) = @_;
    my $raw = Praxo::Json::string($input, 'raw');
    $raw //= Praxo::Json::stringify(Praxo::Json::get($input, 'manifest') // {});
    my $manifest;
    eval { $manifest = Praxo::Plugin::parse_manifest($raw) };
    check((defined($manifest) ? 1 : 0) == Praxo::Json::bool($expect, 'valid'), 'valid mismatch');
    return unless $manifest;
    my $id = Praxo::Json::string($expect, 'id');
    check($manifest->{id} eq $id, "id: got $manifest->{id}") if defined $id;
    my $kind = Praxo::Json::string($expect, 'kind');
    check($manifest->{kind} eq $kind, "kind: got $manifest->{kind}") if defined $kind;
}

sub run_memory {
    my ($input, $expect) = @_;
    my $store = Praxo::Runtime::MemoryStore->new;
    for my $put (@{ Praxo::Json::array($input, 'puts') }) {
        my $record = Praxo::Json::get($put, 'record') // {};
        $store->put(Praxo::Json::string($put, 'session') // '', {
            id => Praxo::Json::string($record, 'id') // '',
            frame => Praxo::Json::string($record, 'frame') // '',
            content => Praxo::Json::string($record, 'content') // '',
            createdAt => Praxo::Json::string($record, 'createdAt'),
        });
    }
    my @records = $store->search(
        Praxo::Json::string($input, 'session') // '',
        Praxo::Json::string($input, 'query') // '',
        Praxo::Json::int($input, 'limit'),
    );
    my $ids = @records ? [ map { $_->{id} } @records ] : undef;
    my $contents = @records ? [ map { $_->{content} } @records ] : undef;
    check(Praxo::Json::equals($ids, Praxo::Json::get($expect, 'ids')), 'ids mismatch');
    check(Praxo::Json::equals($contents, Praxo::Json::get($expect, 'contents')), 'contents mismatch');
}

sub run_event {
    my ($input, $expect) = @_;
    my @events = map {
        Praxo::Models::event(type => $_, session_id => 's1')
    } @{ Praxo::Json::array($input, 'events') };
    if ((Praxo::Json::string($input, 'sink') // 'filter') eq 'multi') {
        my $count = Praxo::Json::int($input, 'sinkCount', 1);
        $count = 1 if $count < 1;
        my @sinks = map { RecordingSink->new } 1 .. $count;
        my $multi = Praxo::Runtime::MultiSink->new(\@sinks);
        $multi->emit($_) for @events;
        my $per_sink = [ map { $_->types } @sinks ];
        check(Praxo::Json::equals($per_sink, Praxo::Json::get($expect, 'perSink')),
            'perSink mismatch');
        return;
    }
    my $sink = RecordingSink->new;
    my $predicate = Praxo::Json::get($input, 'predicateTypes');
    my %allowed = map { $_ => 1 } @{ $predicate // [] };
    my $filter = Praxo::Runtime::FilterSink->new($sink, sub {
        return defined($predicate) ? $allowed{ $_[0]{type} } : 1;
    });
    $filter->emit($_) for @events;
    my $delivered = @{ $sink->types } ? $sink->types : undef;
    check(Praxo::Json::equals($delivered, Praxo::Json::get($expect, 'delivered')),
        'delivered mismatch');
}

sub run_stream {
    my ($expect) = @_;
    my @kinds = Praxo::Models::stream_kinds();
    check(Praxo::Json::equals(\@kinds, Praxo::Json::get($expect, 'kinds')), 'kinds mismatch');
}

sub run_checkpoint {
    my ($input, $expect) = @_;
    my $allow = Praxo::Runtime::CheckpointAllowlist->new;
    $allow->register($_) for @{ Praxo::Json::array($input, 'registered') };
    my $operation = Praxo::Json::string($input, 'operation') // 'roundtrip';
    my $type = Praxo::Json::string($input, 'type') // '';
    my $value = Praxo::Json::get($input, 'value');
    if ($operation eq 'roundtrip') {
        my $data = $allow->marshal($type, $value);
        check(Praxo::Json::equals($allow->unmarshal($data), Praxo::Json::get($expect, 'value')),
            'value mismatch');
        return;
    }
    my $code = '';
    eval {
        if ($operation eq 'marshal') {
            $allow->marshal($type, $value);
        } elsif ($operation eq 'unmarshal') {
            $allow->unmarshal(Praxo::Json::stringify({ type => $type, data => $value }));
        } else {
            Praxo::Errors::praxo_error('CHECKPOINT_ERROR', 'unknown operation');
        }
    };
    $code = Praxo::Errors::error_code($@) if $@;
    check($code eq (Praxo::Json::string($expect, 'errorCode') // ''),
        "errorCode: got $code");
}

sub run_policy {
    my ($input, $expect) = @_;
    my $root = tempdir(CLEANUP => 1);
    for my $dir (@{ Praxo::Json::array($input, 'makeDirs') }) {
        make_path(File::Spec->catdir($root, $dir));
    }
    my @grants;
    for my $item (@{ Praxo::Json::array($input, 'grants') }) {
        my $grant_root = File::Spec->catdir($root, Praxo::Json::string($item, 'root') // '');
        make_path($grant_root);
        push @grants, {
            root => $grant_root,
            access => Praxo::Json::string($item, 'access') // 'read',
        };
    }
    my $checker = Praxo::Runtime::PathChecker->new(\@grants);
    my $target = File::Spec->catfile($root, Praxo::Json::string($input, 'target') // '');
    my $need = Praxo::Json::string($input, 'need') // 'read';
    if (Praxo::Json::bool($expect, 'error')) {
        my $caught = 0;
        eval { $checker->check($target, $need) };
        $caught = 1 if $@;
        check($caught, 'expected a policy error');
        return;
    }
    my $allowed = $checker->check($target, $need)->{allowed};
    check($allowed == Praxo::Json::bool($expect, 'allowed'), 'allowed mismatch');
}

sub run_context {
    my ($input, $expect) = @_;
    my @messages = map {
        Praxo::Models::message_text(
            Praxo::Json::string($_, 'role') // '',
            Praxo::Json::string($_, 'content'),
        )
    } @{ Praxo::Json::array($input, 'messages') };
    if ((Praxo::Json::string($input, 'operation') // '') eq 'estimate') {
        my $tokens = Praxo::Runtime::estimate_tokens(\@messages);
        check($tokens == Praxo::Json::int($expect, 'tokens'), "tokens: got $tokens");
        return;
    }
    my $budget = Praxo::Runtime::ContextBudget->new(
        max_tokens => Praxo::Json::int(Praxo::Json::get($input, 'budget'), 'maxTokens'),
        keep_recent => Praxo::Json::int(Praxo::Json::get($input, 'budget'), 'keepRecent'),
    );
    my ($output, $ok) = $budget->compact(\@messages);
    check($ok == Praxo::Json::bool($expect, 'ok'), 'ok mismatch');
    return unless $ok;
    my $tokens = Praxo::Runtime::estimate_tokens($output);
    check($tokens == Praxo::Json::int($expect, 'tokens'), "tokens: got $tokens");
    my $wire = [ map { Praxo::Models::message_wire($_) } @$output ];
    check(Praxo::Json::equals($wire, Praxo::Json::get($expect, 'messages')), 'messages mismatch');
}

sub run_middleware {
    my ($input, $expect) = @_;
    my $operation = Praxo::Json::string($input, 'operation') // '';
    if ($operation eq 'pii') {
        my $got = Praxo::Middleware::redact(Praxo::Json::string($input, 'text') // '');
        check($got eq (Praxo::Json::string($expect, 'text') // ''), 'text mismatch');
    } elsif ($operation eq 'pii-value') {
        my $got = Praxo::Middleware::redact_value(Praxo::Json::get($input, 'value'));
        check(Praxo::Json::equals($got, Praxo::Json::get($expect, 'value')), 'value mismatch');
    } elsif ($operation eq 'structured') {
        my $repair = Praxo::Json::string($input, 'repairOutput');
        my ($output, $code) = Praxo::Middleware::structured_apply(
            Praxo::Json::get($input, 'schema') // {},
            Praxo::Json::string($input, 'output') // '',
            Praxo::Json::int($input, 'maxRepairs'),
            defined($repair) ? sub { $repair } : undef,
        );
        if (Praxo::Json::bool($expect, 'ok')) {
            check(defined($output) && $output eq (Praxo::Json::string($expect, 'output') // ''),
                'output mismatch');
        } else {
            check($code eq (Praxo::Json::string($expect, 'errorCode') // ''), 'errorCode mismatch');
        }
    } elsif ($operation eq 'call-limit') {
        my $limit = Praxo::Middleware::CallLimit->new(
            model_limit => Praxo::Json::int($input, 'modelLimit'),
            tool_limit => Praxo::Json::int($input, 'toolLimit'),
        );
        my @outcomes;
        for my $call (@{ Praxo::Json::array($input, 'calls') }) {
            my $code = 'ok';
            eval {
                if ($call eq 'model') { $limit->before_model }
                else { $limit->before_tool }
            };
            $code = Praxo::Errors::error_code($@) if $@;
            push @outcomes, $code;
        }
        check(Praxo::Json::equals(\@outcomes, Praxo::Json::get($expect, 'outcomes')),
            'outcomes mismatch');
    } elsif ($operation eq 'tool-selection') {
        my $selection = Praxo::Middleware::ToolSelection->new(
            [ @{ Praxo::Json::get($input, 'selected') // [] } ],
        );
        my @tools = map { Praxo::Models::tool_spec(name => $_) }
            @{ Praxo::Json::array($input, 'tools') };
        my $advertised = [ map { $_->{name} } @{ $selection->filter(\@tools) } ];
        check(Praxo::Json::equals($advertised, Praxo::Json::get($expect, 'advertised')),
            'advertised mismatch');
        my $reject = 'ok';
        eval { $selection->reject(Praxo::Json::string($input, 'requested') // '') };
        $reject = Praxo::Errors::error_code($@) if $@;
        check($reject eq (Praxo::Json::string($expect, 'reject') // ''), 'reject mismatch');
    } elsif ($operation eq 'fallback') {
        my $content = Praxo::Json::string($input, 'fallbackContent') // '';
        my $middleware = Praxo::Middleware::fallback_model(sub {
            Praxo::Models::response(
                message => Praxo::Models::message_assistant($content),
            )
        });
        my $handler = $middleware->(sub {
            Praxo::Errors::praxo_error('PRIMARY_FAILED', 'primary');
        });
        my $response = $handler->(Praxo::Models::request());
        check(($response->{message}{content} // '') eq $content, 'output mismatch');
    } else {
        die "unknown middleware operation $operation\n";
    }
}

sub run_agent_loop {
    my ($input, $expect) = @_;
    my $invocations = 0;
    my $registry = Praxo::Agent::ToolRegistry->new;
    for my $tool (@{ Praxo::Json::array($input, 'tools') }) {
        my $name = Praxo::Json::string($tool, 'name') // '';
        $registry->register(Praxo::Agent::FuncTool->new(
            $name,
            Praxo::Json::string($tool, 'description') // '',
            sub { $invocations++; return $_[0] },
        ));
    }
    my $sink = RecordingSink->new;
    my $options = Praxo::Agent::AgentOptions->new(
        ScriptedModel->new([ @{ Praxo::Json::get($input, 'script') // [] } ]),
    );
    $options->{tools} = $registry;
    $options->{events} = $sink;
    $options->{max_steps} = Praxo::Json::int($input, 'maxSteps');
    $options->{max_tokens} = Praxo::Json::int($input, 'maxTokens');
    my $result;
    my $failure;
    eval {
        $result = Praxo::Agent::run_agent(
            $options,
            Praxo::Models::session(id => 's1'),
            Praxo::Json::string($input, 'prompt') // '',
        );
    };
    $failure = $@ if $@;
    if (Praxo::Json::bool($expect, 'error')) {
        check(defined $failure, 'unexpected success');
        my $expected = Praxo::Json::string($expect, 'errorCode');
        check(Praxo::Errors::error_code($failure) eq $expected, 'errorCode mismatch')
            if defined $expected;
    } else {
        check(!defined $failure,
            defined($failure) ? "unexpected failure: $failure" : 'unexpected failure');
        check(($result->{output} // '') eq (Praxo::Json::string($expect, 'output') // ''),
            'output mismatch');
        check(($result->{steps} // 0) == Praxo::Json::int($expect, 'steps'), 'steps mismatch');
    }
    check($invocations == Praxo::Json::int($expect, 'toolInvocations'), 'tool invocations mismatch');
    my $events = @{ $sink->types } ? $sink->types : undef;
    check(Praxo::Json::equals($events, Praxo::Json::get($expect, 'events')), 'events mismatch');
}

sub run_vector {
    my ($group, $vector) = @_;
    my $input = Praxo::Json::get($vector, 'input');
    my $expect = Praxo::Json::get($vector, 'expect');
    return run_toolcall($input, $expect) if $group eq 'toolcall';
    return run_jsonschema($input, $expect) if $group eq 'jsonschema';
    return run_plugin($input, $expect) if $group eq 'plugin';
    return run_memory($input, $expect) if $group eq 'memory';
    return run_event($input, $expect) if $group eq 'event';
    return run_stream($expect) if $group eq 'stream';
    return run_checkpoint($input, $expect) if $group eq 'checkpoint';
    return run_policy($input, $expect) if $group eq 'policy';
    return run_context($input, $expect) if $group eq 'context';
    return run_middleware($input, $expect) if $group eq 'middleware';
    return run_agent_loop($input, $expect) if $group eq 'agent-loop';
    die "no runner for group $group\n";
}

sub read_text {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

sub run_all {
    my $version = read_text(File::Spec->catfile($ROOT, 'spec', 'SPEC_VERSION'));
    $version =~ s/^\s+|\s+$//g;
    my @files = sort glob(File::Spec->catfile($ROOT, 'spec', 'vectors', '*.json'));
    my @required = qw(
        agent-loop checkpoint context event jsonschema memory middleware plugin
        policy stream toolcall
    );
    my @failures;
    my %groups;
    my %seen;
    for my $path (@files) {
        my ($name) = $path =~ m{([^/\\]+)\.json$};
        my $file = eval { Praxo::Json::parse(read_text($path)) };
        if (!$file) {
            push @failures, "$name: invalid vector file";
            next;
        }
        my $group = Praxo::Json::string($file, 'group') // '';
        $groups{$group} = 1;
        push @failures, "$name: specVersion mismatch"
            unless (Praxo::Json::string($file, 'specVersion') // '') eq $version;
        push @failures, "$name: group mismatch" unless $name eq $group;
        my $vectors = Praxo::Json::array($file, 'vectors');
        push @failures, "$group: empty vector group" unless @$vectors;
        for my $vector (@$vectors) {
            my $id = Praxo::Json::string($vector, 'id') // '';
            push @failures, "$group/$id: duplicate id with $seen{$id}"
                if exists $seen{$id};
            $seen{$id} = $group;
            my $ok = eval { run_vector($group, $vector); 1 };
            push @failures, "$group/$id: $@" unless $ok;
        }
    }
    for my $group (@required) {
        push @failures, "missing required vector group: $group"
            unless $groups{$group};
    }
    return @failures;
}

my @failures = run_all();
if (!@failures) {
    print "all spec vectors passed\n";
    exit 0;
}
print STDERR $_ for @failures;
exit 1;
