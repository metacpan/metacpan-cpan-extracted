# Net::Clacks Disconnect Handling Optimizations

Date: 2025-12-19

## Problem Statement

Two issues were observed:
1. 100% CPU usage after many clients connected/disconnected
2. Inability to connect after many clients had connected/disconnected

## Root Cause Analysis

### CPU Spin Issue

When a client disconnects (especially abruptly), the server's `IO::Select` still contains the dead socket. The `sysread()` call returns:
- `0` for EOF (clean disconnect)
- `undef` with `$!{EAGAIN}` for temporary conditions
- `undef` with other errors for permanent failures

The original code treated EOF (`sysread` returning 0) the same as temporary errors, incrementing a `failcount` and only disconnecting after 6 failures. This caused:
- Dead sockets to remain in the selector
- `select()` returning immediately (socket is readable but dead)
- Tight loop causing 100% CPU

### File Descriptor Accumulation

While Perl's garbage collection handles socket cleanup, the `IO::Select` object retained references to dead sockets, preventing cleanup and causing the selector to grow.

## Changes Made

### lib/Net/Clacks/Server.pm

#### 1. EOF Detection Fix (lines ~1175-1210)

**Before:**
```perl
if(!defined($bytes)) {
    $self->{clients}->{$cid}->{failcount}++;
    last;
}
```

**After:**
```perl
if(!defined($bytes)) {
    # undef = error, check if temporary (EAGAIN/EWOULDBLOCK) or permanent
    if(!$ERRNO{EAGAIN} && !$ERRNO{EWOULDBLOCK}) {
        # Permanent error - disconnect immediately
        push @{$self->{toremove}}, $cid;
    }
    last;
}
if($bytes == 0) {
    # EOF - peer closed connection, disconnect immediately
    push @{$self->{toremove}}, $cid;
    last;
}
```

#### 2. Safety Check for toremove (lines ~1171-1173)

Added check to skip clients already marked for removal:
```perl
next if(!defined($self->{clients}->{$cid}));
next if(contains($cid, $self->{toremove}));
```

#### 3. Reduced Failcount Threshold (line ~1222)

Changed from 6 to 3 for faster cleanup of problematic connections:
```perl
if($self->{clients}->{$cid}->{failcount} > 3) {
```

#### 4. EPIPE Handling in _clientOutput() (lines ~1265-1280)

Added explicit EPIPE detection for immediate cleanup:
```perl
if($ERRNO{EPIPE}) {
    print STDERR "Client $cid: connection closed by peer (EPIPE)\n";
    push @{$self->{toremove}}, $cid;
    next;
} elsif(!$ERRNO{EAGAIN} && !$ERRNO{EWOULDBLOCK}) {
    print STDERR "Write error for $cid: $ERRNO\n";
    push @{$self->{toremove}}, $cid;
    next;
}
```

### lib/Net/Clacks/Client.pm

#### 1. Selector Cleanup in reconnect() (lines ~131-140)

Clean up old selector before creating new connection:
```perl
sub reconnect($self) {
    # Clean up old selector before deleting socket
    if(defined($self->{selector}) && defined($self->{socket})) {
        eval {
            $self->{selector}->remove($self->{socket});
        };
    }
    if(defined($self->{socket})) {
        delete $self->{socket};
    }
    undef $self->{selector};
    # ... rest of reconnect logic
}
```

#### 2. Removed Dead Code (line ~290)

Removed unused `IO::Select->new()` call that created orphaned selector.

### lib/Net/Clacks/ClacksCache.pm

#### 1. Fixed DESTROY Syntax (line ~107)

Added missing `sub` keyword:
```perl
sub DESTROY($self) {  # was: DESTROY($self) {
```

## Test File Created

### t/05-disconnect.t

Author test (enabled with `TEST_DISCONNECT=1` or `TEST_AUTHOR=1`) that verifies:

1. **Server startup and basic connection** - Basic functionality works
2. **Clean disconnect via monitor** - Server sends DEBUG DISCONNECTED message
3. **Abrupt disconnect** - Server detects killed client quickly (~0.7s)
4. **Rapid connect/disconnect** - No FD leak after 20 cycles
5. **Multiple concurrent disconnects** - All clients cleaned up
6. **EPIPE handling** - Server survives write errors
7. **Client reconnect** - Old connection cleaned up

### t/test_server.xml

Test configuration using Unix domain socket for fast, reliable testing.

## Test Results

All 7 tests pass:
```
ok 1 - Server startup and basic connection
ok 2 - Clean disconnect - verify server cleanup via monitor
ok 3 - Abrupt disconnect - verify server cleanup
ok 4 - Rapid connect/disconnect - verify no FD leak
ok 5 - Multiple concurrent disconnects - verify all cleaned
ok 6 - EPIPE handling - verify cleanup on write error
ok 7 - Client reconnect - verify old resources cleaned
```

Key metrics:
- Abrupt disconnect detection: ~0.7 seconds
- FD growth after 20 rapid cycles: 0
- All DEBUG DISCONNECTED messages received by monitor

## Running the Tests

```bash
# Run disconnect tests only
TEST_DISCONNECT=1 perl -Ilib t/05-disconnect.t

# Run all tests including disconnect tests
TEST_DISCONNECT=1 make test

# Run with verbose output
TEST_DISCONNECT=1 TEST_VERBOSE=1 perl -Ilib t/05-disconnect.t
```

## Rollback Instructions

If issues are found, revert these files to their previous state:
- `lib/Net/Clacks/Server.pm`
- `lib/Net/Clacks/Client.pm`
- `lib/Net/Clacks/ClacksCache.pm`

The test files can be removed:
- `t/05-disconnect.t`
- `t/test_server.xml`

## Technical Notes

### Why SIGKILL in Tests

The test server runs in a forked child process. During `IO::Select->can_read()`, the process blocks in a system call and may not respond to SIGTERM immediately. The tests use SIGKILL for reliable cleanup.

### Monitor Mode for Verification

The tests use the server's monitor mode to verify cleanup. When a client disconnects, the server sends `DEBUG DISCONNECTED=<client_id>` to all clients with monitor mode enabled. This provides external verification that the server has actually cleaned up the client.

### Unix Domain Sockets

Tests use Unix domain sockets instead of TCP because:
- No SSL certificates required
- Faster connection/disconnection
- No port conflicts
- Easy cleanup (just delete socket file)
