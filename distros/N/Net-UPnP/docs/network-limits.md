# Network resource limits

The control point and gateway APIs bound work performed on behalf of an
untrusted device. These limits address the HTTP duration/buffering, repeated
SSDP, and mapping-enumeration findings in the 2026-10-23 security review.

## HTTP

`Net::UPnP::HTTP->new()` defaults to:

| Option | Default | Meaning |
| --- | --- | --- |
| `timeout` | 10 seconds | Total transaction budget, including name resolution, connect, writes and reads |
| `max_header_bytes` | 65536 | Combined status line, headers and chunk trailers |
| `max_line_bytes` | 8192 | Individual status, header, chunk-size and trailer line |
| `max_body_bytes` | 16777216 | Total decoded response body, including all chunks |

Pass positive finite values to the constructor to tune these limits; byte
limits must be integers. `deadline` is an optional absolute monotonic time
(from `Net::UPnP::HTTP::_now()`) that can shorten the transaction budget.

Socket I/O uses nonblocking operations and the remaining absolute deadline.
Hostname resolution runs in a short-lived child connected by a four-byte pipe,
so a blocking resolver cannot extend the request indefinitely. This requires a
Perl platform with `fork` and monotonic `Time::HiRes` support. Resolution failure
fails the request; there is no unbounded fallback. The caller's alarm is not
changed.

Content-Length, EOF-delimited and chunked responses are supported. Chunked
responses complete at the terminating chunk and bounded trailers, without
waiting for connection closure. Declared oversize lengths, incomplete bodies,
conflicting lengths and ambiguous transfer framing fail explicitly.

`post()` retains its false return value on transport failure. `geterror()`
returns the diagnostic for the most recent request. SOAP action/query wrappers
return an empty HTTP response with status code `0` on failure, allowing callers
to inspect the status without dereferencing an empty string. `postaction()` and
its `postcontrol()` alias accept an optional third hash reference of HTTP
options, used by gateway enumeration to pass its remaining deadline.

## Discovery

`search()` uses one total deadline of `mx * 2` seconds, including description
requests. Repeated packets do not reset it. It also accepts `max_packets`
(default 256) and `max_devices` (default 64), both positive integers. Description
URLs are deduplicated before fetching, including failed URLs. The bounded
packet budget also bounds the deduplication set and HTTP attempts.

The existing device-list return type is unchanged. Hitting a packet/device cap
returns the collected results and sets `geterror()` on the control point. An
ordinary end of the discovery window is not an error. `mx => 0` returns an
empty list immediately.

## Gateway mappings

`getportmappingentries(max_entries => 1024, timeout => 30)` has both an entry
cap and a total time budget. Each SOAP request receives the remaining overall
deadline. The deprecated `getportmappingentry()` alias and the invalid-count
fallback in `getportmappingnumberofentries()` use the same bounded path.

The method retains its list return type. A count/time limit returns collected
entries and sets the gateway's `geterror()` diagnostic; callers needing a
complete inventory must inspect it. A normal non-200 terminal response ends
enumeration without a limit error; transport failure has a diagnostic.

## Verification

`prove -l t/http-limits.t t/network-limits.t` exercises loopback-only fixtures
for normal response framing, stalls, slow trickles, byte limits, resolver
deadlines, caller alarms, safe SOAP failures, discovery floods/deduplication,
and gateway limits/aliases/fallbacks. No live UPnP device is needed.

On the pre-fix revision, the loopback control returned its two-byte body, a
65-byte EOF body was accepted despite a requested 64-byte limit, and a silent
peer required a separate test watchdog. The new regression suite rejects the
oversize/stalled cases while preserving the normal control and each supported
framing mode. `make test` passes 101 assertions across three test files on the
local macOS Perl runtime. Linux/Windows and real devices were not tested here.

The resource-limit change described here addresses four findings. The
subsequent destination-policy, example-traversal and RSS fixes are documented
in [device-and-media-safety.md](device-and-media-safety.md). The external
`Shell.pm` behavior remains unresolved.
