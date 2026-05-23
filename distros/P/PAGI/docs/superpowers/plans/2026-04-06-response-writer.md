# Response Writer API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a push-style `$res->writer(%opts)` method that returns a `Writer` object directly, plus `on_close` callback stack, `is_closed` accessor, and `Future->fail` on write-after-close.

**Architecture:** `writer()` is a new async method on `PAGI::Response` that sends `http.response.start` and returns the `Writer`. The `Writer` class gains `on_close` (callback stack), `is_closed` (boolean), and changes `write()` to return `Future->fail` instead of `croak` on write-after-close. `stream()` benefits from the Writer changes automatically.

**Tech Stack:** Perl 5.18+, Test2::V0, Future::AsyncAwait

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `t/response-writer.t` | Create | Tests for push-style `writer()`, `on_close`, `is_closed`, write-after-close |
| `lib/PAGI/Response.pm` | Modify | New `writer()` method, Writer class changes |

---

## Task 1: Writer `on_close` Callback Stack and `is_closed`

### Files
- Create: `t/response-writer.t`
- Modify: `lib/PAGI/Response.pm:1091-1132`

- [ ] **Step 1: Write failing test — `on_close` fires on close**

Create `t/response-writer.t`:

```perl
use strict;
use warnings;

use Test2::V0;
use Future::AsyncAwait;

use PAGI::Response;

# Helper: create a Response with a capturing $send
sub make_response {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({}, $send);
    return ($res, \@sent);
}

subtest 'on_close callbacks fire when writer closes' => sub {
    my ($res, $sent) = make_response();
    my @fired;

    $res->stream(async sub {
        my ($writer) = @_;
        $writer->on_close(sub { push @fired, 'first' });
        $writer->on_close(sub { push @fired, 'second' });
        await $writer->write("data");
        await $writer->close;
    })->get;

    is \@fired, ['first', 'second'], 'on_close callbacks fire in registration order';
};

subtest 'on_close via constructor' => sub {
    my ($res, $sent) = make_response();
    my @fired;

    $res->stream(async sub {
        my ($writer) = @_;
        # We can't pass on_close via stream() currently, but we can test
        # that on_close added before any writes still fires
        $writer->on_close(sub { push @fired, 'cleanup' });
        await $writer->write("data");
        await $writer->close;
    })->get;

    is \@fired, ['cleanup'], 'on_close registered early still fires';
};

subtest 'is_closed returns correct state' => sub {
    my ($res, $sent) = make_response();

    $res->stream(async sub {
        my ($writer) = @_;
        is $writer->is_closed, 0, 'not closed initially';
        await $writer->write("data");
        is $writer->is_closed, 0, 'not closed after write';
        await $writer->close;
        is $writer->is_closed, 1, 'closed after close';
    })->get;
};

done_testing;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response-writer.t'`

Expected: FAIL — `on_close` method doesn't exist, `is_closed` method doesn't exist

- [ ] **Step 3: Implement `on_close`, `is_closed` on Writer**

In `lib/PAGI/Response.pm`, replace the entire `PAGI::Response::Writer` package (lines 1091-1132) with:

```perl
# Writer class for streaming responses
package PAGI::Response::Writer {
    use strict;
    use warnings;
    use Future::AsyncAwait;
    use Carp qw(croak);

    sub new {
        my ($class, $send, %opts) = @_;
        my $self = bless {
            send          => $send,
            bytes_written => 0,
            closed        => 0,
            _on_close     => [],
        }, $class;
        push @{$self->{_on_close}}, $opts{on_close} if $opts{on_close};
        return $self;
    }

    async sub write {
        my ($self, $chunk) = @_;
        return Future->fail('Writer already closed') if $self->{closed};
        $self->{bytes_written} += length($chunk // '');
        await $self->{send}->({
            type => 'http.response.body',
            body => $chunk,
            more => 1,
        });
    }

    async sub close {
        my ($self) = @_;
        return if $self->{closed};
        $self->{closed} = 1;
        await $self->{send}->({
            type => 'http.response.body',
            body => '',
            more => 0,
        });
        $_->() for @{$self->{_on_close}};
    }

    sub on_close {
        my ($self, $cb) = @_;
        push @{$self->{_on_close}}, $cb;
        return $self;
    }

    sub is_closed { $_[0]->{closed} }

    sub bytes_written { $_[0]->{bytes_written} }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response-writer.t'`

Expected: PASS

- [ ] **Step 5: Run existing response tests for regressions**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response.t'`

Expected: PASS — the `stream()` tests should still work because `new()` now accepts optional `%opts` and the constructor is backwards compatible. However, the write-after-close test in `t/response.t` may need updating if it expects a `croak` instead of a `Future->fail`. Check for this and fix if needed.

- [ ] **Step 6: Commit**

```bash
git add t/response-writer.t lib/PAGI/Response.pm
git commit -m "feat: add on_close callback stack and is_closed to Writer, change write-after-close to Future->fail"
```

---

## Task 2: Write-After-Close Returns Failed Future

### Files
- Modify: `t/response-writer.t`
- Possibly modify: `t/response.t` (if existing test expects croak)

- [ ] **Step 1: Write test — write after close returns failed Future**

Append to `t/response-writer.t` (before `done_testing`):

```perl
subtest 'write after close returns failed Future' => sub {
    my ($res, $sent) = make_response();
    my $write_error;

    $res->stream(async sub {
        my ($writer) = @_;
        await $writer->write("data");
        await $writer->close;

        my $f = $writer->write("after close");
        ok $f->is_failed, 'write after close returns failed Future';
        like [$f->failure]->[0], qr/closed/i, 'failure message mentions closed';
    })->get;
};

subtest 'write after close does not send events' => sub {
    my ($res, $sent) = make_response();

    $res->stream(async sub {
        my ($writer) = @_;
        await $writer->write("data");
        await $writer->close;

        # Capture count before bad write
        my $count = scalar @$sent;
        $writer->write("should not send");  # don't await — it's failed
        is scalar @$sent, $count, 'no new events sent after close';
    })->get;
};
```

- [ ] **Step 2: Run test to verify it passes (implementation from Task 1)**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response-writer.t'`

Expected: PASS

- [ ] **Step 3: Check if existing response.t tests expect croak on write-after-close**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response.t'`

If any test fails because it expected `croak`/`dies` on write-after-close, update that test to expect a failed Future instead. The test would look like:

```perl
# Old (if it exists):
like dies { $writer->write("x")->get }, qr/closed/;

# New:
my $f = $writer->write("x");
ok $f->is_failed, 'write after close fails';
```

- [ ] **Step 4: Commit**

```bash
git add t/response-writer.t t/response.t
git commit -m "test: add write-after-close tests, update existing tests for Future->fail"
```

---

## Task 3: Push-Style `writer()` Method on Response

### Files
- Modify: `t/response-writer.t`
- Modify: `lib/PAGI/Response.pm`

- [ ] **Step 1: Write failing test — `writer()` returns a Writer**

Append to `t/response-writer.t` (before `done_testing`):

```perl
subtest 'writer() returns a Writer and sends headers' => sub {
    my ($res, $sent) = make_response();

    $res->content_type('text/plain')->status(200);

    my $writer = $res->writer->get;

    isa_ok $writer, 'PAGI::Response::Writer';

    # Headers should already be sent
    is scalar @$sent, 1, 'http.response.start sent';
    is $sent->[0]{type}, 'http.response.start', 'start event sent';
    is $sent->[0]{status}, 200, 'status correct';

    # Write and close
    $writer->write("hello")->get;
    $writer->close->get;

    is $sent->[1]{body}, 'hello', 'chunk sent';
    is $sent->[1]{more}, 1, 'more=1 for chunk';
    is $sent->[2]{more}, 0, 'more=0 for close';
};

subtest 'writer() with on_close option' => sub {
    my ($res, $sent) = make_response();
    my @fired;

    my $writer = $res->writer(on_close => sub { push @fired, 'init' })->get;

    $writer->on_close(sub { push @fired, 'later' });

    $writer->write("data")->get;
    $writer->close->get;

    is \@fired, ['init', 'later'], 'constructor on_close fires first, then added ones';
};

subtest 'writer() prevents double send' => sub {
    my ($res, $sent) = make_response();

    $res->writer->get;

    like dies { $res->writer->get }, qr/already sent/i, 'second writer() croaks';
};

subtest 'writer() chains with response methods' => sub {
    my ($res, $sent) = make_response();

    my $writer = $res
        ->status(201)
        ->content_type('application/x-ndjson')
        ->header('X-Stream' => 'true')
        ->writer
        ->get;

    is $sent->[0]{status}, 201, 'status from chain';
    my %headers = map { $_->[0] => $_->[1] } @{$sent->[0]{headers}};
    is $headers{'content-type'}, 'application/x-ndjson', 'content-type from chain';
    is $headers{'x-stream'}, 'true', 'custom header from chain';
};
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response-writer.t'`

Expected: FAIL — `Can't locate object method "writer"`

- [ ] **Step 3: Implement `writer()` on Response**

In `lib/PAGI/Response.pm`, add the `writer` method after the `stream` method (around line 993):

```perl
async sub writer {
    my ($self, %opts) = @_;
    $self->_mark_sent;

    # Send headers
    await $self->{send}->({
        type    => 'http.response.start',
        status  => $self->status,
        headers => $self->{_headers},
    });

    return PAGI::Response::Writer->new($self->{send}, %opts);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response-writer.t'`

Expected: PASS

- [ ] **Step 5: Run all response tests**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response.t t/response-writer.t t/02-streaming.t'`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/PAGI/Response.pm t/response-writer.t
git commit -m "feat: add push-style writer() method to PAGI::Response"
```

---

## Task 4: `on_close` Fires on Auto-Close from `stream()`

### Files
- Modify: `t/response-writer.t`

- [ ] **Step 1: Write test — `on_close` fires when `stream()` auto-closes the writer**

Append to `t/response-writer.t` (before `done_testing`):

```perl
subtest 'on_close fires on stream() auto-close' => sub {
    my ($res, $sent) = make_response();
    my @fired;

    $res->stream(async sub {
        my ($writer) = @_;
        $writer->on_close(sub { push @fired, 'auto' });
        await $writer->write("data");
        # Do NOT call $writer->close — let stream() auto-close
    })->get;

    is \@fired, ['auto'], 'on_close fires when stream() auto-closes writer';
};

subtest 'on_close fires only once even with explicit + auto close' => sub {
    my ($res, $sent) = make_response();
    my $count = 0;

    $res->stream(async sub {
        my ($writer) = @_;
        $writer->on_close(sub { $count++ });
        await $writer->write("data");
        await $writer->close;
        # stream() will also try to close, but close() is idempotent
    })->get;

    is $count, 1, 'on_close fires exactly once (close is idempotent)';
};
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response-writer.t'`

Expected: PASS — `stream()` calls `$writer->close()` at the end (line 992 of Response.pm), and `close()` fires `on_close` callbacks. The idempotent guard in `close()` prevents double-firing.

- [ ] **Step 3: Commit**

```bash
git add t/response-writer.t
git commit -m "test: verify on_close fires on stream() auto-close and is idempotent"
```

---

## Task 5: POD Documentation

### Files
- Modify: `lib/PAGI/Response.pm`

- [ ] **Step 1: Add POD for `writer()` method**

Find the `stream()` POD documentation in `lib/PAGI/Response.pm` (search for `=head2 stream`) and add documentation for `writer` after it:

```pod
=head2 writer

    my $writer = await $res->writer;
    my $writer = await $res->writer(on_close => sub { cleanup() });

Returns a L<PAGI::Response::Writer> directly, sending headers immediately.
Unlike C<stream()>, the writer is not scoped to a callback — you own it
and must call C<close()> when done.

This is useful when the writer needs to be passed to event handlers,
pub/sub callbacks, timers, or other contexts outside a single function:

    async sub live_feed {
        my ($self, $ctx) = @_;
        my $writer = await $ctx->response
            ->content_type('text/plain')
            ->writer(on_close => sub { $bus->unsubscribe($id) });

        my $id = $bus->subscribe(async sub ($line) {
            await $writer->write("$line\n");
        });

        await $ctx->receive;    # wait for disconnect
        await $writer->close;
    }

The optional C<on_close> callback is registered before headers are sent,
eliminating any race window with fast client disconnects.
```

- [ ] **Step 2: Add POD for `on_close` and `is_closed` on Writer**

Find the Writer documentation section (search for `bytes_written` in the POD) and add:

```pod
=head3 on_close

    $writer->on_close(sub { cleanup() });

Registers a callback to fire when the writer closes (either explicitly
or via client disconnect). Multiple callbacks can be registered; they
fire in registration order. Returns C<$self> for chaining.

=head3 is_closed

    if ($writer->is_closed) { ... }

Returns true if the writer has been closed.
```

- [ ] **Step 3: Update write() POD to document Future->fail behavior**

Find the `write` documentation in the Writer POD and add:

```pod
Writing after close returns a failed L<Future> rather than throwing.
This allows cleanup code that races with close to handle the error
gracefully via C<await>.
```

- [ ] **Step 4: Verify POD parses**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && perl -MPod::Simple::SimpleTree -e "Pod::Simple::SimpleTree->new->parse_file(shift)->root or die" lib/PAGI/Response.pm && echo "POD OK"'`

Expected: POD OK

- [ ] **Step 5: Commit**

```bash
git add lib/PAGI/Response.pm
git commit -m "docs: add POD for writer(), on_close, is_closed, and write-after-close behavior"
```

---

## Task 6: Final Validation

- [ ] **Step 1: Run the full test suite**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/'`

Expected: All tests PASS (same pre-existing failures as before, no new failures)

- [ ] **Step 2: Review — verify `stream()` still works correctly with updated Writer**

Read `lib/PAGI/Response.pm` and confirm:
- `stream()` still creates Writer with `->new($self->{send})` (no extra args — backwards compatible)
- `stream()` still auto-closes via `$writer->close() unless $writer->{closed}` — but now should use `$writer->is_closed` instead of reaching into internals

- [ ] **Step 3: Fix `stream()` to use `is_closed` instead of `$writer->{closed}`**

In `lib/PAGI/Response.pm`, update the stream method's auto-close guard (around line 992):

```perl
# Old:
await $writer->close() unless $writer->{closed};

# New:
await $writer->close() unless $writer->is_closed;
```

- [ ] **Step 4: Run response tests again**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/response.t t/response-writer.t'`

Expected: PASS

- [ ] **Step 5: Commit if changed**

```bash
git add lib/PAGI/Response.pm
git commit -m "refactor: use is_closed accessor in stream() instead of internal field"
```
