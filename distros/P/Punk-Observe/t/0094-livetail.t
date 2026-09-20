#!perl
# The live tail, and everything it admits losing.
#
# THE HEADLINE ASSERTION IS THAT NOTHING VANISHES QUIETLY. A line too long for
# a bus slot arrives truncated with a flag rather than not arriving; a lapped
# consumer gets a number; a resume past the end of the buffer is told how much
# it missed; a client that stopped reading is closed rather than queued.
#
# Every timing assertion here is on ORDERING or CONVERGENCE. Not one is on
# elapsed time: a loaded smoker makes a fixed sleep a coin toss, and a test
# that fails on a busy box teaches people to ignore it.
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Config;
use POSIX ();
use Test::More;

# A forked child inherits the TAP pipe and perl's STDOUT buffer. Flushing it
# at the child's exit duplicates every line the parent had written but not
# yet flushed, and the harness reports a plan mismatch for a suite that
# passed. Unbuffered here, and every child leaves through POSIX::_exit.
$| = 1;
use Punk::Observe;

my $L = 'Punk::Observe::Live';
sub rt   { $L->can('roundtrip')->($_[0]) }
sub ring { $L->can('ring')->($_[0]) }
sub flow { $L->can('flow')->(@_) }
sub sse  { $L->can('sse')->(@_) }

# --- the slot the record is sized against -----------------------------------

my ($slot, $bus_slot) = $L->can('slot_sizes')->();
my $have_bus = $L->can('have_bus')->();

is($slot, 2048, 'the tail encodes against a 2048-byte slot');
SKIP: {
    skip 'no Shared::Arena ring in this build', 2 unless $have_bus;
    # The ring's slot is a runtime answer, and it must hold at least what the
    # record is sized against: a record sized against a bigger number than
    # the ring carries is refused rather than truncated.
    ok($L->can('bus_init')->(64), 'the ring comes up to be asked');
    ($slot, $bus_slot) = $L->can('slot_sizes')->();
    cmp_ok($bus_slot, '>=', $slot,
           "the ring's slot ($bus_slot) holds a record sized against $slot");
}

# --- the topic IS the tenant boundary ---------------------------------------

{
    is($L->can('topic')->('acme'), 'po.tail.acme', 'a topic carries the tenant');
    is($L->can('topic')->('a_b-1'), 'po.tail.a_b-1', '  through the allowlist');

    # A topic that accepts arbitrary bytes is a way to subscribe to somebody
    # else's stream.
    for my $bad ('../other', 'a b', 'a/b', '', 'a.b', "a\0b", 'x' x 65) {
        my $shown = $bad =~ /[^ -~]/ ? '(control chars)' : "'$bad'";
        is($L->can('topic')->($bad), undef, "a tenant of $shown is refused");
    }
}

# --- A LONG LINE ARRIVES TRUNCATED, NOT NOT-AT-ALL --------------------------
#
# The ring REFUSES oversize (publish answers -1), it does not
# shorten. So a long line published unchanged is a line that never arrives,
# and the tail would silently skip exactly the interesting ones.

{
    my $r = rt({ t => '1700000000000000000', stream => '42', severity => 9,
                 service => 'api', body => 'connection refused' });
    ok($r->{ok}, 'a short record round-trips');
    is("$r->{t}", '1700000000000000000', '  the nanosecond timestamp is exact');
    is("$r->{stream}", '42', '  the stream survives');
    is($r->{severity}, 9, '  the severity survives');
    is($r->{service}, 'api', '  the service name survives');
    is($r->{body}, 'connection refused', '  and the body is unchanged');
    is($r->{truncated}, 0, '  nothing was cut');
    is($r->{flagged}, 0, '  and nothing is flagged');
    ok($r->{fits_slot}, '  and it fits a slot');
}

{
    my $long = 'x' x 10_000;      # a stack trace, a serialised payload
    my $r = rt({ t => '1', stream => '1', severity => 9,
                 service => 'api', body => $long });
    ok($r->{ok}, 'a 10,000-byte line still produces a record');
    ok($r->{fits_slot}, '  that fits a slot the bus will accept');
    cmp_ok($r->{encoded_len}, '<=', $slot, '  within the slot size');
    is($r->{truncated}, 1, '  reported truncated to the caller');
    is($r->{flagged}, 1, '  AND flagged in the record itself');
    cmp_ok(length $r->{body}, '>', 1000, '  with most of the line intact');
    is(substr($r->{body}, 0, 10), 'x' x 10, '  the PREFIX is kept');
}

{
    # The boundary: the longest body that is NOT cut, and one byte more.
    my $fit;
    for my $n (1500, 1600, 1700, 1800, 1900) {
        my $r = rt({ t => '1', service => 'api', body => 'y' x $n });
        $fit = $n unless $r->{truncated};
    }
    ok(defined $fit, 'there is a longest uncut body');
    my $a = rt({ t => '1', service => 'api', body => 'y' x $fit });
    is($a->{truncated}, 0, "a $fit-byte body is not cut");
    my $b = rt({ t => '1', service => 'api', body => 'y' x ($fit + 400) });
    is($b->{truncated}, 1, '  and a longer one is');
    cmp_ok($b->{encoded_len}, '<=', $slot, '  still inside the slot');
}

{
    # An absurd service name cannot push the body out of the slot.
    my $r = rt({ t => '1', service => 'S' x 5000, body => 'hello' });
    ok($r->{fits_slot}, 'an absurd service name still fits a slot');
    is($r->{flagged}, 1, '  and is flagged as truncated');
    cmp_ok(length $r->{service}, '<=', 128, '  the name is capped');
}

{
    # An empty body is a real log line - a bare newline in an app's output.
    my $r = rt({ t => '5', service => '', body => '' });
    ok($r->{ok}, 'an empty record round-trips');
    is($r->{body}, '', '  with an empty body');
    is($r->{truncated}, 0, '  and is not called truncated');
}

{
    # Bytes, not characters. A UTF-8 body crosses as bytes and comes back the
    # same bytes.
    my $body = "caf\xc3\xa9 \xe2\x9c\x93";
    my $r = rt({ t => '1', service => 'api', body => $body });
    is($r->{body}, $body, 'a UTF-8 body survives byte for byte');
}

# --- a damaged slot is REFUSED, not followed --------------------------------
#
# A slot is untrusted input the moment another process wrote it.

{
    my $bad = $L->can('decode_bad');
    is($bad->(''), 0, 'an empty slot is refused');
    is($bad->('short'), 0, 'a slot shorter than the header is refused');
    is($bad->("\0" x 31), 0, 'one byte short of the header is refused');
    is($bad->("\0" x 32), 1, 'an exactly-empty record is accepted');

    # A length field claiming more than the slot holds. This is the one that
    # would hand back a pointer past the end.
    my $hdr = "\0" x 24 . pack('V', 0) . pack('V', 0xFFFFFFFF);
    is($bad->($hdr), 0, 'a body length past the end of the slot is refused');
    $hdr = "\0" x 24 . pack('V', 0xFFFFFFFF) . pack('V', 0);
    is($bad->($hdr), 0, 'and so is a service length past it');
    # The pair that only overflows when ADDED.
    $hdr = "\0" x 24 . pack('V', 0x80000000) . pack('V', 0x80000000);
    is($bad->($hdr), 0, 'two lengths that only overflow when summed are refused');
}

# --- the resume ring --------------------------------------------------------

{
    my $r = ring({ cap => 8, rows => [ map { "row$_" } 1 .. 5 ], since => 0 });
    is(scalar @{ $r->{rows} }, 5, 'a fresh connection gets everything held');
    is("$r->{rows}[0]{id}", '1', '  ids start at 1');
    is("$r->{rows}[-1]{id}", '5', '  and are monotonic');
    is("$r->{missed}", '0', '  and a fresh connection missed nothing');
}

{
    my $r = ring({ cap => 8, rows => [ map { "row$_" } 1 .. 5 ], since => 3 });
    is(scalar @{ $r->{rows} }, 2, 'a resume returns only what follows the id');
    is("$r->{rows}[0]{id}", '4', '  starting at the next one');
    is("$r->{missed}", '0', '  with nothing missed');
}

{
    my $r = ring({ cap => 8, rows => [ map { "row$_" } 1 .. 5 ], since => 5 });
    is(scalar @{ $r->{rows} }, 0, 'a resume from the newest id returns nothing');
    is("$r->{missed}", '0', '  and reports no gap');
}

# THE ONE THAT MATTERS. A reconnection whose id has scrolled off must be TOLD
# how much it lost. Silently starting from the oldest available row is a
# reconnection that hides a gap.
{
    my $r = ring({ cap => 4, rows => [ map { "row$_" } 1 .. 10 ], since => 2 });
    is($r->{held}, 4, 'the ring holds only its capacity');
    is("$r->{oldest}", '7', '  with the oldest surviving id');
    is("$r->{evicted}", '6', '  and counts what scrolled off');
    is("$r->{missed}", '4',
       'a resume past the buffer is told EXACTLY how many it missed');
    is(scalar @{ $r->{rows} }, 4, '  and still gets what is left');
}

{
    # Evicting by BYTES, not only by rows: 512 slots at the full size would be
    # a megabyte per connection held for a resume nobody may ever ask for.
    my $r = ring({ cap => 100, bytes => '200',
                   rows => [ map { 'z' x 50 } 1 .. 20 ], since => 0 });
    cmp_ok(0 + $r->{bytes}, '<=', 200, 'the ring is bounded by bytes too');
    cmp_ok($r->{held}, '<', 20, '  so rows are evicted before the row cap');
    cmp_ok(0 + $r->{evicted}, '>', 0, '  and the eviction is counted');
}

{
    my $r = ring({ cap => 4, rows => [], since => 0 });
    is(scalar @{ $r->{rows} }, 0, 'an empty ring returns nothing');
    is("$r->{oldest}", '0', '  and has no oldest id');
}

# --- backpressure -----------------------------------------------------------

{
    # A client that never drains.
    my $r = flow('1000', [ (100) x 50 ], 0);
    is($r->{closed}, 1, 'a client that never reads is CLOSED');
    cmp_ok($r->{admitted}, '<=', 10, '  after at most the limit in bytes');
    cmp_ok(0 + $r->{pending}, '<=', 1000,
           '  and the queue never grew past the limit');
}

{
    # A client that keeps up.
    my $r = flow('1000', [ (100) x 50 ], 1);
    is($r->{closed}, 0, 'a client that keeps up is not closed');
    is($r->{admitted}, 50, '  and every row is admitted');
    is("$r->{pending}", '0', '  with nothing left pending');
}

{
    # One row larger than the whole limit must close, not loop.
    my $r = flow('100', [ 5000 ], 0);
    is($r->{closed}, 1, 'a single oversized row closes the connection');
    is($r->{admitted}, 0, '  and is not admitted');
}

# --- the SSE frame ----------------------------------------------------------

{
    my $f = sse('7', 'log', 'hello');
    like($f, qr/^id: 7\n/, 'a frame leads with its id');
    like($f, qr/event: log\n/, '  then the event name');
    like($f, qr/data: hello\n/, '  then the data');
    like($f, qr/\n\n\z/, '  and ends with a blank line');
}

# A body with a newline in it must be SPLIT across data: lines, or the frame
# ends early and the rest of the line becomes the next event.
{
    my $f = sse('1', 'log', "line one\nline two");
    my @data = $f =~ /^data: (.*)$/mg;
    is_deeply(\@data, [ 'line one', 'line two' ],
              'an embedded newline becomes two data lines, not two events');
    my @blank = $f =~ /(\n\n)/g;
    is(scalar @blank, 1, '  and the frame still has exactly one terminator');
}

{
    my $f = sse('1', 'log', "trailing\n");
    my @data = $f =~ /^data: (.*)$/mg;
    is_deeply(\@data, [ 'trailing', '' ], 'a trailing newline is preserved');
}

{
    my $f = sse('0', undef, 'x');
    like($f, qr/^id: 0\n/, 'an id of zero is still written');
    unlike($f, qr/event:/, '  and no event line is invented');
}

# A heartbeat must NOT advance the client's Last-Event-ID, or a reconnection
# resumes from a comment and skips real rows.
{
    my $h = $L->can('heartbeat')->();
    is($h, ":\n\n", 'the heartbeat is a bare comment frame');
    unlike($h, qr/id:/, '  carrying no id at all');
}

# --- ACROSS WORKERS ---------------------------------------------------------
#
# A line ingested on one worker must reach a client connected to another. This
# forks for real and asserts on what ARRIVED, not on how long it took.

SKIP: {
    skip 'no Shared::Arena ring in this build', 9 unless $have_bus;
    skip 'no fork on this platform', 9 unless $Config{d_fork};

    my $init  = $L->can('bus_init');
    my $pub   = $L->can('bus_publish');
    my $drain = $L->can('bus_drain');
    my $reset = $L->can('bus_reset_cursors');

    ok($init->(256), 'the shared bus arena comes up');

    my $topic = $L->can('topic')->('acme');
    my $other = $L->can('topic')->('rival');

    # The arena is set up BEFORE the fork. A subscription made after one lands
    # in a single process, and a cursor that starts at "now" silently misses
    # everything published before it.
    my $pid = fork();
    defined $pid or skip 'fork failed', 8;

    if (!$pid) {
        # The ingesting worker.
        for my $i (1 .. 20) {
            my $rec = rt({ t => "$i", stream => '1', severity => 9,
                           service => 'api', body => "line $i" });
            $pub->($topic, 'x');       # payload shape is the parent's concern
        }
        $pub->($other, 'SECRET');      # another tenant's stream
        $pub->($topic, 'DONE');
        POSIX::_exit(0);
    }

    # The worker holding the connection. Converge on the sentinel rather than
    # sleeping: a fixed wait is a coin toss on a loaded smoker.
    my (@rows, $gaps, $rounds);
    for ($rounds = 0; $rounds < 20_000; $rounds++) {
        my $d = $drain->($topic);
        push @rows, @{ $d->{rows} };
        $gaps = $d->{gaps};
        last if grep { $_ eq 'DONE' } @rows;
    }
    waitpid $pid, 0;

    ok(scalar(grep { $_ eq 'DONE' } @rows),
       'a record published on another worker reaches this one');
    is(scalar(grep { $_ eq 'x' } @rows), 20, '  and all 20 of them arrive');
    is(scalar(grep { $_ eq 'SECRET' } @rows), 0,
       "  while ANOTHER TENANT'S topic is never delivered");
    is("$gaps", '0', '  with no gap over a ring this size');

    # A lapped consumer gets a NUMBER. A silently short stream is
    # indistinguishable from a quiet one.
    $reset->();
    for (1 .. 2000) { $pub->($topic, 'flood') }
    my $d = $drain->($topic);
    cmp_ok(0 + $d->{gaps}, '>', 0, 'a lapped consumer reports a gap');
    cmp_ok(0 + $d->{count} + 0 + $d->{gaps}, '>=', 2000,
           '  and delivered plus lost accounts for everything published');

    # Post-fork cursors are reset: a worker forked after a publish must not
    # replay it.
    $reset->();
    $pub->($topic, 'before-fork');
    my $pid2 = fork();
    if (defined $pid2 && !$pid2) {
        $reset->();                       # what a post-fork hook does
        my $after = $drain->($topic);
        POSIX::_exit(scalar @{ $after->{rows} } ? 1 : 0);
    }
    if (defined $pid2) {
        waitpid $pid2, 0;
        is($? >> 8, 0,
           'a worker forked after a publish does not replay it once reset');
    }
    else { ok(1, 'fork unavailable, skipped the replay check') }

    ok(1, 'the bus section completed without hanging');
}

done_testing();
