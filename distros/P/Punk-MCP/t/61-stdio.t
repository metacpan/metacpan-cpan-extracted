#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use FindBin;
use IPC::Open3 ();
use JSON::PP ();
use Symbol ();

# A real `punk mcp` child over pipes: one line in, its lines out.

my $APP = File::Spec->catdir($FindBin::Bin, 'data', 'stdio-app');
my @INCS = map { "-I$_" } grep { !ref } @INC;
my $J = JSON::PP->new->canonical;

sub start {
    my (@args) = @_;
    my $errfile = File::Temp->new;
    open my $efh, '>', $errfile->filename or die $!;
    my ($in, $out) = (Symbol::gensym, Symbol::gensym);
    my $pid = IPC::Open3::open3($in, $out, '>&' . fileno($efh),
        $^X, @INCS, '-MPunk::Command', '-e', 'exit Punk::Command->main(@ARGV)',
        'mcp', '--dir', $APP, @args);
    close $efh;
    $in->autoflush(1);
    return { pid => $pid, in => $in, out => $out, err => $errfile };
}
sub send_line { my ($p, $msg) = @_; print { $p->{in} } (ref $msg ? $J->encode($msg) : $msg), "\n" }
sub read_line {
    my ($p) = @_;
    my $line;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 20;
        $line = readline $p->{out};
        alarm 0;
        1;
    } or return 'TIMEOUT';
    return undef unless defined $line;
    chomp $line;
    return JSON::PP->new->utf8->decode($line);
}
sub req { +{ jsonrpc => '2.0', id => $_[0], method => $_[1], ($_[2] ? (params => $_[2]) : ()) } }
sub call { my ($p, $id, $name, $args, $meta) = @_;
    send_line($p, req($id, 'tools/call', { name => $name, arguments => $args // {},
                                           ($meta ? (_meta => $meta) : ()) })) }
sub finish {
    my ($p) = @_;
    close $p->{in};
    my $rest = read_line($p);
    waitpid($p->{pid}, 0);
    return ($rest, $? >> 8);
}

# ---- a whole conversation ---------------------------------------------------------

my $p = start('--token', 'sekret');
send_line($p, req(1, 'initialize', { protocolVersion => '2025-11-25' }));
my $r = read_line($p);
is($r->{result}{protocolVersion}, '2025-11-25', 'initialize, a line back');
ok($r->{result}{capabilities}{resources}{subscribe}, 'the process is the session: subscribe is offered');
ok($r->{result}{capabilities}{logging}, 'and logging');

send_line($p, { jsonrpc => '2.0', method => 'notifications/initialized' });
send_line($p, req(2, 'tools/list'));
$r = read_line($p);
is($r->{id}, 2, 'a notification writes nothing: the next line answers the next request');
is(scalar @{ $r->{result}{tools} }, 5, 'tools/list');

call($p, 3, 'echo', { say => 'hi' });
$r = read_line($p);
is_deeply($r->{result}{structuredContent}, { said => 'hi', user => 'stdio-user' },
    'a call, with principal giving $c->mcp_user');

call($p, 4, 'slow', {}, { progressToken => 'tok' });
my @lines = map { read_line($p) } 1 .. 3;
is($lines[0]{method}, 'notifications/progress', 'progress comes first, as its own line');
is($lines[0]{params}{progressToken}, 'tok', 'against the token');
is($lines[1]{method}, 'notifications/message', 'then the log line');
is($lines[2]{id}, 4, 'then the answer');

send_line($p, req(5, 'logging/setLevel', { level => 'error' }));
is_deeply(read_line($p)->{result}, {}, 'logging/setLevel');
call($p, 6, 'slow', {}, { progressToken => 'tok2' });
@lines = (read_line($p), read_line($p));
is($lines[0]{method}, 'notifications/progress', 'progress still comes');
is($lines[1]{id}, 6, 'but the warning is below the level now, and the answer follows');

send_line($p, req(7, 'resources/subscribe', { uri => 'books://1' }));
is_deeply(read_line($p)->{result}, {}, 'resources/subscribe');
call($p, 8, 'touch');
@lines = (read_line($p), read_line($p));
is_deeply($lines[0], { jsonrpc => '2.0', method => 'notifications/resources/updated',
                       params => { uri => 'books://1' } },
    'an update to a subscribed URI is a line, written as it happens');
is($lines[1]{id}, 8, 'and the unsubscribed one is not: the answer is next');

call($p, 9, 'stray');
is(read_line($p)->{result}{content}[0]{text}, 'still fine',
    'a print in a controller does not reach the protocol stream');

call($p, 10, 'later');
is(read_line($p)->{result}{content}[0]{text}, 'from a future', 'a Future is awaited');

send_line($p, 'this is not json');
is(read_line($p)->{error}{code}, -32700, 'a line that is not JSON is -32700');
send_line($p, req(11, 'ping'));
is_deeply(read_line($p)->{result}, {}, 'and the next line is served');

send_line($p, req(12, 'initialize', { protocolVersion => '2025-11-25' }));
is(read_line($p)->{error}{code}, -32600, 'a second initialize is refused');

my ($rest, $code) = finish($p);
ok(!defined $rest, 'at EOF nothing more is written');
is($code, 0, 'and it exits 0');
my $stderr = do { local $/; open my $fh, '<', $p->{err}->filename; <$fh> };
like($stderr, qr/this must not reach the protocol/, 'the stray print went to stderr');

# ---- who may call ------------------------------------------------------------------

$p = start();
send_line($p, req(1, 'initialize', { protocolVersion => '2025-11-25' }));
$r = read_line($p);
is($r->{error}{code}, -32001, 'no token: the guard refuses');
is($r->{error}{data}{reason}, 'refused (401): no token', 'with the guard\'s words');
finish($p);

{
    local $ENV{PUNK_MCP_TOKEN} = 'sekret';
    $p = start();
    send_line($p, req(1, 'ping'));
    is_deeply(read_line($p)->{result}, {}, 'PUNK_MCP_TOKEN is the token');
    finish($p);
}
{
    local $ENV{PMCP_TEST_TRUST} = 1;
    $p = start();
    send_line($p, req(1, 'ping'));
    is_deeply(read_line($p)->{result}, {}, 'stdio_trust lets the local process in without one');
    finish($p);
}

done_testing;
