#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# the inline app packages `use Punk` at compile time, so this guard
# must run during compilation too - a runtime skip_all would be too late
BEGIN {
    # The VERSION check is the load-bearing half. install_kw arrived in
    # Punk 0.04 and is how the queue/task/cron keywords reach an app
    # class; against an older Punk this file compiles far enough to call
    # it and then dies mid-BEGIN, which a smoker reports as a FAIL of
    # this dist rather than as the missing dependency it is. Punk is a
    # recommends, not a requires - the queue works standalone - so an
    # old one is a normal thing to meet.
    unless (eval { require Punk; Punk->VERSION('0.04'); 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'Punk 0.04 required for the plugin');
    }
}
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";

{
    package AssetApp;
    use Punk;
    plugin 'Queue' => {
        dsn   => $DSN,
        admin => { prefix => '/q', guard => sub { return } },
    };
}
my $app = AssetApp->to_app;

sub hit_asset {
    my (%o) = @_;
    my $body = '';
    open my $in, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => $o{path},
        QUERY_STRING => '', CONTENT_TYPE => '', CONTENT_LENGTH => 0,
        'psgi.input' => $in, %{ $o{env} // {} },
    });
}
sub header_of {
    my ($res, $name) = @_;
    my @h = @{ $res->[1] };
    while (my ($k, $v) = splice @h, 0, 2) {
        return $v if lc $k eq lc $name;
    }
    return undef;
}

# ---- the served bundle matches VENDORED.md, in order ------------------------

my $res = hit_asset(path => '/q/assets/funky.js');
is($res->[0], 200, 'funky.js serves');
my $js = $res->[2][0];

like(substr($js, 0, 4000), qr/THIS MUST BE LOADED BEFORE ANY OTHER/,
     'the bundle starts with the namespace module');

# every js file VENDORED.md lists, present in listed order
my $vendored = do {
    open my $fh, '<',
        "$FindBin::Bin/../lib/Punk/Plugin/Queue/assets/VENDORED.md"
        or die $!;
    local $/; <$fh>;
};
my @listed = $vendored =~ /^\s{4}(\d\d-[\w.-]+\.js)\b/mg;
ok(@listed >= 37, 'VENDORED.md lists the js files (' . @listed . ')');

my $asset_dir = "$FindBin::Bin/../lib/Punk/Plugin/Queue/assets/funky/js";
opendir my $dh, $asset_dir or die $!;
my @on_disk = sort grep { /\.js\z/ } readdir $dh;
closedir $dh;
is_deeply(\@on_disk, \@listed,
          'the js files on disk are exactly the listed set, same order');

# each vendored file's own opening bytes are its marker: assert every
# file's content appears in the bundle, at monotonically increasing
# positions - completeness and order in one pass
{
    my $pos = -1;
    my $ordered = 1;
    my $complete = 1;
    for my $f (@listed) {
        open my $fh, '<:raw', "$asset_dir/$f" or die "$f: $!";
        read $fh, my $head, 200;
        close $fh;
        my $at = index($js, $head);
        if ($at < 0) { $complete = 0; diag("missing content: $f"); last }
        if ($at < $pos) { $ordered = 0; diag("out of order: $f"); last }
        $pos = $at;
    }
    ok($complete && $ordered,
       'every listed file is in the served bundle, in dependency order');
}

# css: themes last of the framework, punk-queue.css after as override
$res = hit_asset(path => '/q/assets/funky.css');
is($res->[0], 200, 'funky.css serves');
my $css = $res->[2][0];
my $themes_at = index($css, '[data-theme');
my $pq_at     = index($css, 'punk-queue.css - the override layer');
ok($themes_at > 0, 'themes.css is in the bundle');
ok($pq_at > $themes_at, 'punk-queue.css comes after it - the override');
like($css, qr/\.fa-check-circle::before/,
     'the FontAwesome neutralisation is present (no icon font vendored)');

$res = hit_asset(path => '/q/assets/app.js');
is($res->[0], 200, 'app.js serves');
my $appjs = $res->[2][0];
like($appjs, qr/entity_change/, 'with the ws entity bridge');

# ---- the three contracts with the vendored subset ---------------------------
# Each of these is a name or a signature that lives in Funky and is silent
# when it is wrong: no error, just a column reading 'undefined', a toolbar
# that never appears, or a control wearing the browser's default chrome.

# 1. a column renderer is called as (value, type, row) - the DataTables
#    signature (table.js: `renderer(value, 'display', rowData, meta)`).
#    Taking the second argument as the row yields the string 'display'.
unlike($appjs, qr/render:\s*function\s*\(\s*\w+\s*,\s*row\s*\)/,
       'no column renderer mistakes the type argument for the row');
like($appjs,
     qr/render:\s*function\s*\(v,\s*type,\s*row\)\s*\{\s*return \(v \+ 1\) \+ '\/' \+ row\.attempts/,
     "the jobs table's attempt column reads the row it was given, "
   . "one-based like the log's lifecycle rows");

# 1b. SPA.bindNavigation intercepts every same-origin a[href] at the
#     document; a listener of ours on such a link double-navigates and
#     the doubled showLoading orphans a spinner timer (the stuck
#     "Loading..." bug). Only href="#" links may carry a handler.
unlike($appjs, qr/closest\([^)]*a\[data-action="view"\]/,
       'no click listener shadows SPA navigation on the view links');

# 2. Funky.Table appends its wrapper INSIDE the element it is given, so the
#    container has to be a div - a <table> host makes the bulk action bar
#    (inserted as the container's first child) a stray div inside a table.
{
    my $tdir = "$FindBin::Bin/../lib/Punk/Plugin/Queue/assets/templates";
    opendir my $td, $tdir or die $!;
    my @bad;
    for my $f (sort grep { /\.tmpl\z/ } readdir $td) {
        open my $fh, '<', "$tdir/$f" or die $!;
        local $/;
        my $t = <$fh>;
        push @bad, $f if $t =~ /<table\s+id="pq/;
    }
    closedir $td;
    is_deeply(\@bad, [], 'every Funky.Table container is a div, not a table');
}

# 3. bulk-actions.js emits `bulk-action-bar` (singular) and creates it
#    hidden, then hands the display over to CSS. Nothing in the vendored
#    subset styles it, so this sheet must.
like($css, qr/\.bulk-action-bar\s*\{/,
     'the bulk action bar is styled under the class Funky emits');
like($css, qr/\.bulk-action-bar\.show\s*\{[^}]*display/,
     '...including the .show state it toggles');
like($css, qr/\.pq-shell select\b/,
     'bare selects are themed - Funky only dresses .form-control');

# .funky-table ellipses every cell (overflow:hidden + max-width:0). That is
# right for a wide data table and wrong for a column of identifiers: among
# fifty tasks sharing a prefix, `mail.welc...` names nothing.
like($css, qr/\.pq-breakdown th:first-child,\s*\.pq-breakdown td:first-child \{[^}]*text-overflow: clip/s,
     'the breakdown name column opts out of the blanket cell ellipsis');
like($appjs, qr/<a href="#" title="' \+ esc\(names\[i\]\)/,
     '...and carries the full name in a title as well as its text');

# 4. relative-time hydrates on `funky.datatable.draw` (a DOM event) while
#    Funky.Table announces `funky:table:draw` on PubSub. Rows drawn by a
#    reload keep an empty <time> without a bridge between the two.
like($appjs, qr/PubSub\.on\('funky:table:draw'/,
     'app.js bridges the table draw into RelativeTime');

# ---- the poll is the load-bearing refresh -----------------------------------
# A job changes state inside a worker process, which cannot reach a socket
# held by a web process, so live mode can never carry the transitions worth
# watching. The 5s tick re-reads the current page's own view - but only
# when the stats it already fetched say something moved, and only accepts
# the new signature once the page really did re-read (a hidden tab or an
# open selection defers the refresh; swallowing it would lose the change).
like($appjs, qr/function statsSignature\(s\)/,
     'the poll derives a change signature from the stats it already has');
like($appjs, qr/if \(lastSig === null \|\| refreshActive\(\)\) lastSig = sig;/,
     '...refreshes the page only on a change, and defers rather than drops');
like($appjs, qr/\w+\.selectedIds && \w+\.selectedIds\.size\)\) return false;/,
     '...never while rows are selected, mid-bulk-action');
like($appjs, qr/if \(!activeRefresh \|\| document\.hidden\) return false;/,
     '...and never into a hidden tab');

# ---- ETag / 304 -------------------------------------------------------------

$res = hit_asset(path => '/q/assets/funky.js');
my $etag = header_of($res, 'ETag');
ok($etag, "the bundle carries an ETag ($etag)");

$res = hit_asset(path => '/q/assets/funky.js',
                 env => { HTTP_IF_NONE_MATCH => $etag });
is($res->[0], 304, 'a matching If-None-Match gets 304');
is(scalar @{ $res->[2] }, 0, 'with no body');

# ---- the no-CDN rule, executable --------------------------------------------

for my $page ('', qw(/jobs /workers /locks /crons)) {
    my $r = hit_asset(path => "/q$page");
    my $html = $r->[2][0];
    my @external = $html =~ m{(?:src|href)="(https?://[^"]+)"}g;
    is_deeply(\@external, [],
        "page '/q$page' references only same-origin assets");
}

done_testing();
