#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Spec ();
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
plan skip_all => 'Template::Stencil required'
    unless eval { require Template::Stencil; 1 };

# The admin UI renders through Template::Stencil, from two roots: the app's
# own directory (if it named one) and the bundled one. A name resolves to
# the first root that has it, so an override directory holds only what it
# changes - and the same is true of css/js, which append to the bundles.

my @KEEP;
sub write_dir {
    my (%files) = @_;
    my $dir = File::Temp->newdir(TEMPLATE => 'pqtmpl-XXXXXX', TMPDIR => 1);
    push @KEEP, $dir;
    while (my ($name, $body) = each %files) {
        open my $fh, '>', File::Spec->catfile("$dir", $name) or die $!;
        print $fh $body;
        close $fh;
    }
    return "$dir";
}

sub get {
    my ($app, $path, %env) = @_;
    open my $in, '<', \(my $body = '') or die $!;
    return $app->({ REQUEST_METHOD => 'GET', PATH_INFO => $path,
                    QUERY_STRING => '', CONTENT_TYPE => '',
                    CONTENT_LENGTH => 0, 'psgi.input' => $in, %env });
}

sub header_of {
    my ($res, $name) = @_;
    my @h = @{ $res->[1] };
    while (my ($k, $v) = splice @h, 0, 2) {
        return $v if lc $k eq lc $name;
    }
    return undef;
}

# ---- one page overridden, everything else bundled ----------------------------

my $tdir = write_dir(
    'jobs.tmpl' => qq{<h1 class="page-title">My Jobs</h1>\n}
                 . qq{<div id="mine" data-prefix="{% prefix %}"></div>\n},
);

{
    package TmplApp;
    use Punk;
    plugin 'Queue' => {
        dsn   => 'dbi:SQLite:dbname=' . PQTest::queue_file(),
        admin => { prefix => '/q', guard => sub { return },
                   templates => $tdir },
    };
}
my $app = TmplApp->to_app;

{
    my $html = get($app, '/q/jobs')->[2][0];
    like($html, qr/<h1 class="page-title">My Jobs<\/h1>/,
         'the overridden page template is the one rendered');
    like($html, qr/<div id="mine" data-prefix="\/q">/,
         '...with the same data the shipped templates get');
    unlike($html, qr/pqJobsTable/, '...and not the shipped one');

    like($html, qr/<title>Jobs - punk-queue<\/title>/,
         'the bundled layout still wraps it');
    like($html, qr{<a href="/q/workers">Workers</a>},
         '...nav and all');

    my $other = get($app, '/q/workers')->[2][0];
    like($other, qr/pqWorkersTable/,
         'a page the override directory does not have falls back to ours');
}

# ---- the layout itself -------------------------------------------------------

my $ldir = write_dir(
    'layout.tmpl' => qq{<html><head><title>{% title %}</title>\n}
                   . qq{{% for href in styles %}<link href="{% href %}">{% end %}\n}
                   . qq{</head><body data-page="{% page %}" data-live="{% live %}">\n}
                   . qq{<nav>{% for i in nav %}<a href="{% i.href %}">{% i.label %}</a>{% end %}</nav>\n}
                   . qq{{% raw content %}\n}
                   . qq{{% for src in scripts %}<script src="{% src %}"></script>{% end %}\n}
                   . qq{</body></html>\n},
);

{
    package LayoutApp;
    use Punk;
    plugin 'Queue' => {
        dsn   => 'dbi:SQLite:dbname=' . PQTest::queue_file(),
        admin => { prefix => '/admin/q', guard => sub { return },
                   templates => $ldir },
    };
}
my $lapp = LayoutApp->to_app;

{
    my $html = get($lapp, '/admin/q/locks')->[2][0];
    like($html, qr/^<html><head><title>Locks<\/title>/,
         'a custom layout replaces ours');
    like($html, qr/pqLocksTable/, '...and still wraps the shipped page');
    like($html, qr{<link href="/admin/q/assets/funky\.css">},
         'styles carries the stylesheet URLs, so a layout needs no paths');
    like($html, qr{<script src="/admin/q/assets/funky\.js"></script>\s*<script src="/admin/q/assets/app\.js"></script>},
         'scripts carries them in load order');
    like($html, qr{<a href="/admin/q">Overview</a>}, 'nav is data');
    like($html, qr/data-live="false"/, 'live is a JS literal');
    unlike($html, qr/\{%/, 'nothing is left untemplated');
}

# ---- css and js overrides ----------------------------------------------------

my $adir = write_dir(
    'brand.css' => ".pq-brand { color: rebeccapurple }\n",
    'extra.js'  => "window.__MINE = 1;\n",
    'more.js'   => "window.__ALSO = 2;\n",
);

{
    package AssetApp2;
    use Punk;
    plugin 'Queue' => {
        dsn   => 'dbi:SQLite:dbname=' . PQTest::queue_file(),
        admin => { prefix => '/q', guard => sub { return },
                   css => File::Spec->catfile($adir, 'brand.css'),
                   js  => [ File::Spec->catfile($adir, 'extra.js'),
                            File::Spec->catfile($adir, 'more.js') ] },
    };
}
my $aapp = AssetApp2->to_app;

{
    my $css = get($aapp, '/q/assets/funky.css')->[2][0];
    like($css, qr/rebeccapurple/, 'a css override is served');
    ok(index($css, 'rebeccapurple') > index($css, '--pq-'),
       '...at the end, after our own sheet, so the cascade favours it');

    my $js = get($aapp, '/q/assets/app.js')->[2][0];
    like($js, qr/window\.__MINE = 1/, 'a js override is served');
    ok(index($js, 'window.__MINE') < index($js, 'window.__ALSO'),
       '...in the order given');
    ok(index($js, 'window.__MINE') > index($js, 'Funky'),
       '...after app.js, which it can therefore build on');
}

# ---- the ETag follows the bytes ----------------------------------------------

{
    my $plain = get($app,  '/q/assets/funky.css');
    my $mine  = get($aapp, '/q/assets/funky.css');
    my ($e1, $e2) = (header_of($plain, 'ETag'), header_of($mine, 'ETag'));
    ok($e1 && $e2, 'both bundles are ETagged');
    isnt($e1, $e2, 'an override changes the ETag - no stale shared cache');

    my $again = get($aapp, '/q/assets/funky.css',
                    HTTP_IF_NONE_MATCH => $e2);
    is($again->[0], 304, 'and the ETag still answers a conditional GET');
}

# ---- boot-time failures ------------------------------------------------------

{
    my $err = '';
    eval {
        package BadTmplApp;
        use Punk;
        plugin 'Queue' => {
            dsn   => 'dbi:SQLite:dbname=' . PQTest::queue_file(),
            admin => { guard => sub { return },
                       templates => '/no/such/template/dir' },
        };
        1;
    } or $err = $@;
    like($err, qr/templates => '\/no\/such\/template\/dir' is not a directory/,
         'a missing template directory croaks at boot');
}

{
    my $err = '';
    eval {
        package BadCssApp;
        use Punk;
        plugin 'Queue' => {
            dsn   => 'dbi:SQLite:dbname=' . PQTest::queue_file(),
            admin => { guard => sub { return },
                       css => '/no/such/sheet.css' },
        };
        1;
    } or $err = $@;
    like($err, qr/css override '\/no\/such\/sheet\.css' is not a readable file/,
         'a missing override sheet croaks at boot, naming it');
}

done_testing();
