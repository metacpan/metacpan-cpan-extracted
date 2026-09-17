package Punk::Observe;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.10';

require XSLoader;
XSLoader::load('Punk::Observe', $VERSION);

1;

__END__

=head1 NAME

Punk::Observe - an OpenTelemetry observability and logging backend

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

In a Punk application, one plugin serves the whole thing - the receiver, the
screens, the live tail and the alert pages. The guard is not optional:

    plugin 'Observe' => {
        guard  => 'Web::Auth#observe_admin',
        store  => '/var/lib/punk-observe',
        ingest => { prefix => '/v1', keys => '/etc/punk-observe/keys' },
    };

The receiver is also a PSGI application on its own, so it mounts into a bare
C<plackup>, or into anything else that speaks PSGI:

    use Punk::Observe::Ingest;

    my $app = Punk::Observe::Ingest->new(
        auth     => sub { my ($env) = @_; resolve_tenant($env) },
        on_batch => sub {
            my ($tenant, $signal, $body, $encoding) = @_;
            append_to_wal($tenant, $signal, $body);
        },
    )->to_app;

Point any OpenTelemetry SDK at it on C</v1/traces>, C</v1/metrics> and
C</v1/logs>, and ask one language about all three:

    metric http.server.request.count
      | where service = "api" and http.route = "/checkout"
      | rate(5m) by http.response.status_code

=head1 DESCRIPTION

B<This is a backend, not a client.> It receives OTLP, stores it, queries it
and draws it. If you want to emit telemetry from a Perl application, that is
L<Punk::OpenTelemetry>.

Traces, metrics and logs arrive over OTLP - C<http/protobuf> or C<http/json> -
and land in a storage engine built for each signal's shape. One query language
spans all three, so a metric spike, the traces that caused it and the log lines
those traces emitted are reachable in a single expression rather than by
copying a trace id between three tabs.

gRPC is not offered, and L</WHAT IS NOT SUPPORTED> says why.

=head2 What is here

=over 4

=item * B<Ingest.> OTLP over C<http/protobuf> and C<http/json>, gzip and
deflate bodies, partial success, and a tenant resolver.
L<Punk::Observe::Ingest>.

=item * B<Storage> for all three signals: a write-ahead log, immutable
segments with content-derived series ids, compressed metric chunks, deflated
log blocks with a trigram filter, and spans assembled at read time.
L<Punk::Observe::Store>.

=item * B<The query language>, its planner, its resumable executor and the
pruning that decides what never has to be read at all.
L<Punk::Observe::Query>, L<Punk::Observe::Exec> and L<Punk::Observe::Scan>.

=item * B<Retention>: compaction, two rollup tiers, and deletion by whole
block. L<Punk::Observe::Retain>.

=item * B<The screens>: status, logs, metrics, traces, the service map,
explore, dashboards and alerts. The waterfall, the flamegraph and the service
map are laid out in C and arrive complete in the HTML; the charts are drawn in
the browser from a figure computed here. L<Punk::Observe::View>,
L<Punk::Observe::Plot>, L<Punk::Observe::SVG>, L<Punk::Observe::Map>,
L<Punk::Observe::Flame>.

=item * B<The live tail>, over server-sent events, across a worker pool.
L<Punk::Observe::Live>.

=item * B<Dashboards and alerting>: panels validated by the parser that will
run them, per-series rule state, grouped notification and an SSRF-checked
webhook target. L<Punk::Observe::Dashboard>, L<Punk::Observe::Alert>,
L<Punk::Observe::Route>, L<Punk::Observe::Target>.

=item * B<The mount>: a guarded UI scope, key-authenticated ingest, the three
limits and the tenant seam. L<Punk::Plugin::Observe>, L<Punk::Observe::Key>,
L<Punk::Observe::Limit>, L<Punk::Observe::Tenant>.

=back

=head2 What is not here

There is no packaged server binary. What ships is the engine, the receiver and
the plugin, assembled by the host application.

One thing comes from the host rather than from this distribution: the queue.
Alert evaluation and delivery run as jobs the plugin registers on the host's
L<Punk::Queue> - see L</ALERTING> - so a queue worker has to exist, which any
queue-using Punk application already has. Rules and dashboards live in the
configuration database the plugin migrates; F<sqitch/> is the schema.

Exponential histograms and summaries are decoded past rather than stored. See
L</WHAT IS NOT SUPPORTED>.

=head1 THE RECORD

A span is a record with a duration and a trace id. A log line is a record with
a body and a severity. A metric point is a record with a value. The three
storage layouts differ in how they lay records out, not in what a record is,
which is what makes one C<where> and one C<by> work across all three, and what
makes the cross-signal stages expressible at all.

=head1 TIMESTAMPS

Event times are unix nanoseconds. For any date in this decade that is around
1.8e18, which does not fit the 32-bit IV that several supported perls have,
and does not survive an NV intact on any of them.

So a timestamp crosses into Perl as an integer where that is lossless and as a
decimal string where it is not. Both compare and sort correctly; neither loses
a digit. Code reading these values should treat them as strings unless it has
checked C<$Config{uvsize}>.

Durations are measured on a monotonic clock. The wall clock is read once, for
the timestamp itself, because it steps - NTP corrects it, an operator sets it,
a virtual machine resumes with a stale one - and an interval measured across a
step is not merely inaccurate, it is a very large positive number.

=head1 DURABILITY

Ingested telemetry is appended to a write-ahead log before the request is
answered. What a C<200> B<means> depends on the C<fsync> policy, so the policy
is stated here rather than left to be inferred.

=over 4

=item C<always>

The log is flushed to stable storage before the response is sent. A C<200>
survives a power cut. The cost is one flush per batch, which on a
network-attached volume is one to two milliseconds.

=item C<interval> (the default, 200ms)

The write reaches the operating system before the response is sent, and is
flushed on a timer. A C<200> survives a process crash - a C<kill -9> loses
nothing, because the data is already in the page cache. B<A power cut or a
kernel panic can lose up to the interval.>

=item C<never>

The operating system decides when to flush.

=back

The default is C<interval>, and the reason is what the data is rather than a
general claim about safety. Losing 200 milliseconds of telemetry to a power
cut is an acceptable trade; losing 200 milliseconds of a job queue is not,
which is why L<Punk::Queue> makes the opposite choice. An installation that
disagrees should set C<always> and expect to pay for it.

=head2 Recovery

A log that is being appended to is supposed to have a ragged end, and a crash
guarantees one. On restart, replay reads frames until one fails its magic, its
bounds or its checksum, then stops and reports how many bytes it could not
read. B<That is a success, not an error.>

Refusing to start because the last frame is torn would turn "the final few
milliseconds did not make it" into "the service will not come up" - the data
was already lost, and the outage would be added on top. The count of truncated
bytes is logged once at startup and exported as a metric, because a log that
truncates on every restart means the durability policy is wrong and somebody
should be able to see that.

A frame whose checksum fails stops replay B<at that frame> rather than being
skipped. A bad checksum means the bytes are not what was written, so the
length that would locate the following frame came from the same untrusted
bytes and cannot be relied on either.

=head1 METRIC COMPRESSION

Metric points are stored with delta-of-delta timestamps and XOR-encoded
values. The numbers below were measured on 120-point chunks at a 15-second
interval, and the corpus is named for each because a compression figure
without its corpus is marketing.

    constant gauge                 0.45 bytes per point
    integer-valued gauge           1.09
    steady monotonic counter       1.83
    as_int series                  3.26
    accumulating float drift       5.46

Raw storage is 16 bytes per point, so the worst case here is a threefold
improvement and the common ones are far better.

B<The technique rewards values whose meaningful bits sit high.> That is where
a double keeps its exponent, so a gauge holding whole numbers or repeating
values compresses very well. Two consequences are worth knowing before
reading a chart of your own data:

=over 4

=item * An arbitrary decimal fraction is the weak case. C<40.1> and C<40.2>
as IEEE doubles share almost no mantissa, so a value reported to one decimal
place compresses worse than one reported as a whole number.

=item * An C<as_int> series is currently the weakest case, not the strongest.
A small integer keeps its meaningful bits at the bottom, which is the
opposite of what XOR encoding exploits. Integer chunks want delta-of-delta
encoding, the same technique the timestamps already use; that is a known
improvement and is not yet implemented.

=back

Values are stored as bit patterns throughout, so C<NaN> payloads, both
infinities, negative zero and integers above 2^53 all survive exactly.

=head2 A histogram becomes ordinary series

A histogram point is a count, a sum and a bucket array, so it is not one
value and cannot be one record. It is exploded into series the store already
knows how to keep: C<< <name>_bucket >> labelled by C<le>, plus C<_sum>,
C<_count>, C<_min> and C<_max>.

That is the Prometheus convention, chosen for a structural reason rather than
familiarity. Every one of those is a plain timestamp-and-value series, so
histograms need no new chunk format, no new index and no new merge rule, and
they get content-derived ids, compression, the postings index and the rollup
tier for free. It is also what makes an exact long-range percentile possible:
see L</Downsampling>.

B<The cost is that N buckets is N series.> Fifty buckets across ten routes is
five hundred, which is what the cardinality cap exists to bound - and the cap
counts them, so it is visible rather than discovered.

=head1 RETENTION

Data is deleted by whole B<block> - two hours - and never by record. Deleting
one line would mean rewriting a compressed block, which would make a segment
mutable and remove the property every reader depends on.

=head2 Deletion cannot break a reader

The deletion primitive is C<unlink(2)>, never C<ftruncate(2)>.

A reader holding a memory map of an B<unlinked> file keeps reading it
correctly: the name is gone, the data lives until the last mapping drops. A
reader holding a map of a B<truncated> file takes C<SIGBUS> on the next touch
- not an error return, a signal, killing the worker mid-request for every
connection it was holding.

So there is no C<ftruncate> anywhere on a segment path, and the test suite
fails if one appears.

=head2 A deleted file that is still mapped is still on the disk

A large segment unlinked an hour ago occupies its space until the last worker
drops its mapping, so the space a retention policy promises and the space the
filesystem reports can differ with no visible explanation. That figure is
counted and shown, because a number nobody can see is a number nobody can act
on.

=head2 Downsampling

Two tiers, at five minutes and one hour, each point carrying
C<{count, sum, min, max, last}>. That set is closed under merging, so an
hourly point is built from twelve five-minute points without returning to the
raw data.

It answers C<count>, C<sum>, C<avg>, C<min>, C<max> and C<rate> exactly.

B<It cannot answer a percentile, and it refuses to.> There is no function of
those five numbers that yields a p95, and every approximation that looks close
is wrong in the tail - which is the only part of a latency chart anybody
reads. Asking for one over a downsampled range returns an error suggesting a
shorter range or a histogram instrument, rather than a plausible wrong number.

Where the series is a histogram the percentile merges exactly from the bucket
counts, and the rollup keeps them. That is the supported path for a long-range
percentile.

Counter resets are recorded into the rollup, because the raw points that would
reveal one are dropped afterwards.

=head1 QUERIES

A query is parsed, planned, and then executed in B<steps>.

=head2 It yields

A worker holds hundreds of connections. A query that scans two gigabytes
synchronously stalls every one of them, and what the operator sees is that
the service froze because somebody opened a dashboard.

So the executor is a resumable state machine rather than a function: it
processes a bounded number of rows and returns, and the caller drives it from
a timer so the event loop runs in between. Yielding is invisible in the
answer - the same query over the same data gives the same result whatever the
step budget.

=head2 It refuses

Estimating a query's cost and B<refusing> it is the fourth thing the planner
does, and a refusal carries what to add rather than what went wrong:

    this query would scan too much - try narrowing the time range, as in
    | where t > ...

A refused query with an actionable message is a better product than a
thirty-second one, and far better than a timeout.

Two things are refused rather than approximated. A pattern needing a full
regular expression engine - C<=~> supports an anchored prefix, an anchored
suffix and a plain substring - and a column belonging to another signal,
which is a parse error naming it rather than an empty result.

=head2 It reads as little as it can

Before anything is mapped or decompressed, the plan's predicates are turned
into the question "can this segment, this chunk, this block possibly hold a
matching row".

A segment answers from its footer's time span, so a query outside it costs
32 bytes rather than a mapping. A metric chunk carries its own first and last
timestamp. A log block is checked in increasing cost order - its stream, then
its time range, then its trigram filter - and every one of those is decided
before the block is inflated. A filter consulted after decompressing the
block has cost more than it saved.

The counts survive into the result as C<blocks> and C<blocks_skipped>, so
what a query avoided reading is visible rather than assumed.

B<Every one of those tests is conservative, and the asymmetry is why.>
Skipping a block that could have matched loses data silently and the answer
still looks complete; reading a block that turns out not to match costs time
and nothing else. So a predicate shape the pruner does not understand narrows
nothing at all.

In particular B<an C<or> narrows nothing>. C<t E<gt> noon or service = "api">
still admits every row outside the time range, and taking either arm as a
bound would drop rows the query asked for. Only a conjunction narrows.

The same rule sets the floor on search: a term shorter than three characters
yields no trigram, so it prunes nothing and reads every block. Answering "no
match" from a filter that cannot see the term is the one failure mode that
loses log lines.

=head2 The result is honest

Every result carries how many rows it scanned, whether a budget cut it short,
and whether a percentile is exact or estimated.

B<A truncated result that looks complete is the observability equivalent of a
green dashboard over dropped spans> - which is the failure this whole project
exists to stop. A partial answer is the correct prefix of the real one, and it
says so.

=head2 Absent is not zero

A comparison against a field the row does not have is B<false>, in both
directions. C<duration > 0> does not match a row with no duration, and
C<duration != 0> does not either. Treating absent as zero would silently widen
every numeric filter.

=head1 TRACES

B<A trace is never complete, so nothing waits for one.>

The spans of a single trace arrive from many processes, in many batches, out
of order, across a window bounded only by the longest span. A backend that
assembles traces when they are written has to buffer them, decide when a
trace is finished, and be wrong.

So spans are stored individually and a trace is assembled when it is read.
Ingest never buffers, a span arriving an hour late still joins its trace, and
there is no trace timeout for anyone to misconfigure.

Two consequences follow that are worth knowing:

=over 4

=item * B<Rootness is decided after assembly, not per span.> A span with no
parent identifier is not necessarily a root - its parent may simply be in
another segment. Deciding at write time makes every trace appear to have
several roots.

=item * B<A span whose named parent is absent is counted, not hidden.> That
count is how an incomplete trace is distinguished from a genuinely shallow
one.

=back

Broken instrumentation can produce a cycle in the parent chain. Assembly is
depth-bounded and reports cycles rather than recursing on them.

=head2 Finding traces

Looking up a trace by identifier is a hash probe - measured at 1.53 probes per
lookup over a thousand traces - and does not get slower as the tenant grows.
The slot stores the full sixteen bytes of the identifier, because a
sixty-four-bit comparison would eventually merge two unrelated traces into one
waterfall, which is the most confusing thing this system could do.

Searching by duration is a binary search into an ordinal array sorted by
duration, so "slower than 500ms" is a contiguous range rather than a filtered
scan.

Before any of that, a segment is skipped entirely if its footer says it cannot
match: outside the time range, no trace slower than the threshold, or no error
span at all when the query wants errors.

=head2 The service graph

Edges are accumulated when a segment is sealed, not computed per query, so the
service map does not scan every span on every page load. The table is
services-squared rather than span-sized: six hundred spans across four
services produce four edges.

A span whose parent belongs to a different service is an edge. A call within
one service is not - counting it would make every service a self-loop. A span
whose caller is absent gets an edge from a synthetic root, because traffic
arriving from something uninstrumented is a finding rather than a gap to hide.

=head1 LOG STORAGE

Log lines are grouped into streams by their label set and stored in
raw-deflated blocks of up to a megabyte. A block is the unit of
decompression, which is what sets its size: smaller means more directory and
worse ratios, larger means a query for one minute inflates ten.

On realistic log text - 3,000 lines of structured request logs - a block
compressed 27 times, to 3.7 bytes per line.

=head2 Searching

A search never decompresses every block the label filter leaves. Three tests
run in increasing cost order, and only a block surviving all three is opened:

=over 4

=item 1. the stream, an integer comparison

=item 2. the time span, from the block directory, B<without inflating it>

=item 3. a per-block trigram bloom filter

=back

The filter stores no text. It answers only "can this block possibly contain
that substring", and a block that survives it is decompressed and matched
B<exactly>. So a false positive costs one wasted decompression and never a
wrong answer, while a false negative would lose a log line silently. There is
no acceptable rate of the second, so the filter is sized from each block's
measured distinct-trigram count rather than a fixed guess, and the test suite
asserts zero false negatives over 175,837 trigrams actually present across 200
blocks.

False positives depend on the length of the term, and both corpora are given
because quoting only the flattering one would be marketing. Absent
twelve-character terms: none in 2,000. Absent three-character terms: 2 in 495.
A short term carries fewer trigrams for a block to disagree on, so it prunes
less well, and the cost of that is a wasted decompression rather than a wrong
answer.

B<A search shorter than three characters cannot use the filter at all>,
because it has no trigrams. Such a search falls through to scanning every
block in range rather than silently matching nothing.

Matching is case-insensitive, folded identically when the block is written and
when it is searched.

=head2 What becomes a label

Only a configured allowlist of attributes becomes part of a stream's label
set. By default: C<service.name>, C<severity>, C<host.name> and
C<deployment.environment>.

Everything else stays in the record, searchable but not indexed. B<This limit
is what keeps the store alive.> A stream is a label set, so a label set
containing a request id is one stream per request - the same cardinality
explosion that kills a metric store, wearing different clothes. One customer
sending C<user_id> as a resource attribute would otherwise take the store
down.

C<trace_id> and C<span_id> are stored as first-class columns rather than as
text, which is what makes correlating a trace to its log lines a lookup
instead of a search for a hex string.

=head1 COUNTER RESETS

A cumulative monotonic counter that goes backwards means the process
restarted. That is detected when the point is B<written>, not when it is
queried, and the chunk carries a flag saying so.

The reason is retention: rollups outlive the raw points. A rate computed over
a rolled-up range containing an undetected reset is simply wrong, with nothing
left in the data to reveal it.

A gauge falling is not a reset, and is not treated as one.

=head1 CARDINALITY

A series is its label set, so the number of distinct label sets is the number
of things the store must keep track of. One attribute carrying a request
identifier turns a thousand series into a million, and the store that admitted
them is no longer serving anybody.

So distinct series are admitted through a cap, and the cap is the B<process
group's> rather than each worker's: the counter lives in an arena shared
across forked workers. Eight workers each enforcing a limit of 100,000
separately would admit 800,000, which is a cap in name only.

=head2 What happens at the cap

A series over the cap is B<refused>, and its points are folded into an overflow
series that is present in the data and says what it is. The counts are
readable through L<Punk::Observe::Segment/shm_stats>.

Refusing is the deliberate half. Dropping the points silently would make a
chart that is quietly missing a fifth of its traffic, which reads as a service
getting quieter rather than as a limit being hit. An overflow series that says
"you exceeded the cap" is a finding an operator can act on.

The other half is that the cap must actually be shared. C<shm_stats> reports
C<shared>, and where it is false the arena could not be mapped across workers
and the cap is not being enforced. That is surfaced rather than assumed,
because an operator finding the cap did not hold with no explanation available
is the worst version of this failure.

Log streams are capped by a different mechanism, the label allowlist. See
L</What becomes a label>.

=head1 WHAT IS NOT SUPPORTED

Each of these is a decision rather than a gap, so the question is answered
once.

=over 4

=item B<gRPC ingest.>

A gRPC call returns HTTP 200 even when it fails; the outcome lives entirely in
the C<grpc-status> and C<grpc-message> HTTP/2 trailers. PSGI has no trailer
channel, and Hyperman's HTTP/2 path has none either. An endpoint serving gRPC
without them would answer C<200> with no status, which an exporter reads as
complete success while every batch is discarded.

So it is refused at configuration time, with the reason, rather than served
badly. Use the OTLP/HTTP endpoints. See L<Punk::Observe::Ingest/GRPC>.

=item B<Clustering.>

One store, on one machine's disks. There is no sharding, no replication and no
consensus.

A distributed store is not a feature added to this one later; it is a different
system with a different failure model, and the honest version of that is a
different distribution. A single node with fast local disks holds far more
telemetry than most installations produce, and an operator who has outgrown it
knows more about their shape than a default could.

=item B<Tail sampling at the backend.>

Deciding which traces to keep after seeing all of their spans requires
buffering every trace until it is complete, which requires deciding when a
trace is complete. B<A trace is never complete> - see L</TRACES> - so that
decision is always a guess, and the traces it guesses wrong about are the slow
ones, which are the ones worth keeping.

Sample at the client, where the decision is cheap and the head is available.
L<Punk::OpenTelemetry> does this.

=item B<PromQL.>

The query language here spans three signals; PromQL spans one. Accepting a
subset of PromQL would mean every query that works elsewhere and not here is a
bug report, and the cross-signal stages - which are the reason this exists -
have nowhere to live in its grammar.

See L<Punk::Observe::Query>.

=item B<Deleting a single record.>

Retention granularity is a block, two hours. Removing one line means rewriting
a compressed block, which makes a segment mutable and removes the property
every reader depends on. See L</RETENTION>.

=item B<Percentiles over downsampled ranges.>

Refused rather than approximated. See L</Downsampling>.

=item B<Exponential histograms and summaries.>

Skipped rather than half-decoded. An exponential histogram's bounds are
base-2 rather than explicit, so they have to be computed from a scale before
they can become C<le> labels; a summary carries pre-computed quantiles, which
cannot be merged across points at all and are therefore a different storage
question rather than the same one.

Explicit-bucket histograms are stored - see L</A histogram becomes ordinary
series>.

=back

=head1 TENANCY

Every path this distribution constructs is rooted at the store root, and a
multi-tenant deployment sets that root to a per-tenant directory. There is no
tenant column in a segment and no tenant predicate in a query.

That is a security decision rather than a layout preference. A tenant column
means every query must remember to filter on it and the one that forgets
serves another customer's telemetry; a directory means a query for one tenant
has no file handle that reaches another's data.

A tenant identifier is C<[A-Za-z0-9_-]{1,64}> and is validated before any path
is built.

=head1 THE SCREENS

Every waterfall, flamegraph and service map is laid out in C at request time
and arrives complete in the HTML.

That is not an optimisation. A trace waterfall that exists only after a
script runs is a trace waterfall that does not exist in a saved page, in a
text browser, behind a strict content security policy, or in an email to a
colleague. JavaScript makes the waterfall B<navigable> - pan, zoom, hover -
by rewriting two custom properties rather than four thousand DOM nodes. It
does not make it exist.

=head2 The charts are drawn in the browser

A chart is the exception, and it is a deliberate one. A line over a hundred
thousand points with a legend, a shared crosshair and drag-to-zoom is a
different problem from a waterfall of forty bars, and the honest answer is
that it is worth a plotting library.

So a chart arrives as a figure - a block of JSON the page carries - and is
drawn by L<https://plotly.com/javascript/|Plotly>, which is B<served from the
mount> rather than from a content delivery network. An observability console
that phones out to a third party on every page load is one that fails on the
air-gapped network it was installed to watch, and it is one that tells that
third party which services an operator was looking at.

The figure is data rather than code: it lands in a
C<< <script type="application/json"> >>, which a browser parses and does not
execute. It carries service names and log bodies, which are attacker-influenced
in exactly the way a request path is.

B<Colour is named by role.> A figure carries C<series:2> and C<sev:error>,
resolved in the browser against the stylesheet's custom properties at the
moment of drawing. The server does not know which theme the reader is in, and
cannot know they are about to change it - and the categorical ramp was
measured for perceptual distance under two simulated colour vision
deficiencies, which the library's own defaults were not.

A page that has no figure does not load the library at all. See
L<Punk::Observe::Plot>.

=head2 The time range is a calendar, and a row of buttons underneath it

Every screen that reads a window carries the same control, and it is rendered
twice over. What the server sends is a row of preset buttons - C<15m>, C<1h>,
up to C<all> - each of them a submit button naming its own range. That row
works with JavaScript off, on a browser too old for the picker, and in the
seconds before the picker loads.

When the picker does load it replaces that row with a calendar and a time of
day at each end. The presets are still there, as its menu, read off the
buttons the server drew rather than repeated in JavaScript: the list lives in
C and there is one copy of it.

Which of the two forms a submit carries is the distinction worth stating.
B<A preset submits its key>, not the two instants it happened to resolve to.
Freezing C<15m> into a pair of timestamps would make "the last 15 minutes"
stop meaning the last fifteen minutes fifteen minutes later. A window picked
off the calendar has no key, so it submits C<from> and C<to> as nanosecond
decimal strings, which is also what a dragged selection on a chart writes.

Both forms travel in hidden fields inside the filter form rather than in the
query string alone, so submitting any other control on the page - a search
box, a severity filter - keeps the window the reader chose.

moment.js and the picker are vendored beside plotly and for the same reason.
See L</THIRD-PARTY ASSETS>.

=head2 Coordinates are formatted by hand

No coordinate anywhere is produced by a float format specifier. C<%f> in a
Perl-flavoured formatter reads an NV, and the C runtime on Windows prints
three-digit exponents, either of which puts something like C<1e-005> into a
path attribute. That is not a valid path, so the chart silently does not
draw, on one platform, with no error.

Values are clamped, rounded to two decimals and their digits emitted
directly. A NaN or an infinity becomes a number rather than the text C<nan>,
because one bad coordinate must cost one point and never the whole path.

=head2 SVG attribute context is not HTML context

A span name and a log body are untrusted input, and the template engine
escapes for HTML. A name containing a quote inside an SVG attribute ends the
attribute early and everything after it becomes markup, so text bound for an
attribute is escaped for that context, control characters included.

=head2 Self time, not total

A flamegraph frame shows the time a span B<spent>, not the time it lasted. A
root that took five seconds because it waited on a database did not spend
five seconds.

Children that ran concurrently overlap, so subtracting each child's duration
in turn can exceed the parent and drive self time negative. The child
intervals are merged before subtracting, which is what keeps a frame inside
its parent.

=head2 A refusal is a message, not an empty panel

A percentile that cannot be computed from downsampled data renders as an
explanation of why. An empty chart reads as "no data", which is a different
answer and a wrong one.

The same rule covers a trace: one whose parent pointers form a loop, or whose
spans reference a parent that never arrived, says so rather than quietly
rendering a shorter tree.

=head1 FUNCTIONS

This module carries the record contract, the clock and the store root. The
signal engines are in the modules listed under L</SEE ALSO>.

=head2 The record

=over 4

=item C<rec_size()>

The size of one stored record, in bytes.

=item C<rec_declared_size()>

The size the format declares. It must equal C<rec_size>: where it does not, the
compiler has padded the structure and every segment written by this build is
laid out differently from every other.

=item C<rec_offsets()>

A flat list of member name and byte offset, for all sixteen members. A padding
surprise on an unusual ABI shows up here, naming the member, rather than as a
silently misread segment.

=back

=head2 64-bit values

An event time is a C<uint64_t> from the wire to the disk. See L</TIMESTAMPS>
for why, and for what it looks like from Perl.

=over 4

=item C<u64_roundtrip($v)>

Passes a value through a record's timestamp field and back out through the
documented representation. What comes back equals what went in, on every perl.

=item C<u64_to_string($v)>

The decimal string form, taken directly. On a 64-bit perl the ordinary path
never reaches it, so this is how that branch is exercised somewhere other than
the 32-bit smokers, which are the machines least able to report why it broke.

=item C<u64_is_string($v)>

Whether this perl returns that value as a string rather than as an integer.

=item C<uvsize()>

This perl's C<UV> size in bytes. Values above C<2**53> need the string form
wherever this is below 8.

=back

=head2 The clock

Durations are measured on a monotonic clock; the wall clock is read once, for
the timestamp. An interval measured across a wall-clock step is not merely
inaccurate, it is a very large positive number.

=over 4

=item C<now_ns()>

The current time in unix nanoseconds.

=item C<have_monotonic()>

Whether this build found a monotonic clock.

=item C<clock_freeze($t)>

Pins the clock at C<$t>. B<This is process-wide and stays in force until
C<clock_real> is called.> It exists so that a timer can be tested by stating
what time it is rather than by sleeping, which on a loaded machine is how a
test suite becomes intermittent.

=item C<clock_step($ns)>

Advances a frozen clock.

=item C<clock_real()>

Returns to the real clock.

=item C<block_start($t)>

The start of the two-hour block containing C<$t>. This is the retention
granularity: see L</RETENTION>.

=item C<duration($start, $end)>

The interval between two instants. An end before its start yields zero, not the
enormous positive number that subtracting them in a C<uint64_t> produces.

=back

=head2 The store root

=over 4

=item C<tenant_ok($id)>

Whether a tenant identifier is acceptable: C<[A-Za-z0-9_-]{1,64}>.

=item C<store_root($data_dir, $tenant)>

The root directory for a tenant, or undef if the identifier was refused.

=item C<store_join($data_dir, $tenant, $relative)>

A path inside that root, or undef if the identifier was refused or the result
would escape the root. A path for one tenant never resolves inside another's,
whether or not either directory exists.

=item C<arena_roundtrip($bytes)>

Puts bytes through the arena a record's variable-length fields are stored in
and reads them back.

=back

=head2 Build facts

=over 4

=item C<build_info()>

A flat list of name and value: C<clock_gettime>, C<clock_monotonic>,
C<atomics>, C<big_endian>. Each is 1 or 0.

These are what the build probed for, not what the platform claims. A POSIX
macro says an API exists, not that it links.

=back

=head1 THE LIVE TAIL

A browser tailing logs is connected to one worker. The lines it wants are
being ingested by all of them, so an ingesting worker publishes matching
records on a per-tenant topic and whichever worker holds the connection
forwards them.

Across a pool that is Hyperman's shared-memory bus. It is optional: the
self-hosted default is one worker, where a tail never leaves the process it
was ingested in, and a build that cannot find the bus header says so and
serves an in-process tail rather than failing.

=head2 A long line is truncated, not dropped

The bus refuses a message larger than its slot. It does not shorten one. So
publishing a long log line unchanged does not produce a short line, it
produces B<no line> - and the tail would silently skip exactly the
interesting ones: a stack trace, a serialised payload, the thing somebody is
tailing to find.

The record is therefore cut to fit deliberately, with a flag saying so, and
the row carries a marker and a link to the whole record. A truncation the
reader can see is a different thing from a line that never arrived.

=head2 Everything lost is counted

A slow consumer that gets lapped, a reconnection whose last event id has
scrolled out of the buffer, and a client that stopped reading are each
reported with a number rather than papered over.

A silently short stream is indistinguishable from a quiet one. That is the
whole argument: a gap with a figure beside it is a diagnosis, a gap without
one is a mystery.

A reconnection resumes from C<Last-Event-ID> where the buffer still holds it,
and says how many lines it missed where it does not.

=head2 It closes rather than queues

A browser that has stopped reading must not become an unbounded queue in the
server. Past a byte threshold the connection is closed with a reason, which
the client can act on, instead of a worker growing a buffer until something
unrelated fails.

The browser side is bounded too: at most two thousand rows live in the
document, dropping from the top, with the count of what scrolled off on
display. Appending is paused while the reader has scrolled up, because a list
that jumps while it is being read is unusable.

=head2 Behind a proxy

An SSE stream through a buffering reverse proxy delivers nothing until the
proxy has buffered enough to flush, which presents as "live tail does not
work" and is not this software.

For nginx, on the location that serves the stream:

    proxy_buffering off;
    proxy_cache off;
    proxy_read_timeout 3600s;
    proxy_set_header Connection '';
    proxy_http_version 1.1;

The response already sets C<X-Accel-Buffering: no> and C<Cache-Control:
no-cache>, which covers nginx in its default configuration; the settings
above are what an explicitly configured proxy needs. A heartbeat comment is
sent on an idle stream so an intermediary does not close it, and it carries
no event id - a heartbeat that advanced C<Last-Event-ID> would make a
reconnection resume past real rows.

=head1 ALERTING

A rule is an OQL string executed on the same path the dashboard uses. An
alert that can fire on a different answer than the graph shows is worse than
no alert, because it destroys trust in both.

    rule       an OQL query
    condition  an operator and a threshold
    for        how long the condition must hold
    every      how often to evaluate
    labels     matched by the routing rules

B<Nothing is configured outside the screen.> Rules are created, edited,
silenced and deleted on the alerts page, stored in the configuration
database; L<Punk::Observe::Evaluate> runs them as a cron the plugin registers
on the host's L<Punk::Queue> at registration - the host writes no loop, no
cron entry, no evaluator. Its one contribution is the C<on_alert> callback,
because delivery - webhook, email, pager - is the one thing the core cannot
know.

The cron's cadence B<is the resolution of every rule on the installation>;
each rule's own C<every> is honoured on top of it, inside the pass. The
first person who wants ten-second alerting needs to know why they cannot
have it, which is why it is said here rather than discovered.

Rules, dashboards, silences and the outbox are configuration rather than
telemetry, so they live in the configuration database the plugin migrates -
F<sqitch/> is the schema.

=head2 State is per series

A rule grouped C<by service> produces many series and each carries its own
state: C<ok>, C<pending>, C<firing>, C<stale> or C<error>. One state per rule
is the bug that makes an alert resolve because a B<different> service
recovered.

C<pending> back to C<ok> notifies nobody. That is the entire purpose of
C<for>, and C<for> is measured on the condition holding B<continuously> - a
breach that clears inside the window resets it.

=head2 A vanished series does not stay firing

A pod is deleted, its series stops being reported, and a naive implementation
leaves it red for ever. A permanently red dashboard is how alerting loses its
audience, and once it has, the real alert is not read either.

An absent series goes C<stale> and leaves C<firing> after two evaluation
intervals, with a resolution saying the series stopped existing rather than
that the condition cleared. Those are different events.

=head2 An evaluation error is not "ok"

A rule whose query fails goes to C<error> and notifies. It does not report
healthy.

This is the failure that costs somebody a weekend and the one most likely to
be written by accident, because the natural code path treats "no rows" and
"no answer" identically. The evaluation carries a status alongside its rows
and the two are never collapsed.

An error notifies once, not every tick. A successful evaluation re-arms it.

=head2 One deploy is one message

Notifications are grouped by a configured label set and held for
C<group_wait> before the first send, so one bad deploy sends one message
listing forty services rather than forty messages. A series arriving after
the group was sent opens a new group, so the forty-first is a second
notification rather than a lost one.

C<group_wait> delays the first notification. That is the intent, and the
interface says so, because latency on a page is something to know in advance
rather than discover during an incident.

Delivery is an outbox keyed on C<(rule, series, fired_at)>. A retried job
recomputes the same key and is refused, so a delivery cannot happen twice.
C<fired_at> is in the key rather than the time of the send: a series that
resolves and fires again is a new notification, not a duplicate.

=head2 A silence suppresses notification, not state

A silenced rule still reaches C<firing> and still renders red. It just does
not page. A silence that hid the state is how an incident is forgotten.

Silences expire, and an expired one stops suppressing immediately.

=head2 A webhook target is validated before it is fetched

A webhook URL is a request the server makes to an address a user supplied,
which is an SSRF. Loopback, link-local and the private ranges are refused by
default, along with any scheme that is not C<http> or C<https>, and an
operator who needs an internal target adds it to an allowlist explicitly.

See L<Punk::Observe::Target> for what that check does and does not claim.

=head1 THE CONSOLE WATCHES ITSELF

When the application this mounts into also carries L<Punk::OpenTelemetry>,
browsing the console writes telemetry into the store the console is showing.
That is B<deliberate, kept, and worth knowing about>: a console whose own
latency is invisible is a console that cannot explain why it is slow, and
during an incident "is it them or is it us" is a real question this answers.

Three consequences to be aware of. The numbers on the status page include the
reader looking at them. The service map has an edge that is the console. And
on a quiet system the observer can be the dominant workload - the store fills
with records about the act of looking at the store.

An installation that wants the separation has two clean cuts, in order of
preference:

=over 4

=item * B<A separate tenant.> Point the console's own exporter at the same
endpoint with a different ingest key, and resolve that key to its own tenant.
The console's telemetry stays inspectable - it is telemetry - without mixing
into what is being observed.

=item * B<Point the exporter elsewhere, or nowhere.> The console is an
ordinary OTLP client; its exporter goes wherever any exporter goes, including
off.

=back

What is not offered is a path-prefix exclusion inside the plugin. The mount
prefix is configuration, the OTLP path is not under it, and a filter keyed on
either would silently stop matching the day one of them moved.

=head1 MOUNTING IT

    plugin 'Observe' => {
        prefix => '/observe',
        guard  => 'Web::Auth#observe_admin',       # required
        store  => '/var/lib/punk-observe',
        ingest => { prefix => '/v1', keys => '/etc/punk-observe/keys' },
        limits => { series => 1_000_000, rate_records => 50_000 },
    };

Registration B<croaks without a guard>. An unguarded mount is every log line
the application has ever written, served to anybody who finds the prefix, and
a loud failure at boot beats a silent hole nobody notices.
C<PUNK_OBSERVE_INSECURE> is the deliberate escape.

The ingest prefix sits outside the UI scope in both directions: it is
authenticated by key rather than by the UI guard, because an exporter has no
session, and it is CSRF-exempt, because an exporter has no form token. Wrong
in one direction is a security hole; wrong in the other returns 403 to every
exporter in the world with a message about forms.

See L<Punk::Plugin::Observe> for the options.

=head2 Ingest keys

A bearer token in C<Authorization>, which is the channel
C<OTEL_EXPORTER_OTLP_HEADERS> already gives every OpenTelemetry SDK.

Keys are stored as hashes, never as tokens: the key file lives in F</etc>,
gets backed up, and ends up in a configuration-management repository. They
are compared in constant time, because a key compared with C<eq> leaks the
length of the matching prefix and is recovered one byte at a time.

An ingest key cannot read the UI, and there is no option to widen it.

=head1 LIMITS

Three of them, failing three different ways. Treating them as one limit is
the mistake, and all three matter on a single box: they are what stops one
misconfigured service taking down the machine whose job is to explain the
outage.

=head2 Ingest rate returns a partial success

Never a bare 429. A 429 makes the exporter re-send the whole batch, forever,
at the moment the server is already under pressure - the limit becomes an
amplifier. OTLP carries a rejected count for exactly this: accept what fits,
say how much did not.

The counter lives in an arena mapped before the fork, so the limit is per
pool. A per-worker window on a four-worker box is four times what was
configured, and the symptom looks like the limit not working rather than like
a fork bug.

Unconfigured, the rate limit is off. The limiter covers the ingest prefix and
nothing else: rate-limiting a health endpoint takes the box out of a load
balancer under exactly the load the limiter exists for.

=head2 Cardinality drops the new series

Never an eviction. Evicting an existing series to admit a new one converts a
cardinality problem into data loss on the exact series somebody has open in a
dashboard, which is the one they are watching because it matters. Admission
only ever increments, so that is structural rather than a rule to remember.

The cap gates B<metric> records only. A metric series carries ongoing state -
rollups, exemplar sidecars, compression streams - and that is the cost the
cap bounds. A log line or span with a unique attribute combination is bytes
in a sealed segment, paid once and aged out by retention: you can log any
data, a payment id per checkout included, without consuming a series slot.
What bounds log and span attributes is the indexed-label allowlist below -
unlisted attributes filter correctly and cost a scan, never a series.

This limit B<has> a default, because a store with no cardinality limit is a
store waiting for one bad deploy.

=head2 Storage shortens retention

Writes are never refused. A store over its byte budget should lose old data;
it must not lose the incident happening now, which is when it is most needed.

The newest block is always kept. A budget smaller than one block is a
misconfiguration, and answering it by deleting the incident in progress would
be the limiter doing more damage than the thing it limits.

=head2 The indexed-attribute allowlist matters more than the numbers

Logs and spans carry unbounded attributes. Only the configured set becomes an
index dimension; the rest stay in the record and are reachable by a residual
filter, so nothing is lost - it is just slower to find.

Without it, one service putting a request id in a resource attribute takes
the store down, and the store is right to refuse. The overflow counter
B<names the attribute>, because the person who hits this first is a
self-hoster with no support contract and no dashboard telling them which one
did it.

=head1 SEE ALSO

L<Punk::OpenTelemetry>, the client this exists to receive from.

Mounting it:

=over 4

=item * L<Punk::Plugin::Observe> - the plugin, its options and its guard

=item * L<Punk::Observe::Tenant> - the tenant seam

=item * L<Punk::Observe::Key> - ingest keys

=item * L<Punk::Observe::Limit> - the three limits

=back

Receiving and answering:

=over 4

=item * L<Punk::Observe::Ingest> - the OTLP receiver, as a PSGI application

=item * L<Punk::Observe::Query> - the query language

=item * L<Punk::Observe::Exec> - planning and running a query

=item * L<Punk::Observe::Scan> - what a query decides without reading

=back

Storage:

=over 4

=item * L<Punk::Observe::Decode> - OTLP protobuf, read as records

=item * L<Punk::Observe::WAL> - the write-ahead log

=item * L<Punk::Observe::Segment> - segments, series ids and the symbol table

=item * L<Punk::Observe::SegIO> - one segment carrying all three signals

=item * L<Punk::Observe::Metric> - compressed metric chunks

=item * L<Punk::Observe::Log> - log blocks and the trigram filter

=item * L<Punk::Observe::Trace> - spans, trace assembly and the service graph

=item * L<Punk::Observe::Retain> - compaction, rollups and deletion

=item * L<Punk::Observe::Store> - sealing, and the read path over what is
sealed

=item * L<Punk::Observe::Cache> - the settled part of a window, computed once

=item * L<Punk::Observe::Warm> - and computed where nobody is waiting

=back

Drawing:

=over 4

=item * L<Punk::Observe::View> - the screens, and what they are given

=item * L<Punk::Observe::SVG> - chart primitives

=item * L<Punk::Observe::Map> - laying out the service graph

=item * L<Punk::Observe::Flame> - aggregated self-time across traces

=item * L<Punk::Observe::Live> - the log tail

=back

Dashboards and alerting:

=over 4

=item * L<Punk::Observe::Dashboard> - a panel is an OQL string with a title

=item * L<Punk::Observe::Alert> - rule evaluation and its states

=item * L<Punk::Observe::Route> - grouping, silences and the outbox key

=item * L<Punk::Observe::Target> - where a webhook may point

=back

=head1 THIRD-PARTY ASSETS

The console serves a few files it did not write. They are vendored into
C<root/static/> rather than fetched from a CDN, because a console that phones
out to a third party on every page load is one that reports on an air-gapped
network by not working.

=over 4

=item * plotly.js - charts. MIT, Copyright (c) 2016-2026 Plotly, Inc.

=item * moment.js - date parsing and formatting for the range picker. MIT,
Copyright (c) JS Foundation and other contributors.

=item * vanilla-datetimerange-picker - the time range control. MIT, Copyright
(c) 2023 alumuko. A dependency-free port of Dan Grossman's bootstrap
daterangepicker, MIT, Copyright (c) 2012-2019 Dan Grossman.

=back

Each is served unmodified, and F<t/0090-assets.t> pins the exact build by
digest, so an upgrade is a deliberate act rather than a quiet edit.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
