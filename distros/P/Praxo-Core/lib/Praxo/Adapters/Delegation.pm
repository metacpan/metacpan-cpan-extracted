package Praxo::Adapters::Delegation;

use strict;
use warnings;
use Time::HiRes ();
use Praxo::Errors qw(praxo_error error_code);

sub subagent_run {
    my ($runner, $request) = @_;
    my $parent = $request->{parentSessionId} // '';
    my $agent = $request->{agentId} // '';
    praxo_error(
        'SUBAGENT_INVALID',
        'agent: subagent parent session and agent id are required',
    ) if $parent eq '' || $agent eq '';
    my $timestamp = sprintf('%.6f', Time::HiRes::time());
    my $base = {
        id => 'subagent',
        parentSessionId => $parent,
        agentId => $agent,
        mode => ($request->{mode} // '') eq 'fork' ? 'fork' : 'isolated',
        status => 'running',
        output => '',
        error => '',
        createdAt => $timestamp,
        updatedAt => $timestamp,
    };
    my $result;
    my $ok = eval {
        $result = $runner->($request);
        1;
    };
    if (!$ok) {
        my $failure = $@;
        return {
            %$base,
            status => 'failed',
            error => error_code($failure) || 'SUBAGENT_ERROR',
        };
    }
    return {
        %$base,
        status => 'completed',
        output => $result->{output} // '',
    };
}

1;
