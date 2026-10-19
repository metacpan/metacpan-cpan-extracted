use strict;
use warnings;

use Test2::V0;

use IO::Handle;
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Async::Timer::Countdown;
use JSON::MaybeXS qw( encode_json decode_json );

use Net::Async::MCP::Server;
use Net::Async::MCP::Server::Transport::Stdio;

# A fully-formed 2026-07-28 request as a single wire line.
sub _req {
    my ( $id, $method, %params ) = @_;
    return encode_json({
        jsonrpc => '2.0',
        id      => $id,
        method  => $method,
        params  => {
            %params,
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    }) . "\n";
}

sub _server {
    my $server = Net::Async::MCP::Server->new(name => 'stdio-test');
    $server->register_tool(
        name        => 'echo',
        description => 'Echoes its argument',
        inputSchema => { type => 'object' },
        code        => sub { my ($args) = @_; return $args->{text} },
    );
    return $server;
}

# Every response is one line of JSON; decode whatever has been written so far.
sub _decode_lines {
    my ( $text ) = @_;
    return [ map { decode_json($_) } grep { length } split /\n/, ( $text // '' ) ];
}

# A real OS pipe, an in-memory sink for the responses, and a transport wired to
# both. No process is spawned and no socket is opened.
sub _wire_up {
    my ( $loop ) = @_;

    pipe( my $rh, my $wh ) or die "pipe: $!";
    $wh->autoflush(1);

    open my $out_fh, '>', \my $out or die "open scalar handle: $!";
    $out_fh->autoflush(1);

    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server       => _server(),
        read_handle  => $rh,
        write_handle => $out_fh,
    );
    $loop->add($transport) if $loop;

    return ( $transport, $wh, \$out );
}

# The regression this file exists for. handle_requests still blocks its caller
# until EOF, but it must no longer block the event loop while it does: the old
# `while (my $line = <STDIN>)` never yielded, so no other notifier in the loop
# could ever run and this subtest would hang on a pipe nothing ever fed.
#
# The timer is both the feeder and the witness. Each expiry records what has
# been written to the response sink *so far*, then feeds the next request line,
# so the recorded snapshots prove the ordering: the answer to line 1 is already
# on the sink by the time line 2 is fed. That is only possible if the read,
# the dispatch and the write all happened while handle_requests was still
# waiting — batching everything at EOF would leave the snapshot empty.
subtest 'handle_requests does not block the event loop' => sub {
    my $loop = IO::Async::Loop->new;
    my ( $transport, $wh, $out ) = _wire_up($loop);

    my @lines = (
        _req( 1, 'tools/list' ),
        _req( 2, 'tools/call', name => 'echo', arguments => { text => 'hello' } ),
    );

    my $ticks = 0;
    my @snapshots;
    my $timer;
    $timer = IO::Async::Timer::Countdown->new(
        delay     => 0.05,
        on_expire => sub {
            $ticks++;
            push @snapshots, $$out;

            if ( my $line = shift @lines ) {
                print {$wh} $line;
                $timer->start;
            }
            else {
                close $wh;    # EOF: graceful shutdown
            }
        },
    );
    $loop->add($timer);
    $timer->start;

    $transport->handle_requests;

    is( $ticks, 3, 'timer in the same loop expired three times while reading' );

    is( _decode_lines( $snapshots[0] ), [], 'nothing written before the first request was fed' );

    my $after_first = _decode_lines( $snapshots[1] );
    is( scalar @$after_first, 1, 'first response was written before the second request was fed' );
    is( $after_first->[0]{id}, 1, 'and it is the answer to the first request' );

    my $all = _decode_lines($$out);
    is( scalar @$all, 2, 'two responses in total' );
    is( $all->[1]{id}, 2, 'second response id' );
    is(
        $all->[1]{result}{content}[0]{text},
        'hello',
        'tools/call round-tripped through the transport',
    );
};

# The behaviours the readline loop had, unchanged.
subtest 'line handling' => sub {
    my $loop = IO::Async::Loop->new;
    my ( $transport, $wh, $out ) = _wire_up($loop);

    my $notification = encode_json({
        jsonrpc => '2.0',
        method  => 'notifications/progress',
    }) . "\n";

    my $unterminated = _req( 2, 'tools/list' );
    chomp $unterminated;

    print {$wh} "\n";             # empty line, skipped
    print {$wh} "not json\n";     # parse error, loop carries on
    print {$wh} _req( 1, 'tools/list' );
    print {$wh} $notification;    # no id, handle() returns undef, nothing written
    print {$wh} $unterminated;    # last line without its newline
    close $wh;

    $transport->handle_requests;
    ok( 1, 'handle_requests returned on EOF' );

    my $msgs = _decode_lines($$out);
    is( scalar @$msgs, 3, 'three lines written: parse error and two responses' );

    is( $msgs->[0]{error}{code}, -32700, 'invalid JSON answered with -32700' );
    is( $msgs->[0]{error}{message}, 'Parse error', 'parse error message' );
    is( $msgs->[0]{id}, undef, 'parse error carries a null id' );

    is( $msgs->[1]{id}, 1, 'request after the parse error still answered' );
    ok( $msgs->[1]{result}, 'and it is a result' );

    is( $msgs->[2]{id}, 2, 'final line without a trailing newline answered too' );
};

# The convenience path: no loop of its own, so handle_requests makes one.
subtest 'handle_requests without a loop' => sub {
    my ( $transport, $wh, $out ) = _wire_up(undef);

    ok( !$transport->loop, 'transport starts outside any loop' );

    print {$wh} _req( 9, 'tools/list' );
    close $wh;

    $transport->handle_requests;

    ok( $transport->loop, 'transport was added to a loop of its own' );

    my $msgs = _decode_lines($$out);
    is( scalar @$msgs, 1, 'one response' );
    is( $msgs->[0]{id}, 9, 'response id' );
};

# A response has to leave the write handle when it is written, not when the
# process exits or the buffer happens to fill. Perl block buffers a pipe, so
# without autoflush a finished response sits in the buffer while the client
# waits for it and the transport waits for the next request.
#
# Both directions are real pipes here, and the response pipe is deliberately
# left at its default buffering — turning it on in the test would hide exactly
# the bug this asserts. The reader on the response side lives in the same loop,
# so what it has collected mid-run is what the client would have seen by then:
# an empty snapshot means the response was still stuck in the buffer.
subtest 'responses are flushed as they are written' => sub {
    my $loop = IO::Async::Loop->new;

    pipe( my $req_r, my $req_w ) or die "pipe: $!";
    $req_w->autoflush(1);

    pipe( my $resp_r, my $resp_w ) or die "pipe: $!";

    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server       => _server(),
        read_handle  => $req_r,
        write_handle => $resp_w,
    );
    $loop->add($transport);

    my $seen = '';
    my $reader = IO::Async::Stream->new(
        read_handle       => $resp_r,
        close_on_read_eof => 0,
        on_read           => sub {
            my ( undef, $buffref ) = @_;
            $seen .= $$buffref;
            $$buffref = '';
            return 0;
        },
    );
    $loop->add($reader);

    my $ticks = 0;
    my $snapshot;
    my $timer;
    $timer = IO::Async::Timer::Countdown->new(
        delay     => 0.05,
        on_expire => sub {
            if ( ++$ticks == 1 ) {
                print {$req_w} _req( 7, 'tools/call', name => 'echo', arguments => { text => 'flushed' } );
                $timer->start;
            }
            else {
                $snapshot = $seen;    # what the client can see, mid-run
                close $req_w;         # EOF: graceful shutdown
            }
        },
    );
    $loop->add($timer);
    $timer->start;

    $transport->handle_requests;

    ok( length $snapshot, 'response left the write handle before the transport saw EOF' )
        or diag 'nothing had reached the read end of the response pipe';

    my $msgs = _decode_lines($snapshot);
    is( scalar @$msgs, 1, 'a whole line arrived, not a fragment' );
    is( $msgs->[0]{id}, 7, 'and it is the answer to the request' );
    is( $msgs->[0]{result}{content}[0]{text}, 'flushed', 'with the tool result' );

    $loop->remove($reader);
    close $resp_w;
};

# A client that does not read must not freeze the loop. The response is far
# larger than a pipe holds and nobody drains the pipe until a later timer, so a
# blocking print would sit inside the read callback and no timer could ever
# fire (the alarm turns that hang into a failure). With the write on the
# stream the timer after the request still fires, and the response is
# complete once the client does drain.
subtest 'a non-draining client does not block the loop' => sub {
    my $loop = IO::Async::Loop->new;

    pipe( my $req_r, my $req_w ) or die "pipe: $!";
    $req_w->autoflush(1);
    pipe( my $resp_r, my $resp_w ) or die "pipe: $!";

    my $text   = q(x) x 300_000;
    my $server = _server();
    $server->register_tool(
        name        => q(big),
        description => q(A response larger than a pipe holds),
        inputSchema => { type => q(object) },
        code        => sub { $text },
    );
    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server       => $server,
        read_handle  => $req_r,
        write_handle => $resp_w,
    );
    $loop->add($transport);

    my ( $ticks, $fired_while_pending, $draining, $seen ) = ( 0, 0, 0, '' );
    my $timer;
    $timer = IO::Async::Timer::Countdown->new(
        delay     => 0.05,
        on_expire => sub {
            $ticks++;
            if ( $ticks == 1 ) {
                print {$req_w} _req( 5, 'tools/call', name => q(big) );
            }
            elsif ( $ticks == 2 ) {
                $fired_while_pending = 1;    # reached only if the loop was not blocked
                close $req_w;                # EOF with the response still queued
            }
            else {
                $draining = 1;
                $resp_r->blocking(0);
                while ( defined sysread( $resp_r, my $buf, 65536 ) ) {
                    last unless length $buf;
                    $seen .= $buf;
                }
                return if $seen =~ /\n\z/;
            }
            $timer->start;
        },
    );
    $loop->add($timer);
    $timer->start;

    local $SIG{ALRM} = sub { die "blocked\n" };
    alarm 20;
    my $ok = eval { $transport->handle_requests; 1 };
    alarm 0;
    ok( $ok, 'handle_requests returned' ) or diag $@;

    ok( $fired_while_pending, 'timer fired while the response was undrained' );
    ok( $draining, 'client drained before handle_requests returned' );

    # After a failure the old blocking print left bytes in the PerlIO buffer;
    # close would block flushing them into a pipe nobody reads.
    $resp_w->blocking(0) unless $ok;
    close $resp_w;
    $resp_r->blocking(1);
    {
        local $/;
        $seen .= <$resp_r> // '';
    }
    my $msgs = _decode_lines($seen);
    is( scalar @$msgs, 1, 'one complete response line' );
    is( $msgs->[0]{id}, 5, 'it is the answer to the request' );
    is( $msgs->[0]{result}{content}[0]{text}, $text, 'with the whole tool result' );
};

subtest 'handle defaults'=> sub {
    my $transport = Net::Async::MCP::Server::Transport::Stdio->new( server => _server() );
    is( $transport->read_handle,  \*STDIN,  'read_handle defaults to STDIN' );
    is( $transport->write_handle, \*STDOUT, 'write_handle defaults to STDOUT' );
};

done_testing;
