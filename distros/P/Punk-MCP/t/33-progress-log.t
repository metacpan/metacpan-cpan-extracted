#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Punk::Test;
use Punk::Plugin::MCP ();

sub events {
    my ($body) = @_;
    return [map { JSON::PP->new->utf8->decode($_) } $body =~ /^data: (.*)$/mg];
}

use File::Temp ();
my $DIR = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub app {
    my ($opts) = @_;
    my $pkg = 'T33::A' . ++$n;
    my $dir = "$DIR/$n";
    eval qq{
        package ${pkg}::Controller::T;
        sub progress {
            my (\$c) = \@_;
            my \@r;
            push \@r, \$c->mcp_progress(1);
            push \@r, \$c->mcp_progress(2, 10, 'two of ten');
            push \@r, \$c->mcp_progress(2);
            push \@r, \$c->mcp_progress(1.5);
            push \@r, \$c->mcp_progress(2.5, 10);
            return join ',', \@r;
        }
        sub logs {
            my (\$c) = \@_;
            return join ',', map { \$c->mcp_log(\$_, { at => \$_ }, 'test') }
                qw(debug info warning error emergency);
        }
        sub shapes {
            my (\$c) = \@_;
            \$c->mcp_log('notice', 'plain words');
            \$c->mcp_log('critical', [1, 2], 'arr');
            \$c->mcp_log('alert', { n => 1, logger => 'own' }, 'test');
            return 'ok';
        }
        sub bad_level { \$_[0]->mcp_log('loud', 'x') }
        sub bad_progress { \$_[0]->mcp_progress('lots') }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        logging level => 'debug', to => sub { push \@main::LOG, \$_[0] };
        cache mcp => { backend => 'file', dir => '$dir' };
        get '/logs' => 'T#logs';
        plugin 'MCP' => { $opts };
        mcp tool => \$_ => { stream => 1 } => 'T#' . \$_ for qw(progress logs shapes bad_level bad_progress);
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}

our @LOG;
sub levels { [map { /\] \[(\w+)\] / ? $1 : '?' } @LOG] }

my $J = JSON::PP->new->canonical;
my %SID;
sub rpc {
    my ($t, $method, $params, %o) = @_;
    $t->post_ok('/mcp', body => $J->encode({ jsonrpc => '2.0', id => 1, method => $method,
                                            params => $params // {} }),
                type => 'application/json',
                headers => { 'MCP-Protocol-Version' => '2025-11-25',
                             ($SID{$t} ? ('Mcp-Session-Id' => $SID{$t}) : ()),
                             Accept => $o{accept} // 'application/json, text/event-stream' });
    $SID{$t} = $t->header('Mcp-Session-Id') if $t->header('Mcp-Session-Id');
    return $t->header('Content-Type') =~ /event-stream/
        ? events($t->body) : [JSON::PP->new->utf8->decode($t->body)];
}

# ---- progress -----------------------------------------------------------------------

my $t = app('');
my @w;
my $ev;
{
    local $SIG{__WARN__} = sub { push @w, @_ };
    $ev = rpc($t, 'tools/call', { name => 'progress', _meta => { progressToken => 42 } });
}
my @prog = grep { ($_->{method} // '') eq 'notifications/progress' } @$ev;
is_deeply([map { $_->{params} } @prog], [
    { progressToken => 42, progress => 1 },
    { progressToken => 42, progress => 2, total => 10, message => 'two of ten' },
    { progressToken => 42, progress => 2.5, total => 10 },
], 'progress against the token, total and message when given');
is($ev->[-1]{result}{content}[0]{text}, '1,1,0,0,1', 'mcp_progress says whether it sent');
is(scalar @w, 2, 'a value not above the last is dropped with a warning, twice');
like($w[0], qr/progress 2 is not above 2, not sent/, 'saying so');

$ev = rpc($t, 'tools/call', { name => 'progress' });
is_deeply([grep { $_->{method} } @$ev], [], 'no progressToken: nothing is sent');
is($ev->[-1]{result}{content}[0]{text}, '0,0,0,0,0', 'and mcp_progress returns 0');

$ev = rpc($t, 'tools/call', { name => 'progress', _meta => { progressToken => 'x' } },
          accept => 'application/json');
is($ev->[0]{result}{content}[0]{text}, '0,0,0,0,0',
    'a token but a JSON answer: nowhere to send it, so 0');

$ev = rpc($t, 'tools/call', { name => 'bad_progress' });
like($ev->[-1]{result}{content}[0]{text}, qr/mcp_progress takes a number/,
    'a progress that is not a number croaks');

# ---- logging -------------------------------------------------------------------------

$t = app(q{logging => 1, session => 'mcp'});
my $init = rpc($t, 'initialize', { protocolVersion => '2025-11-25' }, accept => 'application/json');
is_deeply($init->[0]{result}{capabilities}{logging}, {},
    'logging => 1 with sessions: the capability is advertised');

@LOG = ();
$ev = rpc($t, 'tools/call', { name => 'logs' });
my @logs = grep { ($_->{method} // '') eq 'notifications/message' } @$ev;
is_deeply([map { $_->{params}{level} } @logs], [qw(info warning error emergency)],
    'with no level set, info and above');
is_deeply($logs[0]{params}, { level => 'info', data => { at => 'info' }, logger => 'test' },
    'level, data and logger');
is($ev->[-1]{result}{content}[0]{text}, '0,1,1,1,1', 'mcp_log says whether it sent');
is_deeply(levels(), [qw(debug info warn error fatal)],
    'the request logger has every one, debug too, at the nearest Punk level');
like($LOG[1], qr{\[info\] POST /mcp - at=info logger=test\s*\z}, 'the hash as fields, the logger as one');

@LOG = ();
rpc($t, 'tools/call', { name => 'shapes' });
is_deeply(levels(), [qw(info fatal fatal)], 'notice is info, critical and alert are fatal');
like($LOG[0], qr{ - plain words\s*\z}, 'a string is the message');
like($LOG[1], qr{ - data=\[1,2\] logger=arr\s*\z}, 'an array is the data field');
like($LOG[2], qr{ - logger=own n=1\s*\z}, 'a hash with its own logger keeps it');

my $set = rpc($t, 'logging/setLevel', { level => 'error' }, accept => 'application/json');
is_deeply($set->[0]{result}, {}, 'logging/setLevel answers {}');
@LOG = ();
$ev = rpc($t, 'tools/call', { name => 'logs' });
is_deeply([map { $_->{params}{level} } grep { ($_->{method} // '') eq 'notifications/message' } @$ev],
    [qw(error emergency)], 'and filters what follows');
is(scalar @LOG, 5, 'but not what the request logger gets');

for my $case ([{ level => 'loud' }, 'unknown log level'], [{}, 'a level is required'],
              [{ level => ['x'] }, 'a level is required']) {
    my ($p, $msg) = @$case;
    my $r = rpc($t, 'logging/setLevel', $p, accept => 'application/json');
    is($r->[0]{error}{code}, -32602, "setLevel: $msg is -32602");
    is($r->[0]{error}{message}, $msg, "setLevel: $msg");
}
$ev = rpc($t, 'tools/call', { name => 'bad_level' });
like($ev->[-1]{result}{content}[0]{text}, qr/mcp_log level 'loud' is not one of debug, info/,
    'mcp_log with an unknown level croaks');

my $streamed = rpc($t, 'logging/setLevel', { level => 'emergency', _meta => { progressToken => 'lv' } });
is_deeply($streamed->[-1]{result}, {}, 'setLevel answered through a stream');
$ev = rpc($t, 'tools/call', { name => 'logs' });
is_deeply([map { $_->{params}{level} } grep { ($_->{method} // '') eq 'notifications/message' } @$ev],
    ['emergency'], 'is applied all the same');

@LOG = ();
$ev = rpc($t, 'tools/call', { name => 'logs' }, accept => 'application/json');
is($ev->[0]{result}{content}[0]{text}, '0,0,0,0,0', 'a JSON answer has nowhere to log to');
is(scalar @LOG, 5, 'the request logger has them all the same');

# ---- where logging does not exist ----------------------------------------------------

for my $case ([q{logging => 1, session => 0}, 'stateless'], [q{}, 'logging off']) {
    my ($opts, $name) = @$case;
    $t = app($opts);
    $init = rpc($t, 'initialize', { protocolVersion => '2025-11-25' }, accept => 'application/json');
    ok(!exists $init->[0]{result}{capabilities}{logging}, "$name: no logging capability");
    my $r = rpc($t, 'logging/setLevel', { level => 'debug' }, accept => 'application/json');
    is($r->[0]{error}{code}, -32601, "$name: setLevel is -32601");
    @LOG = ();
    $ev = rpc($t, 'tools/call', { name => 'logs' });
    is($ev->[-1]{result}{content}[0]{text}, '0,0,0,0,0', "$name: mcp_log sends nothing");
    is(scalar @LOG, 5, "$name: but the request logger has them");
}

@LOG = ();
$t->get_ok('/logs');
is($t->body, '"0,0,0,0,0"', 'as a web route there is no client to send to');
is_deeply(levels(), [qw(debug info warn error fatal)], 'and the request logger has them');
like($LOG[0], qr{\[debug\] GET /logs - at=debug logger=test\s*\z}, 'tagged with the route');

done_testing;
