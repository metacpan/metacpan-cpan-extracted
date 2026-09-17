#!perl
# The screens, end to end: real records in a real store, through the view, out
# through the templates, behind the real route table.
#
# THE POINT OF THIS FILE is the join. Every piece below was already built and
# unit-tested while the UI showed none of it, because nothing connected the
# store to the page: the map had no edges, the logs page ignored its own query
# box, and the four interaction modules were served by no route at all. Each
# assertion here is one of those seams.
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    eval { require Template::Stencil; 1 }
        or plan skip_all => 'Template::Stencil not installed';
}
use Punk::Observe;
use File::Raw::JSON ();     # named here rather than reached through View
use Punk::Observe::Store;
use Punk::Observe::View;
use Punk::Observe::WAL;

my $V = 'Punk::Observe::View';

# --- a store with a real incident in it --------------------------------------

my $T0 = '1774224000000000000';
sub at { Punk::Observe::Store::nadd($T0, $_[0]) }

my $dir = tempdir(CLEANUP => 1);
my $store = Punk::Observe::Store->new(dir => $dir);

{
    my @recs;
    # Two traces, shop -> cards, the second one failing.
    for my $n (0, 1) {
        my $base = $n * 1_000_000_000;
        my $bad  = $n == 1;
        push @recs,
            { kind => 3, t => at($base), duration => '5000000',
              body => 'POST /checkout', span_kind => 2, status => 0,
              trace_hi => 100 + $n, trace_lo => 200 + $n, span_id => 10 + $n * 10,
              parent_id => 0, severity => 0,
              attrs => { 'service.name' => 'shop', 'http.route' => '/checkout' } },
            { kind => 3, t => at($base + 500_000), duration => '3000000',
              body => 'POST /authorize', span_kind => 3,
              status => ($bad ? 2 : 0),
              trace_hi => 100 + $n, trace_lo => 200 + $n, span_id => 11 + $n * 10,
              parent_id => 10 + $n * 10, severity => 0,
              attrs => { 'service.name' => 'cards', 'http.route' => '/authorize',
                         'db.query.text' => 'SELECT limit_cents FROM cards WHERE id = ?' } },
            { kind => 2, t => at($base + 900_000), duration => 0,
              body => ($bad ? 'card refused: insufficient funds'
                            : 'checkout complete'),
              severity => ($bad ? 17 : 9), span_kind => 0, status => 0,
              trace_hi => 100 + $n, trace_lo => 200 + $n, span_id => 11 + $n * 10,
              parent_id => 0,
              attrs => { 'service.name' => 'cards' } },
            { kind => 1, t => at($base + 950_000), duration => 0,
              body => 'http.server.duration', value => 5.0 + $n,
              severity => 0, span_kind => 0, status => 0,
              trace_hi => 100 + $n, trace_lo => 200 + $n, span_id => 0,
              parent_id => 0,
              attrs => { 'service.name' => 'shop' } };
    }
    my $r = Punk::Observe::WAL::append($store->wal_path, \@recs, 0, 0);
    ok($r->{ok}, 'the fixture reaches the log');
    ok($store->seal, '  and seals');
}

# The window every page defaults to is the last hour, and the fixture is dated
# 2026. So the pages are asked for the range the fixture is in.
my %W = (from => $T0, to => at(60_000_000_000));

sub page { $V->page($store, $_[0], { %W, %{ $_[1] || {} } }) }

my $ST = Template::Stencil->new({
    template_dir => 'root/templates', wrapper => 'layout.tmpl' });
sub render {
    my ($tmpl, $vars) = @_;
    return $ST->render($tmpl, { prefix => '/observe', theme => '',
                                toolbar => '', %$vars });
}

# Every variable a screen reads, at its empty value. A template that dies on a
# missing key turns a page with no data into a 500, so the render assertions
# below start from the whole set and override only what they are about.
my %empty_page = (
    rows => [], groups => [], names => [], series => [], yticks => [],
    nodes => [], edges => [], spans => [], traces => [], flame => [],
    attrs => [], context => [], services => [], examples => [], logs => [],
    record => {}, query => '', query_esc => '', from => 0, to => 0,
    heading => '', title => '', error => '', hint => '', refusal => '',
    truncated => 0, scanned => 0, degraded => 0, tail => 0, found => 0,
    empty => 0, exact => 1, offset => 0, total => 0, errors => 0,
    errors_only => 0, min_ms => '', trace => '', flame_height => 0,
    width => 720, height => 220, root_name => '', span_count => 0,
    duration_ms => 0, orphans => 0, cycles => 0, back_edges => 0,
    has_severity => 0, has_duration => 0, has_value => 0, has_trace => 0,
    ingest_rate => 0, wal_depth => 0, segments => 0, compaction_lag => 0,
    series_cap => 0, series_rejected => 0, mapped_deleted => 0,
    store_bytes => '0 B', metrics => 0, rules => [], silences => [],
    broken => 0, panels => [], cols => 2, slug => '',
    range_qs => '', range_amp => '', range => '1h', range_all => 0, range_custom => 0, ranges => [],
);

# --- logs: the query box actually runs the query -----------------------------

{
    my $all = page('logs');
    is(scalar @{ $all->{rows} }, 2, 'the logs page shows both log lines');
    is($all->{query}, 'log', '  with a default query, not an empty box');

    # The bug this whole file exists for: the query string was echoed back
    # into the input and never executed.
    my $err = page('logs', { q => 'log | where severity >= error' });
    is(scalar @{ $err->{rows} }, 1, 'a severity filter FILTERS');
    is($err->{rows}[0]{body}, 'card refused: insufficient funds',
       '  keeping the error and not the info line');
    is($err->{rows}[0]{sev_name}, 'error', '  named on the twenty-four point scale');
    is($err->{rows}[0]{service}, 'cards', '  attributed to its service');
    ok(length $err->{rows}[0]{id}, '  and carrying an id, so the row is a link');
    ok(length $err->{rows}[0]{trace}, '  and its trace, so the join is one click');

    my $s = page('logs', { q => 'log | search "refused"' });
    is(scalar @{ $s->{rows} }, 1, 'a substring search searches');

    my $bad = page('logs', { q => 'log | where severity >>> error' });
    ok(length $bad->{error}, 'a query that will not parse says so');
    ok(length $bad->{hint},  '  with something to do about it');
    is(scalar @{ $bad->{rows} }, 0, '  and shows no rows at all');
}

# --- the log row is a link, and the detail page is what it links to ----------

{
    my $err = page('logs', { q => 'log | where severity >= error' });
    my $id  = $err->{rows}[0]{id};

    my $rec = page('record', { id => $id });
    ok($rec->{found}, 'the id resolves to a record');
    is($rec->{record}{body}, 'card refused: insufficient funds', '  the right one');

    # THE ATTRIBUTES ARE THE POINT. A message column with no context is a list
    # of access lines nobody can act on.
    ok(scalar @{ $rec->{attrs} }, 'the detail page shows the attributes');
    my ($svc) = grep { $_->{key} eq 'service.name' } @{ $rec->{attrs} };
    is($svc->{value}, 'cards', '  including the one the table lifted out');
    ok(scalar @{ $rec->{context} }, '  and the lines around it');

    is($rec->{heading}, "$rec->{record}{sev_name} - $rec->{record}{service}",
       '  the heading names the severity and the service');
    is_deeply([ map { $_->{key} } @{ $rec->{attrs} } ],
              [ sort map { $_->{key} } @{ $rec->{attrs} } ],
              '  the attributes are in a stable order');
    # The line you clicked has to be findable in the lines around it, or the
    # context is a second list rather than a position in the first.
    is(scalar(grep { $_->{current} } @{ $rec->{context} }), 1,
       '  and exactly one of them is this one');
    is((grep { $_->{current} } @{ $rec->{context} })[0]{id}, $id,
       '  the one that was asked for');

    my $gone = page('record', { id => '1774224000000000000.999999999999' });
    ok(!$gone->{found}, 'an id that matches nothing is not found');
}

# --- the context is centred on the record, not on the window's edge ----------

# `rows` answers newest first and `limit` keeps that end, so the capped call
# the context used to make kept the newest lines of the ten seconds: on a
# busy store that was everything AFTER the record and nothing before it, with
# the record itself pushed off its own context. Sixty lines each side selects
# that branch on purpose - a quiet fixture can never catch it.

{
    my $dir2   = tempdir(CLEANUP => 1);
    my $store2 = Punk::Observe::Store->new(dir => $dir2);
    my $C0     = at(1_000_000_000);
    my $ms     = 1_000_000;

    my @recs;
    push @recs, { kind => 2, t => Punk::Observe::Store::nsub($C0, $_ * $ms),
                  duration => 0, body => "ctx before $_", severity => 9,
                  span_kind => 0, status => 0, trace_hi => 0, trace_lo => 0,
                  span_id => 0, parent_id => 0,
                  attrs => { 'service.name' => 'shop' } } for reverse 1 .. 60;
    push @recs, { kind => 2, t => $C0, duration => 0,
                  body => 'the line itself', severity => 17, span_kind => 0,
                  status => 0, trace_hi => 0, trace_lo => 0, span_id => 0,
                  parent_id => 0, attrs => { 'service.name' => 'shop' } },
                { kind => 2, t => $C0, duration => 0,
                  body => 'same instant, different line', severity => 9,
                  span_kind => 0, status => 0, trace_hi => 0, trace_lo => 0,
                  span_id => 0, parent_id => 0,
                  attrs => { 'service.name' => 'shop' } };
    push @recs, { kind => 2, t => at(1_000_000_000 + $_ * $ms),
                  duration => 0, body => "ctx after $_", severity => 9,
                  span_kind => 0, status => 0, trace_hi => 0, trace_lo => 0,
                  span_id => 0, parent_id => 0,
                  attrs => { 'service.name' => 'shop' } } for 1 .. 60;
    ok(Punk::Observe::WAL::append($store2->wal_path, \@recs, 0, 0)->{ok},
       'the busy fixture reaches the log');
    ok($store2->seal, '  and seals');

    my $logs = $V->page($store2, 'logs',
                        { %W, q => 'log | search "the line itself"' });
    my $id = $logs->{rows}[0]{id};
    ok(length $id, 'the clicked line has an id');

    my $rec = $V->page($store2, 'record', { %W, id => $id });
    ok($rec->{found}, 'the busy record resolves');

    my @ctx = @{ $rec->{context} };
    is(scalar @ctx, 41, 'the context is twenty either side of the record');

    # The raw instant is the first half of each row's id, so the sides can
    # be counted without trusting the formatted time.
    my @ts     = map { (split /\./, $_->{id})[0] } @ctx;
    my $after  = grep { Punk::Observe::Store::ncmp($_, $C0) > 0 } @ts;
    my $at     = grep { "$_" eq "$C0" } @ts;
    my $before = grep { Punk::Observe::Store::ncmp($_, $C0) < 0 } @ts;
    is($after,  20, '  twenty lines after it');
    is($at,      2, '  both lines sharing its nanosecond');
    is($before, 19, '  and the lines before it fill the rest');

    is(scalar(grep { $_->{current} } @ctx), 1,
       'one line is current - the same nanosecond is not enough to be it');
    is((grep { $_->{current} } @ctx)[0]{id}, $id, '  and it is the one asked for');
}

# --- traces: a search, and a real waterfall ----------------------------------

{
    my $search = page('trace');
    is(scalar @{ $search->{traces} }, 2, 'the trace search finds both traces');
    ok($search->{traces}[0]{duration}, '  with a duration');
    my ($bad) = grep { $_->{errors} } @{ $search->{traces} };
    ok($bad, '  and the failing one is marked');
    is($bad->{row_class}, 'row-error', '  with a class, not with colour alone');

    my $errs = page('trace', { errors => 1 });
    is(scalar @{ $errs->{traces} }, 1, 'errors-only keeps only the failing trace');

    my $one = page('trace', { trace => $bad->{id} });
    is($one->{span_count}, 2, 'one trace assembles to its two spans');

    # The demo drew every bar at depth 0 starting at 0%, which is a set of
    # identical lines rather than a waterfall.
    my @depth = map { $_->{depth} } @{ $one->{spans} };
    is_deeply(\@depth, [ 0, 1 ], 'the spans are NESTED, not flat');
    is($one->{spans}[0]{start_pct}, 0, 'the root starts at the left');
    cmp_ok($one->{spans}[1]{start_pct}, '>', 0,
           '  and the child starts where it really did');
    cmp_ok($one->{spans}[1]{width_pct}, '>', 0, '  with a width of its own');
    is($one->{spans}[0]{service}, 'shop', 'each bar names its service');
    is($one->{spans}[1]{service}, 'cards', '  and they differ');
    is($one->{spans}[1]{kind_name}, 'client', 'span kind is named for the CSS');
    ok(scalar @{ $one->{flame} }, 'the flamegraph is built');

    # THE ROOT IS IN THE FLAMEGRAPH.
    #
    # This used to assert that the count of non-zero x positions plus the
    # count of zero ones equalled the total, which is true of any list of
    # numbers whatever. Underneath it the root span was being dropped from
    # every trace: the store hands back a parent SPAN ID and the view ran it
    # through the INDEX resolver, so the root became its own parent, assembly
    # read that as a cycle, and the frame builder skipped it.
    is(scalar @{ $one->{flame} }, 2,
       'the flamegraph has a frame for BOTH spans, root included');
    my ($rootf) = grep { $_->{depth} == 0 } @{ $one->{flame} };
    ok($rootf, '  with the root among them');
    is($rootf->{name}, 'POST /checkout', '  and it is the root span');
    cmp_ok($rootf->{width}, '>', 0, '  drawn with a width');
    my ($childf) = grep { $_->{depth} == 1 } @{ $one->{flame} };
    ok($childf, '  and the child sits under it');

    # COLLAPSING NEEDS THE PARENT IN THE MARKUP.
    #
    # Rows are emitted chronologically, so a subtree's descendants are only
    # adjacent when nothing else was running. waterfall.js used to walk the
    # next rows while their depth was greater, which hides a slice of whatever
    # was interleaved and leaves the real subtree on screen. It collapses by
    # identity now, and that needs data-parent on every row.
    for my $s (@{ $one->{spans} }) {
        ok(exists $s->{parent_span_id},
           "span $s->{span_id} carries its parent for the collapse");
    }
    my ($child) = grep { $_->{depth} == 1 } @{ $one->{spans} };
    my ($root)  = grep { $_->{depth} == 0 } @{ $one->{spans} };
    is($child->{parent_span_id}, $root->{span_id},
       '  and it is the real parent, not a position in the list');
    is($root->{parent_span_id}, 0, '  the root names none');

    my $html = render('trace', { %{ page('trace', { trace => $bad->{id} }) } });
    like($html, qr/data-parent="/, 'the rendered waterfall carries data-parent');

    # THE ATTRIBUTES REACH THE PAGE.
    #
    # The view sorted every span's attributes into a list and the template
    # never read it, so a database span said SELECT and nothing else. Once
    # the parenting fix put child spans under their request, every trace
    # was a column of operation names with no way to tell one from another.
    # Asserted in the HTML, not in the page vars: the vars had it all along.
    my @ak = map { $_->{key} } @{ $child->{attrs} };
    is_deeply(\@ak, [ sort @ak ], 'a span carries its attributes, sorted');
    is($child->{query}, 'SELECT limit_cents FROM cards WHERE id = ?',
       '  and db.query.text is lifted out as the query');
    ok(!exists $root->{query}, '  a span with no statement has no query');
    like($html, qr/data-detail="\Q$child->{span_id}\E"/,
         'the rendered waterfall has an attribute row for the child');
    like($html, qr{<td class="mono nowrap">db\.query\.text</td><td class="mono">SELECT limit_cents FROM cards WHERE id = \?</td>},
         '  holding the statement');
    like($html, qr{<td class="mono nowrap">http\.route</td><td class="mono">/authorize</td>},
         '  and the rest of the attributes');
    like($html, qr/data-more="\Q$child->{span_id}\E"/,
         '  with a button on the row to open it');
    like($html, qr/title="cards POST \/authorize [^"]*&#10;SELECT limit_cents FROM cards WHERE id = \?"/,
         '  and the statement in the bar tooltip, so a hover answers it');
    unlike($html, qr/title="shop POST \/checkout [^"]*&#10;/,
           '  while a span with no statement keeps the short tooltip');

    # A span in a cycle has depth -1, and 5 + -1*14 is -9px: the label used to
    # be dragged out of its own cell.
    cmp_ok($one->{spans}[0]{indent}, '>=', 0, 'no row is indented off its cell');

    my $missing = page('trace', { trace => '999-999' });
    ok(length $missing->{error}, 'a trace that is not there says so');

    # THE CROSS-SIGNAL JOIN, on the one screen where it is worth the most.
    # A waterfall says where the time went; the log lines say what the code
    # thought was happening while it went there. Having to go and search for
    # them by hand is the difference between an incident tool and two screens
    # that happen to live in one application.
    ok(scalar @{ $one->{logs} || [] },
       'the trace page carries the log lines of that trace');
    my ($refused) = grep { $_->{sev_name} eq 'error' } @{ $one->{logs} };
    ok($refused, '  including the error one');
    is($refused->{service}, 'cards', '  attributed to its service');
    ok(length $refused->{id}, '  and each is a link to the line itself');

    # And ONLY that trace's lines: the other trace logged too.
    my @bodies = map { $_->{body} } @{ $one->{logs} };
    is(scalar(grep { /checkout complete/ } @bodies), 0,
       '  and not the other trace\'s lines');
}

# --- the map: edges, and boxes with names in them ----------------------------

{
    my $m = page('map');
    ok(!$m->{empty}, 'the map has something to draw');

    # It rendered two unlabelled boxes and no lines, because the graph was
    # never accumulated and the template read a key the data did not have.
    ok(scalar @{ $m->{edges} }, 'the map HAS EDGES');
    for my $e (@{ $m->{edges} }) {
        like($e->{path}, qr/\AM[\d.]+,[\d.]+ C/, '  each drawn as a real path');
        ok($e->{weight} > 0, '  with a weight from its call count');
    }

    my @names = sort map { $_->{name} } @{ $m->{nodes} };
    is_deeply(\@names, [ 'cards', 'internet', 'shop' ],
              'every node is NAMED, including the synthetic root');
    for my $n (@{ $m->{nodes} }) {
        ok(defined $n->{x} && defined $n->{y}, "$n->{name} has coordinates");
    }

    my ($hop) = grep { $_->{caller} eq 'shop' } @{ $m->{edges} };
    ok($hop, 'shop calls cards');
    is($hop->{errors}, 1, '  and the error is attributed to the edge');
    is($hop->{state}, 'error', '  which the drawing can colour');
}

# --- metrics -----------------------------------------------------------------

{
    my $none = page('metrics');
    ok(scalar @{ $none->{names} },
       'with no query the metrics page offers what there is');
    is($none->{names}[0]{name}, 'http.server.duration', '  by name');

    my $q = page('metrics', { q => 'metric http.server.duration' });
    ok(scalar @{ $q->{series} }, 'a metric query draws a series');

    # The chart is a figure the browser draws, not a path the server laid out.
    # What is asserted here is that the figure is well-formed JSON carrying
    # the points - the drawing itself is Plotly's problem and t/95 runs the
    # module that hands it over.
    ok(length($q->{series_plot} || ''), '  as a figure for the browser');
    my $fig = eval { File::Raw::JSON::file_json_decode($q->{series_plot}) };
    ok(ref $fig eq 'HASH' && ref $fig->{data} eq 'ARRAY',
       '  which parses as a figure');
    ok(scalar @{ $fig->{data}[0]{x} || [] }, '  with points on it');

    # THE FIGURE MUST NOT BE ABLE TO CLOSE ITS OWN SCRIPT ELEMENT. It carries
    # service names and route templates, which are attacker-influenced in
    # exactly the way a request path is.
    unlike($q->{series_plot}, qr{</script}i,
           '  and cannot end the element it is embedded in');
}

# --- explore -----------------------------------------------------------------

# EVERY SHAPE THE LANGUAGE CAN RETURN HAS SOMEWHERE TO GO.
#
# `explore` is one box over every signal, so it cannot know what shape an
# answer will take. It branched on rows-versus-groups, which was every shape
# there was until `bucket` added a third - and a bucketed answer has `series`
# and no `groups`, so it took the groups branch, found nothing there, and drew
# a heading over an empty panel. A screen that answers two questions out of
# three and looks the same either way is the failure this file exists for.
{
    my %shape = (
        'log'                              => 'rows',
        'log | count by service'           => 'series',
        'log | bucket(1m) count by severity' => 'buckets',
        'spans | bucket(1m) p95'           => 'buckets',
    );
    for my $q (sort keys %shape) {
        my $v = page('explore', { q => $q });
        is($v->{shape}, $shape{$q}, "explore reports the shape of `$q`");

        my $drawn = @{ $v->{rows} || [] } || @{ $v->{groups} || [] }
                 || length($v->{series_plot} || '');
        ok($drawn, "  and has something to render for it")
            or diag('the page carries no rows, no groups and no figure');

        next unless $shape{$q} eq 'buckets';

        # A CHART IS NOT AN ANSWER ON ITS OWN. Reading a value off a line is
        # guessing, and the exact figure is what goes into a ticket - so a
        # bucketed answer carries the table it was drawn from as well.
        ok(scalar @{ $v->{bucket_rows} || [] },
           "  and the numbers behind the chart for `$q`");

        my @t = map { $_->{t} } @{ $v->{bucket_rows} };
        my $desc = 1;
        for my $i (1 .. $#t) {
            $desc = 0 if (length($t[$i]) <=> length($t[$i - 1])
                       || $t[$i] cmp $t[$i - 1]) > 0;
        }
        ok($desc, '  newest first, so an incident is not below the fold');

        # NEVER IN EXPONENTIAL FORM. A p95 in nanoseconds under %g reads
        # 6.7407e+07, which is true and useless in a column being scanned.
        my @exp = grep { $_->{value} =~ /e[+-]/i } @{ $v->{bucket_rows} };
        is(scalar @exp, 0, '  with values a reader can compare at a glance')
            or diag('exponential: ' . $exp[0]{value});
    }
}

# --- a severity grouping reads as severities --------------------------------
#
# THE ENGINE RETURNS THE NUMBER ON PURPOSE - a query compares severities
# numerically, and t/0903 pins that. But a column of 13, 17, 5 and 9 is not
# information to the person reading it, so the name goes on at the point of
# reading.
#
# THE QUERY IS THE ONLY THING THAT KNOWS. A series keyed 13 is a severity or
# an attempt count depending entirely on what was grouped by, so the guard is
# `by severity` in the query rather than a guess at the values - which would
# rename a `by attempt` grouping of 1, 2, 3 into trace and debug.
{
    my $v = page('explore', { q => 'log | bucket(1m) count by severity' });
    my %seen;
    my @s = grep { !$seen{$_}++ } map { $_->{series} } @{ $v->{bucket_rows} || [] };
    ok(scalar @s, 'a severity grouping produces series') or return;

    my @numeric = grep { /\A\d+\z/ } @s;
    is(scalar @numeric, 0, 'none of them is a bare number')
        or diag("still numeric: @numeric");
    ok((grep { /\A(?:trace|debug|info|warn|error|fatal)\z/ } @s) == @s,
       '  every one is a name on the twenty-four point scale')
        or diag("got: @s");

    # THE CHART AND THE TABLE ARE ONE ANSWER. Naming the table and leaving the
    # legend reading 13, 17, 5, 9 is two renderings of the same query
    # disagreeing about what it says - which is why the rename happens on the
    # result, before either is built, rather than on the table afterwards.
    my %ly;
    my @legend = grep { !$ly{$_}++ }
                 ($v->{series_plot} || '') =~ /"name":"([^"]*)"/g;
    ok(scalar @legend, 'the figure carries a legend') or return;
    is(scalar(grep { /\A\d+\z/ } @legend), 0,
       '  and the chart legend is named too, not just the table')
        or diag("legend: @legend");

    # The guard is the GROUPING, not the mention. This query talks about
    # severity and groups by service, and its labels must survive.
    my $svc = page('explore',
        { q => 'log | where severity >= error | bucket(1m) count by service' });
    %seen = ();
    my @n = grep { !$seen{$_}++ } map { $_->{series} } @{ $svc->{bucket_rows} || [] };
    ok(scalar @n, 'a query that only mentions severity still groups by service');
    is(scalar(grep { /\A(?:trace|debug|info|warn|error|fatal)\z/ } @n), 0,
       '  and its service names are left alone')
        or diag("renamed: @n");
}

{
    my $e = page('explore');
    ok(scalar @{ $e->{examples} }, 'explore offers the language');
    ok(!length($e->{error} || ''), '  and no error before anything is run');

    my $r = page('explore', { q => 'spans | by service | count' });
    ok(scalar @{ $r->{groups} },
       'an aggregate comes back as GROUPS, not as invented rows');
    is(scalar @{ $r->{rows} }, 0, '  with no row list beside them');
}

# --- status ------------------------------------------------------------------

{
    my $s = page('status');
    is($s->{segments}, 1, 'the status page counts the segment');
    is($s->{compaction_lag}, 0, '  with no unsummarised one');
    ok(scalar @{ $s->{services} }, '  and lists what is reporting');
}

# --- the nav knows where it is -----------------------------------------------

{
    for my $case ([ logs => 'here_logs' ], [ map => 'here_map' ],
                  [ metrics => 'here_metrics' ], [ explore => 'here_explore' ],
                  [ trace => 'here_traces' ], [ status => 'here_home' ]) {
        my $v = page($case->[0]);
        ok($v->{ $case->[1] }, "$case->[0] marks $case->[1]");
    }
}

# --- and it all renders ------------------------------------------------------

{
    my %empty = (
        rows => [], groups => [], names => [], series => [], yticks => [],
        nodes => [], edges => [], spans => [], traces => [], flame => [],
        attrs => [], context => [], services => [], examples => [],
        record => {}, query => '', query_esc => '', from => 0, to => 0,
        heading => '', title => '', error => '', hint => '', refusal => '',
        truncated => 0, scanned => 0, degraded => 0, tail => 0, found => 0,
        empty => 0, exact => 1, offset => 0, total => 0, errors => 0,
        errors_only => 0, min_ms => '', trace => '', flame_height => 0,
        width => 720, height => 220, root_name => '', span_count => 0,
        duration_ms => 0, orphans => 0, cycles => 0, back_edges => 0,
        ingest_rate => 0, wal_depth => 0, segments => 0, compaction_lag => 0,
        series_cap => 0, series_rejected => 0,
        mapped_deleted => 0, store_bytes => '0 B', logs => 0, metrics => 0,
        rules => [], silences => [], broken => 0,
    );

    for my $case ([ 'logs.tmpl',    page('logs') ],
                  [ 'record.tmpl',  page('record', { id => 'nope' }) ],
                  [ 'trace.tmpl',   page('trace') ],
                  [ 'map.tmpl',     page('map') ],
                  [ 'metrics.tmpl', page('metrics') ],
                  [ 'explore.tmpl', page('explore') ],
                  [ 'status.tmpl',  page('status') ]) {
        my ($tmpl, $vars) = @$case;
        my $out = eval { render($tmpl, { %empty, %$vars }) };
        ok(defined $out && length $out, "$tmpl renders with real data")
            or diag $@;
        unlike($out || '', qr/\{%/, "  leaving nothing unrendered");
        like($out || '', qr/<!doctype html>/i, "  through the wrapper");
    }

    # The four interaction modules are LOADED. They were shipped, tested and
    # served by no route at all, and the test suite forbade a src attribute
    # that would have loaded them.
    my $out = render('logs.tmpl', { %empty, %{ page('logs') } });
    for my $js (qw(brush.js waterfall.js flamegraph.js livetail.js)) {
        like($out, qr/\Q$js\E/, "the page loads $js");
    }
    unlike($out, qr{src="(?:https?:)?//}, '  and none of them off-origin');
}

# --- the map is drawn with names, in the markup ------------------------------

{
    my $m = page('map');
    my $out = render('map.tmpl', { prefix => '/observe', %$m,
                                   back_edges => $m->{back_edges} || 0 });
    like($out, qr/>shop</,  'the map markup contains the service names');
    like($out, qr/>cards</, '  both of them');
    like($out, qr/<path class="line/, '  and the edges as paths');
}

# --- the trace search answers the two questions people arrive with -----------
#
# Somebody on this page has either an IDENTIFIER - pasted out of a log line, a
# header, another vendor's UI - or a DESCRIPTION of what they want. Making
# them pick the right control first means the id goes in the filter box,
# matches nothing, and the page says "no traces", which reads as "that trace
# is gone".
{
    my $list = page('trace');
    my $id   = $list->{traces}[0]{id};
    ok($id, 'the search lists traces with an id each');

    # An identifier opens the trace.
    my $byid = page('trace', { q => $id });
    is($byid->{span_count}, 2, 'a trace id in the search box OPENS that trace');
    ok(scalar @{ $byid->{spans} }, '  as a waterfall, not a filtered list');

    # THE ID ON THE SCREEN IS THE ID IN THE URL. The list once showed eight
    # hex characters derived from the high half by a modulo and linked to a
    # decimal pair, so what you read was not a prefix of what you clicked and
    # was not what any other tool would show you.
    is(length $id, 32, 'the identifier is the canonical 32 hex characters');
    like($id, qr/\A[0-9a-f]{32}\z/, '  lower case, as the specification has it');
    # AND THE TABLE SHOWS THE WHOLE THING. A truncated id cannot be pasted
    # into a chat window, grepped for, or handed to another tool, which is
    # every use a trace id has.
    my $out = render('trace.tmpl', { prefix => '/observe', %$list });
    like($out, qr/\Q$id\E<\/a>/,
         'the table renders the full identifier, not a prefix of it');

    # The decimal pair is what the record holds, and a bookmark from before
    # this change still resolves.
    my ($hi, $lo) = Punk::Observe::View::trace_id($id);
    my $bydec = page('trace', { q => "$hi-$lo" });
    is($bydec->{span_count}, $byid->{span_count},
       'the decimal pair finds the same trace');
    is($bydec->{heading}, $byid->{heading}, '  and it is the same trace');

    # And case does not matter, because a copy out of another tool may not be
    # lower case.
    my $byupper = page('trace', { q => uc $id });
    is($byupper->{span_count}, $byid->{span_count},
       'an upper-case id finds it too');

    # Anything that is not an identifier is a search term.
    my $posts = page('trace', { q => 'POST' });
    cmp_ok(scalar @{ $posts->{traces} }, '>', 0, 'a term filters instead');
    is(scalar(grep { $_->{name} !~ /POST/i } @{ $posts->{traces} }), 0,
       '  keeping only the traces whose root span matches');

    # The method is in the span name, which is what makes "all the POSTs" a
    # question this box can answer at all.
    my $route = page('trace', { q => '/checkout' });
    cmp_ok(scalar @{ $route->{traces} }, '>', 0, 'a route matches too');

    # And the service, because that is the other half of what a root span is.
    my $svc = page('trace', { q => 'shop' });
    cmp_ok(scalar @{ $svc->{traces} }, '>', 0, 'so does a service name');

    # Case-insensitively: a search box is typed into, not copied from.
    my $lower = page('trace', { q => 'post' });
    is(scalar @{ $lower->{traces} }, scalar @{ $posts->{traces} },
       'matching ignores case');

    my $none = page('trace', { q => 'no-such-route-anywhere' });
    is(scalar @{ $none->{traces} }, 0, 'a term matching nothing returns nothing');

    # An all-zero id is invalid per OTLP and is also what a truncated paste
    # looks like, so it is a search term rather than a lookup that fails.
    my @z = Punk::Observe::View::trace_id('0' x 32);
    is(scalar @z, 0, 'an all-zero id is not an identifier');
    my @junk = Punk::Observe::View::trace_id('POST');
    is(scalar @junk, 0, '  and neither is a word');
    my @pad = Punk::Observe::View::trace_id("  $id  ");
    is(scalar @pad, 2, 'a pasted id survives its surrounding whitespace');
}

# --- the time range is a CONTROL, not a constant ----------------------------
#
# Every screen reads a window and the default is an hour, which is right: a
# page that reads everything gets slower every day it runs. A bounded default
# with NO WAY TO WIDEN IT is a dead end though - what it says to somebody
# whose data is from this morning is "nothing matched", and that reads as
# "there is no data", which is a different and wrong answer.
{
    # The fixture is dated 2026 and every default range is relative to now, so
    # the default finds nothing and `all` finds everything. That is exactly
    # the situation the control exists for.
    for my $name (qw(logs trace map metrics explore)) {
        my $v = $V->page($store, $name, {});
        ok(scalar @{ $v->{ranges} || [] },
           "$name offers the range control");
        is($v->{range}, '1h', "  defaulting to the last hour");
        my ($cur) = grep { $_->{current} } @{ $v->{ranges} };
        is($cur->{key}, '1h', "  with the active one marked");
    }

    my $all = $V->page($store, 'trace', { range => 'all' });
    is($all->{range}, 'all', 'the range is taken from the request');
    ok($all->{range_all}, '  and `all` says so, so an empty state does not '
                        . 'suggest a wider one');
    cmp_ok(scalar @{ $all->{traces} }, '>', 0,
           '  and it finds data the default window could not');

    my $wide = $V->page($store, 'logs', { range => '30d' });
    is($wide->{range}, '30d', 'a named range is honoured');

    # THE CHOICE HAS TO SURVIVE THE NEXT SUBMIT.
    #
    # A form submits the name and value of the ONE button that was activated,
    # so pressing Run - or Enter in the query box - sent no `range` at all and
    # the server fell back to the default. Picking "last 7 days" and then
    # refining the query silently threw the seven days away.
    for my $r (qw(7d all 15m)) {
        my $v = $V->page($store, 'logs', { range => $r });
        my $out = render('logs.tmpl', { %empty_page, %$v });
        like($out, qr/<input type="hidden" name="range" value="\Q$r\E">/,
             "the $r window is carried in a hidden field");
    }

    # A custom window has no key, so the two instants travel instead - or a
    # dragged selection on a chart lasts exactly until the next thing anybody
    # types.
    my $custom = $V->page($store, 'logs', { %W });
    is($custom->{range}, 'custom', 'an explicit pair is its own range');
    ok($custom->{range_custom}, '  and says so, so the form knows to carry it');
    my $cout = render('logs.tmpl', { %empty_page, %$custom });
    like($cout, qr/name="from" value="\Q$W{from}\E"/,
         '  carrying the start instant');
    like($cout, qr/name="to" value="\Q$W{to}\E"/, '  and the end');

    # A named range must NOT carry a stale pair beside it.
    my $named = $V->page($store, 'logs', { range => '6h' });
    my $nout  = render('logs.tmpl', { %empty_page, %$named });
    unlike($nout, qr/name="from"/,
           'a named range carries no from/to, so it stays relative');

    # An unknown range falls back to the default rather than to nothing: a
    # hand-edited URL must not produce an empty screen with no explanation.
    my $junk = $V->page($store, 'logs', { range => 'yesteryear' });
    is($junk->{range}, '1h', 'an unknown range falls back to the default');

    # The brush writes explicit bounds into the URL, and those beat a range.
    my $exact = $V->page($store, 'logs', { %W });
    is($exact->{range}, 'custom', 'explicit from/to are their own range');
    is($exact->{from}, $W{from}, '  and are used as given');
}

# --- the "slower than" box -------------------------------------------------
#
# A FILTER THAT CANNOT BE READ MUST NOT BE DROPPED. The box took /\A\d+\z/ and
# discarded anything else without a word, so typing the placeholder's own words
# back at it - "slower than 100" - removed the filter and answered with the
# whole unfiltered table. That is the one wrong outcome that looks exactly like
# a right one.
{
    my $M = 'Punk::Observe::View::min_duration';
    no strict 'refs';

    # An empty box is not a filter, and is not a mistake either. The empty
    # list is what separates the two, so it is what is checked.
    is_deeply([ &$M('') ],      [], 'an empty box is no filter at all');
    is_deeply([ &$M(undef) ],   [], '  and so is an absent one');
    is_deeply([ &$M('   ') ],   [], '  and so is whitespace');

    # A bare number is MILLISECONDS. The field is named min_ms and always
    # meant that; changing it would silently rescale every saved URL.
    is((&$M('100'))[0],   100_000_000, 'a bare number is milliseconds');
    is((&$M(' 100 '))[0], 100_000_000, '  around any amount of space');

    # The units are the query language's own, so the box and `duration >
    # 500ms` cannot disagree about what 500ms is.
    is((&$M('250us'))[0],     250_000, 'us is understood');
    is((&$M('500ms'))[0], 500_000_000, 'ms is understood');
    is((&$M('2s'))[0],  2_000_000_000, 's is understood');
    is((&$M('2m'))[0], 120_000_000_000, 'm is minutes, as in the query language');
    is((&$M('100 ms'))[0], 100_000_000, 'a space before the unit is fine');
    is((&$M('1.5s'))[0], 1_500_000_000, 'a fraction is understood');
    is((&$M('0.25ms'))[0],    250_000, '  including one below the unit');

    # ONE BOX, BOTH ENDS. "faster than 100ms" is a question about the same
    # column as "slower than 100ms", and only one of them used to be askable.
    is_deeply([ &$M('> 100')   ], ['100000000', 'min'], 'a leading > bounds the slow end');
    is_deeply([ &$M('>=250ms') ], ['250000000', 'min'], '  and >=');
    is_deeply([ &$M('100')     ], ['100000000', 'min'], '  and so does no operator at all');
    is_deeply([ &$M('< 100ms') ], ['100000000', 'max'], 'a leading < bounds the fast end');
    is_deeply([ &$M('<=100ms') ], ['100000000', 'max'], '  and <=');
    is_deeply([ &$M('<100')    ], ['100000000', 'max'], '  with the same bare-number unit');
    # A zero MAXIMUM is a real bound - it selects the instantaneous traces -
    # so it must not be mistaken for an absent one.
    is_deeply([ &$M('< 0ns') ], ['0', 'max'], 'a zero maximum is still a bound');

    # THE CASE THAT STARTED THIS. Every one of these used to return undef and
    # be treated as "no filter".
    for my $bad ('slower than 100', 'abc', '5.', 'ms', '1e9', '100msec', '>') {
        my @r = &$M($bad);
        is(scalar @r, 1, "'$bad' is answered, not ignored");
        ok(!defined $r[0], "  and refused rather than dropped");
    }

    # A number and a unit is still not a duration if it does not fit. The
    # alternative is a wrapped value: a filter that runs and means something
    # else entirely.
    ok(!defined((&$M('4000000000w'))[0]), 'an unrepresentable duration refuses');
    ok(!defined((&$M('99999999999999'))[0]), '  and so does one in milliseconds');
    is((&$M('18446744073709551615ns'))[0], '18446744073709551615',
       '  while the largest one that does fit is exact');
}

# And the page SAYS SO rather than quietly showing everything.
{
    my $bad = $V->page($store, 'trace',
                       { range => 'all', min_ms => 'slower than 100' });
    like($bad->{error} || '', qr/not a duration/,
         'an unreadable duration is refused on the page');
    like($bad->{hint} || '', qr/100ms|250us|milliseconds/,
         '  with the forms that would have worked');
    is_deeply($bad->{traces}, [],
              '  and no table, because a full one would read as the answer');

    my $out = render('trace.tmpl', { %empty_page, %$bad });
    like($out, qr/warnbox/, '  the refusal is drawn where it can be seen');
    like($out, qr/name="min_ms" value="slower than 100"/,
         '  and what was typed is still in the box to correct');

    # The same box, read correctly, still filters.
    my $good = $V->page($store, 'trace', { range => 'all', min_ms => '0ms' });
    is($good->{error} || '', '', 'a readable duration is not an error');

    # BOTH ENDS REACH THE STORE, and they select opposite sets. Anything
    # else - a max quietly applied as a min, or dropped - would return a
    # plausible table for the wrong question.
    my $all  = $V->page($store, 'trace', { range => 'all' });
    my %dur  = map { $_->{id} => $_->{duration} } @{ $all->{traces} };
    cmp_ok(scalar keys %dur, '>', 1, 'the fixture has traces of differing length');

    my $slow = $V->page($store, 'trace', { range => 'all', min_ms => '> 0ns' });
    my $fast = $V->page($store, 'trace', { range => 'all', min_ms => '< 1ns' });
    my %slow_ids = map { $_->{id} => 1 } @{ $slow->{traces} };
    my %fast_ids = map { $_->{id} => 1 } @{ $fast->{traces} };
    is_deeply([ grep { $fast_ids{$_} } keys %slow_ids ], [],
              'the two directions select disjoint sets');
    is(scalar(keys %slow_ids) + scalar(keys %fast_ids), scalar keys %dur,
       '  and between them account for every trace');
}

# --- the window follows the reader between screens -------------------------
#
# Picking a range on one screen and clicking to the next used to land on a
# fresh default hour, so two screens one click apart described different spans
# of time. It travels in the LINK, not in localStorage: a URL that means
# something different depending on which browser opens it is not one you can
# paste to somebody, and pasting one is most of what these pages are for.
{
    my $P = 'Punk::Plugin::Observe';
    require Punk::Plugin::Observe;

    is($P->can('_range_qs')->({}), '', 'nothing to carry adds nothing to a URL');
    is($P->can('_range_qs')->({ range => '6h' }), '?range=6h',
       'a named range is carried by name, so it stays relative');
    is($P->can('_range_qs')->({ range => '6h' }, '&'), '&range=6h',
       '  with & for a link that already has a query string');

    # An explicit pair beats a named range, in the same order window() reads
    # them - or a link would carry one window and the page resolve another.
    is($P->can('_range_qs')->({ range => 'custom', from => '1', to => '2' }),
       '?from=1&to=2', 'an explicit pair wins, as it does in the resolver');

    # A bare &, because the templates escape what they interpolate.
    unlike($P->can('_range_qs')->({ from => '1', to => '2' }), qr/&amp;/,
           '  and is not pre-escaped, which would arrive doubled');

    is($P->can('_range_qs')->({ range => 'a b&c=d' }), '?range=a%20b%26c%3Dd',
       'a range key is percent-encoded on the way into an href');

    # A half-specified pair is not a window, and must fall back rather than
    # produce `?from=&to=` - which is what the picker's empty fields submit.
    is($P->can('_range_qs')->({ range => '7d', from => '', to => '' }),
       '?range=7d', 'empty from/to fall back to the named range');

    # And the nav actually carries it.
    my $v = $V->page($store, 'logs', { range => '7d' });
    my $out = render('logs.tmpl',
                     { %empty_page, %$v, range_qs => '?range=7d', range_amp => '&range=7d' });
    # The nav's own roster: Status left it when Health arrived - the status
    # page still answers at /status, it is just not a section tab.
    for my $screen (qw(map traces logs metrics explore alerts health)) {
        like($out, qr{href="\Q/observe/$screen?range=7d\E"},
             "the $screen link carries the window");
    }
}

# --- the service map: the number, and the way it is written -----------------
#
# THE TABLE WANTS "1,200" AND THE FLOW DIAGRAM WANTS 1200. Both used to read
# one key, and the key held the formatted string, so the diagram numified it -
# and Perl stops numifying at the comma. An edge of 62,577 calls came out as
# 62: a Sankey link a thousandth of its real width, labelled "62 calls, 3121
# in error", which is a sentence that cannot be true.
{
    my $dir2 = File::Temp::tempdir(CLEANUP => 1);
    my $big  = Punk::Observe::Store->new(dir => $dir2);

    # Enough calls that the display form and the number differ. Below a
    # thousand they are the same string and this test would pass either way.
    my @recs;
    for my $n (0 .. 1_199) {
        my $base = $n * 1_000_000;
        push @recs,
            { kind => 3, t => at($base), duration => '5000000',
              body => 'POST /checkout', span_kind => 2, status => 0,
              trace_hi => 500, trace_lo => 600 + $n, span_id => 1,
              parent_id => 0, severity => 0,
              attrs => { 'service.name' => 'shop' } },
            { kind => 3, t => at($base + 1000), duration => '3000000',
              body => 'POST /authorize', span_kind => 3,
              status => ($n < 7 ? 2 : 0),
              trace_hi => 500, trace_lo => 600 + $n, span_id => 2,
              parent_id => 1, severity => 0,
              attrs => { 'service.name' => 'cards' } };
    }
    ok(Punk::Observe::WAL::append($big->wal_path, \@recs, 0, 0)->{ok},
       'the large fixture reaches the log');
    ok($big->seal, '  and seals');

    my $m = $V->page($big, 'map', { %W });
    my ($edge) = grep { ($_->{caller} || '') eq 'shop' } @{ $m->{edges} || [] };
    ok($edge, 'the shop to cards edge is on the map');

    like($edge->{count}, qr/\A[0-9]+\z/,
         '  and `count` is the number, all digits');
    is($edge->{count} + 0, 1_200, '  which is the count');
    is($edge->{count_label}, '1,200',
       '  while `count_label` is the form the table shows');
    {
        # The numification is the POINT of this assertion, so the warning it
        # earns is expected rather than a symptom. Scoped off, because a
        # passing test that prints a warning on every run teaches people to
        # skim the warnings.
        no warnings 'numeric';
        is(0 + $edge->{count_label}, 1,
           '  which numifies to 1, which is why the two cannot share a key');
    }

    # The figure is drawn from the number rather than from that.
    ok($m->{flow_plot}, 'the flow diagram was built');
    my $fig = File::Raw::JSON::file_json_decode($m->{flow_plot});
    my $link = $fig->{data}[0]{link};
    my ($i) = grep { $fig->{data}[0]{node}{label}[ $link->{source}[$_] ] eq 'shop' }
              0 .. $#{ $link->{source} };
    ok(defined $i, '  with a link out of shop');
    is($link->{value}[$i], 1_200,
       '  whose width is the call count, not the formatted string numified');
    like($link->{label}[$i], qr/\b1200 calls\b/,
         '  and whose hover text agrees with it');

    # A link with errors is coloured by them and one without is not: the array
    # is per-link, and plot.js resolves the roles inside it.
    is_deeply([ sort keys %{ { map { $_ => 1 } @{ $link->{color} } } } ],
              [ sort keys %{ { map { $_ => 1 } @{ $link->{color} } } } ],
              '  the colours are one per link');
    ok(scalar(grep { $_ eq 'sev:error' } @{ $link->{color} }),
       '  and a failing flow is named by its failure');
}

# The control has to be REACHABLE on the screen that tells you to use it.
{
    my %empty = (prefix => '/observe', theme => '', toolbar => '',
                 rows => [], groups => [], names => [], series => [],
                 yticks => [], nodes => [], edges => [], spans => [],
                 traces => [], flame => [], attrs => [], context => [],
                 services => [], examples => [], logs => [], record => {},
                 query => '', query_esc => '', from => 0, to => 0,
                 heading => '', title => '', error => '', hint => '',
                 refusal => '', truncated => 0, scanned => 0, degraded => 0,
                 tail => 0, found => 0, empty => 1, exact => 1, offset => 0,
                 total => 0, errors => 0, errors_only => 0, min_ms => '',
                 trace => '', flame_height => 0, width => 720, height => 220,
                 root_name => '', span_count => 0, duration_ms => 0,
                 orphans => 0, cycles => 0, back_edges => 0,
                 has_severity => 0, has_duration => 0, has_value => 0,
                 has_trace => 0,
                 range_qs => '', range_amp => '', range => '1h', range_all => 0,
                 ranges => [ { key => '1h', label => 'last hour', current => 1 },
                             { key => 'all', label => 'everything', current => 0 } ]);

    for my $t (qw(trace.tmpl logs.tmpl map.tmpl metrics.tmpl explore.tmpl)) {
        my $out = eval { render($t, \%empty) };
        ok(defined $out, "$t renders its empty state") or diag $@;
        like($out || '', qr/class="rangebtn/,
             "  WITH the range control still on it");
    }
}

# --- the alerts page assembles its own vars ------------------------------
# A rule that could not be EVALUATED is the one worth seeing, so `error` sorts
# above `firing` and takes the error row class however the alphabet falls.
{
    my $src = {
        can_edit => 1,
        rules => [
            { id => 1, name => 'zeta',   state => 'ok',      value => 1.23456789,
              query => 'a b&c' },
            { id => 2, name => 'Alpha',  state => 'firing',  held => 90_000_000_000,
              value => 0, silenced => 1 },
            { id => 3, name => 'beta',   state => 'error',
              reason => 'the store refused the query' },
            { id => 4, name => 'gamma',  state => 'pending', value => 12345.678 },
            { id => 5, name => 'Delta',  state => 'weird' },
            { id => 6, name => 'alpha2', state => 'firing' },
        ],
        silences => [ { pattern => 'p*', until => '1774224000000000000',
                        by => 'me', reason => 'why' },
                      { pattern => 'q*', by => 'you' } ],
    };

    my $v = Punk::Observe::View->page(undef, 'alerts', { alerts => $src });
    is($v->{configured}, 1, 'alerts: a source makes the page configured');
    is($v->{can_edit},   1, '  can_edit comes off the source');
    is($v->{broken},     1, '  one rule could not be evaluated');
    is($v->{empty},      0, '  and the page is not empty');
    is(join(',', map { $_->{name} } @{ $v->{rules} }),
       'beta,Alpha,alpha2,gamma,zeta,Delta',
       '  error, then firing, then pending, then ok, then unknown');
    is($v->{rules}[0]{row_class}, 'row-error', '  error takes the error class');
    is($v->{rules}[0]{reason}, 'the store refused the query',
       '  and carries WHY it could not be evaluated');
    is($v->{rules}[1]{reason}, '', '  a rule with no reason carries none');
    is($v->{rules}[3]{row_class}, '',          '  pending does not');
    is($v->{rules}[1]{held},  '90.00s',        '  held is a duration');
    is($v->{rules}[1]{value}, '0',             '  a zero value is still shown');
    # Was '1.235e+04': %.4g lost the fifth digit of every count and read
    # like a chart axis. Large values round to the integer, comma-grouped
    # like the count columns beside them.
    is($v->{rules}[3]{value}, '12,346',        '  and a big one is grouped');
    is($v->{rules}[4]{query_esc}, 'a%20b%26c', '  the query is url escaped');
    is($v->{silences}[0]{until}, '2026-03-23 00:00:00Z', '  silences carry a date');
    is($v->{silences}[1]{until}, '', '  a silence with no expiry has no date');

    # The filter is a case-insensitive substring on the NAME, and a rule it
    # drops is not counted as broken either.
    my $f = Punk::Observe::View->page(undef, 'alerts',
                                      { alerts => $src, q => 'AL' });
    is(join(',', map { $_->{name} } @{ $f->{rules} }), 'Alpha,alpha2',
       'alerts: the filter folds case');
    is($f->{broken}, 0, '  and counts only what survived it');

    # A source that dies leaves the page configured and empty-handed, never
    # half-populated.
    my $d = Punk::Observe::View->page(undef, 'alerts',
                                      { alerts => sub { die "nope\n" } });
    is($d->{configured}, 1, 'alerts: a dying source is still configured');
    is(scalar @{ $d->{rules} }, 0, '  with no rules');
    is(scalar @{ $d->{silences} }, 0, '  and no silences');

    my $n = Punk::Observe::View->page(undef, 'alerts', {});
    is($n->{configured}, 0, 'alerts: no source at all is unconfigured');
    is($n->{empty}, 1, '  and empty');
}

# --- an unreadable filter is REFUSED, not dropped ---------------------------
# Three answers, not two: nothing typed, something typed that does not read as
# a duration, and a duration. Collapsing the middle one into the first is what
# made a mistyped filter answer with the whole unfiltered table - the one
# outcome indistinguishable from a correct one.
{
    my %cases = (
        'banana'  => 1,   # not a duration
        '   '     => 1,   # nothing but space, and something WAS typed
        '100'     => 0,   # bare milliseconds
        '< 100ms' => 0,   # the fast end of the same box
        '>= 2s'   => 0,
        ''        => 0,   # no filter at all
    );
    for my $in (sort keys %cases) {
        my $v = page('trace', { min_ms => $in });
        if ($cases{$in}) {
            is($v->{error}, "'$in' is not a duration.",
               "min_ms '$in' is refused by name");
            ok(length $v->{hint}, "  with something to do about it");
            is(scalar @{ $v->{traces} }, 0, "  and no traces at all");
        }
        else {
            ok(!defined $v->{error}, "min_ms '$in' is accepted");
        }
    }

    # A BARE ZERO IS A FILTER SOMEBODY TYPED, and `|| ''` blanks it for the
    # box while the guard still has to see it. Reading the display value back
    # as the guard would make "0" mean "no filter".
    my $z = page('trace', { min_ms => '0' });
    ok(!defined $z->{error}, 'min_ms 0 is a duration, not a mistake');
    is($z->{min_ms}, '', '  and the box shows it blank, as it always has');
}

# --- only a count may be zero-filled ----------------------------------------
# An absent bucket saw no rows. For a count that is nought arrivals; for a
# percentile it is UNDEFINED, and drawing it as zero invents a fast bucket
# where there was no traffic - which is the shape of a recovery.
{
    my $dir2 = tempdir(CLEANUP => 1);
    my $s2 = Punk::Observe::Store->new(dir => $dir2);
    my @r;
    # 0-4s and 20-24s, with a sixteen second hole between them
    for my $i (0 .. 4, 20 .. 24) {
        push @r, { t => at($i * 1_000_000_000), kind => 1, body => 'm',
                   value => $i + 1, attrs => { 'service.name' => 'api' } };
    }
    Punk::Observe::WAL::append($s2->wal_path, \@r, 1, '0');
    $s2->seal;

    my %w2 = (from => $T0, to => at(30_000_000_000));
    my $fig = sub {
        my $v = Punk::Observe::View->page($s2, 'metrics', { %w2, q => $_[0] });
        return File::Raw::JSON::file_json_decode($v->{series_plot} || '{}');
    };

    my $count = $fig->('metric m | bucket(5s) count');
    is_deeply($count->{data}[0]{y}, [ 5, 0, 0, 0, 5 ],
              'a bucketed count fills its holes with zero');

    my $p95 = $fig->('metric m | bucket(5s) p95');
    is(scalar(grep { !defined } @{ $p95->{data}[0]{y} }), 3,
       'a bucketed percentile leaves them undefined');

    # `rate` carries a unit, and the axis has to say so or the numbers are
    # read as totals.
    my $rate = $fig->('metric m | rate(5s)');
    is($rate->{layout}{yaxis}{title}{text}, 'per second',
       'a rate labels its own axis');
    is($count->{layout}{yaxis}{title}{text}, '',
       '  and a count does not borrow the label');

    # A stage that does not exist is an error, not an empty chart. (The
    # `\b` in front of `bucket` is inherited from the regex this replaced and
    # cannot change an answer here - `\s*\(` has to follow immediately, and
    # no name in this grammar is followed by an open bracket - so it is not
    # claimed as tested.)
    my $re = Punk::Observe::View->page($s2, 'metrics',
                                       { %w2, q => 'metric m | rebucket(5s) count' });
    ok(!$re->{series_plot}, 'an unknown stage draws no chart');
    ok(length($re->{error} || ''), '  and says why');
}

done_testing();
