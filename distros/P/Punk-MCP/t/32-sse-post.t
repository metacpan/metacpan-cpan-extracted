#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Punk::Test;
use Punk::Plugin::MCP ();

# A reference SSE reader: events as [id, event, data], and comment lines.
sub sse {
    my ($body) = @_;
    my (@events, @comments);
    for my $block (split /\n\n/, $body) {
        my %e;
        for my $line (split /\n/, $block) {
            if ($line =~ /^:\s?(.*)/) { push @comments, $1; next }
            my ($k, $v) = $line =~ /^([^:]+): ?(.*)$/ or next;
            $e{$k} = defined $e{$k} ? "$e{$k}\n$v" : $v;
        }
        push @events, { %e, json => JSON::PP->new->utf8->decode($e{data}) } if exists $e{data};
    }
    return (\@events, \@comments);
}

my $n = 0;
sub app {
    my ($opts, $decl) = @_;
    my $pkg = 'T32::A' . ++$n;
    eval qq{
        package ${pkg}::Controller::T;
        sub plain  { 'plain' }
        sub slow   { my (\$c) = \@_; \$c->mcp_progress(1, 2); 'slow done' }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        plugin 'MCP' => { session => 0, $opts };
        mcp tool => plain => 'T#plain';
        mcp tool => slow => { stream => 1 } => 'T#slow';
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}

my $J = JSON::PP->new->canonical;
sub call {
    my ($t, $tool, %o) = @_;
    my $msg = { jsonrpc => '2.0', id => $o{id} // 1, method => $o{method} // 'tools/call',
                params => { name => $tool, ($o{token} ? (_meta => { progressToken => $o{token} }) : ()) } };
    delete $msg->{params} if $o{method} && $o{method} ne 'tools/call';
    $t->post_ok('/mcp', body => $J->encode($msg), type => 'application/json',
                headers => { 'MCP-Protocol-Version' => '2025-11-25',
                             (defined $o{accept} ? (Accept => $o{accept}) : ()),
                             %{ $o{headers} || {} } });
    return $t->header('Content-Type') // '';
}
my $BOTH = 'application/json, text/event-stream';

# ---- the rule ------------------------------------------------------------------

my $t = app('');
is(call($t, 'plain', accept => $BOTH), 'application/json', 'auto: a plain tool answers JSON');
is(call($t, 'slow',  accept => $BOTH), 'text/event-stream', 'auto: a stream => 1 tool streams');
is(call($t, 'plain', accept => $BOTH, token => 'p'), 'text/event-stream',
    'auto: a progressToken streams any tool');
is(call($t, 'slow', accept => 'application/json'), 'application/json',
    'not when Accept does not allow text/event-stream');
is(call($t, 'slow'), 'application/json', 'nor with no Accept at all');
is(call($t, 'x', accept => $BOTH, method => 'ping'), 'application/json', 'auto: ping is JSON');

$t = app(q{stream => 'json'});
is(call($t, 'slow', accept => $BOTH, token => 'p'), 'application/json',
    "stream => 'json' never streams");

$t = app(q{stream => 'always'});
is(call($t, 'x', accept => $BOTH, method => 'ping'), 'text/event-stream',
    "stream => 'always' streams every request");
is(call($t, 'x', accept => 'application/json', method => 'ping'), 'application/json',
    'still only when Accept allows it');
$t->post_ok('/mcp', body => '{"jsonrpc":"2.0","method":"notifications/initialized"}',
            type => 'application/json', headers => { Accept => $BOTH });
is($t->status, 202, 'a notification is never streamed');

# ---- the frames ---------------------------------------------------------------------

$t = app('');
call($t, 'slow', accept => $BOTH, token => 'tok', id => 'r-1',
     headers => { Origin => 'http://localhost' }, );
my ($events, $comments) = sse($t->body);
is($t->status, 200, 'a streamed answer is 200');
is($t->header('Cache-Control'), 'no-store', 'no-store');
is($t->header('X-Accel-Buffering'), 'no', 'X-Accel-Buffering: no, so a proxy does not hold it');
is(scalar @$events, 2, 'a progress event, then the response');
is_deeply([map { $_->{id} } @$events], [1, 2], 'event ids count up');
is_deeply([map { $_->{event} } @$events], ['message', 'message'], 'every event is a message');
is($events->[0]{json}{method}, 'notifications/progress', 'the first is the progress');
is($events->[-1]{json}{id}, 'r-1', 'the last is the response, with its id');
is($events->[-1]{json}{result}{content}[0]{text}, 'slow done', 'and its result');
is_deeply($comments, [], 'no heartbeat off a Hyperman loop');

# ---- a croak inside the stream ---------------------------------------------------------

{
    local $Punk::Plugin::MCP::_TEST_CROAK = 1;
    call($t, 'slow', accept => $BOTH, id => 5);
}
($events) = sse($t->body);
is(scalar @$events, 1, 'a croak in the dispatch still writes one event');
is_deeply($events->[0]{json}, { jsonrpc => '2.0', id => 5,
                                error => { code => -32603, message => 'internal error' } },
    'an internal error for the request, and then the stream ends cleanly');
call($t, 'slow', accept => $BOTH);
($events) = sse($t->body);
is($events->[-1]{json}{result}{content}[0]{text}, 'slow done', 'the next call is whole');

# ---- cancellation ----------------------------------------------------------------------------

# The tool sends its own cancellation through the dispatcher while it runs, as
# a second request would on a live worker (14).
my $cancel_app = 'T32::Cancel';
eval qq{
    package ${cancel_app}::Controller::T;
    sub run {
        my (\$c) = \@_;
        my \$before = Punk::Plugin::MCP::_live_count();
        Punk::Plugin::MCP::_rpc(\$c, '{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"job-9"}}');
        my \$mine = \$c->mcp->cancelled;
        Punk::Plugin::MCP::_rpc(\$c, '{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":9}}');
        return { live => \$before, cancelled => \$mine };
    }
    package $cancel_app;
    use Punk; use Punk::Plugin::MCP;
    plugin 'MCP' => { session => 0 };
    mcp tool => run => { stream => 1 } => 'T#run';
    1;
} or die $@;
$t = Punk::Test->new($cancel_app);
call($t, 'run', accept => $BOTH, id => 'job-9');
($events) = sse($t->body);
is_deeply($events->[-1]{json}{result}{structuredContent}, { live => 1, cancelled => 1 },
    'a streaming call is registered, and notifications/cancelled for its id sets the flag');
is(Punk::Plugin::MCP::_live_count(), 0, 'and it is unregistered when it ends');

call($t, 'run', accept => $BOTH, id => 9);
($events) = sse($t->body);
is($events->[-1]{json}{result}{structuredContent}{cancelled}, 0,
    'the string "job-9" does not cancel the number 9');

call($t, 'run', accept => 'application/json', id => 'job-9');
is(JSON::PP->new->decode($t->body)->{result}{structuredContent}{live}, 0,
    'a call answered with JSON is not registered: there is nothing to cancel into');

done_testing;
