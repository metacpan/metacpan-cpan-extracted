package Punk::Observe::Trace;

use 5.010;
use strict;
use warnings;

use Punk::Observe ();

our $VERSION = $Punk::Observe::VERSION;

1;

__END__

=head1 NAME

Punk::Observe::Trace - spans, trace assembly and the service graph

=head1 SYNOPSIS

    use Punk::Observe::Trace;

    my @spans = ({ trace_hi => 1, trace_lo => 2, span_id => 10,
                   start => 1_000, end => 501_000, service => 1 },
                 { trace_hi => 1, trace_lo => 2, span_id => 11, parent => 10,
                   start => 2_000, end => 400_000, service => 2 });

    my $a = Punk::Observe::Trace::analyse(\@spans);
    printf "%d traces, %d edges\n", $a->{traces}, scalar @{ $a->{edges} };

    my $s = Punk::Observe::Trace::slower_than(\@spans, 500_000_000);

=head1 DESCRIPTION

B<A trace is never complete, so nothing waits for one.>

The spans of a single trace arrive from many processes, in many batches, out of
order, across a window bounded only by the longest span. A backend that
assembles traces when they are written has to buffer them, decide when a trace
is finished, and be wrong.

So spans are stored individually and a trace is assembled when it is read.
Ingest never buffers, a span arriving an hour late still joins its trace, and
there is no trace timeout for anyone to misconfigure.

=head2 Rootness is decided after assembly

A span with no parent identifier is not necessarily a root - its parent may
simply be in another segment. Deciding at write time makes every trace appear
to have several roots. A span whose named parent is absent is counted as an
orphan rather than hidden, and that count is how an incomplete trace is
distinguished from a genuinely shallow one.

Broken instrumentation can produce a cycle in the parent chain. Assembly is
depth-bounded and reports cycles rather than recursing on them.

=head2 The service graph is accumulated at seal

Edges are computed when a segment is sealed, not per query, so the service map
does not scan every span on every page load. The table is services-squared
rather than span-sized: six hundred spans across four services produce four
edges.

A span whose parent belongs to a different service is an edge. A call within
one service is not - counting it would make every service a self-loop. A span
whose caller is absent gets an edge from a synthetic root, reported as C<*>,
because traffic arriving from something uninstrumented is a finding rather than
a gap to hide.

=head1 THE SPAN SPEC

Every function taking spans takes an arrayref of hashrefs:

    trace_hi   the trace id, high 8 bytes
    trace_lo   the trace id, low 8 bytes
    span_id    the span id
    parent     the parent span id, absent or 0 for none
    start      start time, unix nanoseconds
    end        end time, unix nanoseconds
    service    the service symbol number
    name       the span name symbol number
    status     the OTLP status code

Services and names are symbol numbers rather than strings, because a segment
stores them interned. See L<Punk::Observe::Segment/intern_strings>.

An end before its start is clamped to a zero duration and counted, never stored
as the enormous positive number that subtracting them in a C<uint64_t> would
produce.

=head1 FUNCTIONS

=head2 span_size

    my $bytes = Punk::Observe::Trace::span_size();

The size of one stored span, in bytes.

=head2 analyse

    my $out = Punk::Observe::Trace::analyse(\@spans);

Runs the whole pipeline in one call: add, seal (which sorts), index, summarise
and graph.

    {
      spans     => 600,   traces  => 100,
      slots     => 2048,  clamped => 0,
      any_error => 1,
      t_min     => ...,   t_max   => ...,   dur_max => ...,
      by_duration => [ ... ],
      edges       => [ ... ],
      tree        => [ ... ],
      roots       => 1,   cycles  => 0,     orphans => 0,
    }

C<by_duration> is one entry per trace, slowest first, each carrying
C<trace_hi>, C<trace_lo>, C<duration>, C<spans>, C<errors> and
C<root_service>.

C<edges> is the service graph: C<caller> (a service symbol, or C<*> for the
synthetic root), C<callee>, C<count>, C<errors> and C<dur_max>.

C<tree> is the assembled tree of the B<first> trace only, one entry per span
with C<span_id>, C<parent_index> (an index into C<tree>, or -1) and C<depth>.
C<roots>, C<cycles> and C<orphans> describe that tree.

C<parent_index> is B<not> C<parent> above, and the difference is why it is
spelled differently. The span spec takes a parent SPAN ID; this hands back a
position in a list. Both were called C<parent>, and passing one where the other
was expected made every root its own parent - a cycle, which assembly drops,
which is how the flamegraph lost the root span of every trace while the
waterfall beside it looked correct.

C<any_error> and C<dur_max> are the footer statistics a query prunes segments
on.

=head2 index_probe

    my $out = Punk::Observe::Trace::index_probe(\@spans, [ $hi, $lo, ... ]);

Builds the trace-id index, then looks up each (hi, lo) pair in the flat list.

    {
      found   => 1000,  missing => 100,
      counts  => [ 6, -1, 6 ],
      slots   => 2048,  distinct => 1000,
      probes  => 1530,  lookups  => 1000,
    }

C<counts> is positional: the number of spans for a trace that was found, or -1
for one that was not.

C<probes> over C<lookups> is the average probe count, and it is the assertion
that the table has not degenerated into a scan. Measured at 1.53 over a
thousand traces.

The slot stores the full sixteen bytes of the identifier. A sixty-four-bit
comparison would eventually merge two unrelated traces into one waterfall,
which is the most confusing thing this system could do.

=head2 slower_than

    my $out = Punk::Observe::Trace::slower_than(\@spans, $min_duration_ns);

Every trace at or above a duration, by binary search into the ordinal array
sorted by duration.

    { durations => [ ... ], from => 940, total => 1000 }

C<from> is the ordinal where the range starts, which is what makes this a
contiguous range rather than a filtered scan.

=head2 seg_may_match

    my $bool = Punk::Observe::Trace::seg_may_match(
        $t_min, $t_max, $dur_max, $any_error,
        $from, $to, $min_duration, $want_error);

Whether a segment can possibly answer a trace query, from its footer alone. The
first four arguments are the segment's statistics and the last four are the
query's. False means the segment is skipped without being opened: outside the
time range, holding no trace slower than the threshold, or holding no error
span when the query wants errors.

=head1 SEE ALSO

L<Punk::Observe>, L<Punk::Observe::Flame>, L<Punk::Observe::Map>,
L<Punk::Observe::SegIO>

=cut
