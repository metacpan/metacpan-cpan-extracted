package Punk::Plugin::Queue;

use 5.010;
use strict;
use warnings;
use Carp ();
use File::Basename ();
use File::Spec ();
use File::Raw::JSON ();
use Punk::Queue ();

our $VERSION = '0.02';

my %STATE;

sub _state {
    my ($pkg) = @_;
    return $STATE{$pkg} //= {
        queues => {}, tasks => [], crons => [],
        registered => 0, compiled => 0, keywords_used => 0,
    };
}

sub state_for { $STATE{ $_[1] // $_[0] } }   # test/introspection seam

# ---- import: the keywords ---------------------------------------------------

sub import {
    my ($class) = @_;
    my $caller = caller;
    return if $caller->can('cron') && $caller->can('task');
    _install_keywords($caller);
    return;
}

sub _install_keywords {
    my ($pkg, $app) = @_;
    my $st = _state($pkg);

    $app ||= $pkg->can('punk_app') ? $pkg->punk_app
        : Carp::croak("Punk::Plugin::Queue: $pkg is not a Punk application "
                    . "- `use Punk` before `use Punk::Plugin::Queue`");

    # a to_app-time tripwire: if keywords recorded declarations but the
    # plugin never registered, compiling the app is the moment to say so
    if (!$st->{tripwire}) {
        $st->{tripwire} = 1;
        $app->middleware(sub {
            my ($inner) = @_;
            if ($st->{keywords_used} && !$st->{registered}) {
                require Carp;
                Carp::croak("cron used but plugin 'Queue' was never "
                          . "registered (add plugin 'Queue' => {...})");
            }
            return $inner;
        });
    }

    # `use` then `plugin` reaches here twice. Punk would ignore the second
    # install anyway - same name, same owner - but there is no reason to
    # build three closures for it to drop.
    return if $st->{keywords_installed};
    $st->{keywords_installed} = 1;

    # queue NAME => \%defaults records; queue() with no args returns the
    # queue object - the class-level accessor controllers use at boot
    $app->install_kw(queue => sub {
        my ($name, $defaults) = @_;
        if (!defined $name) {
            my $q = $st->{queue}
                or Carp::croak("Punk::Plugin::Queue: plugin 'Queue' has "
                             . "not been registered yet");
            return $q;
        }
        $st->{keywords_used}++;
        $st->{queues}{$name} = $defaults // {};
        $st->{queue}->queue_defaults($name, $defaults // {})
            if $st->{queue};
        return;
    }, __PACKAGE__);

    $app->install_kw(task => sub {
        my ($name, $target, $defaults) = @_;
        $st->{keywords_used}++;
        push @{ $st->{tasks} }, {
            name => $name, target => $target,
            ($defaults ? (defaults => $defaults) : ()),
        };
        return;
    }, __PACKAGE__);

    $app->install_kw(cron => sub {
        my ($expr, $target, $opts) = @_;
        $st->{keywords_used}++;
        $opts //= {};
        # the default name is the target string SANITISED to the queue
        # name rule ('Reports#nightly' -> 'Reports-nightly'): the same
        # name lands in pq_crons at reconcile, where the name rule has
        # no sense of humour about '#'
        my $name = $opts->{name};
        if (!defined $name) {
            if (ref $target) { $name = 'cron-' . scalar @{ $st->{crons} } }
            else {
                ($name = $target) =~ s/[^A-Za-z0-9_.:-]/-/g;
                $name = substr $name, 0, 64;
            }
        }
        push @{ $st->{crons} }, {
            expr    => $expr,
            target  => $target,
            name    => $name,
            task    => $opts->{task},
            args    => $opts->{args} // [],
            queue   => $opts->{queue} // 'default',
            priority=> $opts->{priority} // 0,
            attempts=> $opts->{attempts} // 1,
            tz      => $opts->{tz} // 'UTC',
            catchup => $opts->{catchup} // 'once',
        };
        return;
    }, __PACKAGE__);
    return;
}

# ---- register: the plugin ---------------------------------------------------

sub new { bless {}, $_[0] }

sub register {
    my ($self, $app, $opts) = @_;
    $opts //= {};
    my $pkg = $app->caller_class
        or Carp::croak('Punk::Plugin::Queue: the app has no caller class');
    my $st = _state($pkg);

    # the terser form: plugin first, keywords after - install them now
    _install_keywords($pkg, $app);
    $st->{app}  = $app;
    $st->{opts} = $opts;

    # backend: explicit dsn, else the app's database keyword/config
    my %qopts;
    if ($opts->{dsn}) {
        $qopts{$_} = $opts->{$_}
            for grep { defined $opts->{$_} }
                qw(dsn user password attr attempts_delay max_backoff
                   missing_after remove_after auto_migrate);
    }
    elsif (my $db = ($app->{databases} || {})->{default}) {
        $qopts{dsn}      = $db->{dsn}
            or Carp::croak("Punk::Plugin::Queue: the app's database has "
                         . "no dsn");
        $qopts{user}     = $db->{user}     if defined $db->{user};
        $qopts{password} = $db->{password} if defined $db->{password};
    }
    else {
        Carp::croak("Punk::Plugin::Queue: no dsn - pass dsn => ... to the "
                  . "plugin, or add a database keyword to the app");
    }
    my $q = Punk::Queue->new(%qopts);
    $q->migrate unless exists $opts->{auto_migrate}
                    && !$opts->{auto_migrate};
    $st->{queue} = $q;

    # queue defaults recorded before we existed
    $q->queue_defaults($_, $st->{queues}{$_}) for keys %{ $st->{queues} };

    # helpers: real methods on the per-app context subclass at to_app;
    # collisions croak here, naming both owners - Punk's behaviour, wanted
    $app->helper(queue   => sub { $q }, __PACKAGE__);
    $app->helper(enqueue => sub {
        my ($c, $task, $args, @rest) = @_;
        my $id = $q->enqueue($task, $args, @rest);
        _live_push($st, job => create => $id);
        return $id;
    }, __PACKAGE__);
    $app->helper(job => sub { $q->job_info($_[1]) }, __PACKAGE__);

    # the compile point: middleware construction runs exactly once at
    # to_app, after every keyword has recorded - resolve targets there so
    # a typo croaks at boot, matching Punk's compile-at-boot promise
    $app->middleware(sub {
        my ($inner) = @_;
        _compile($st) unless $st->{compiled};
        return $inner;
    });

    $st->{registered} = 1;

    _register_admin($st)     if $opts->{admin};
    _register_inserver($st)  if $opts->{in_server};
    return;
}

# 'Job::Mail#send' -> the coderef, resolved relative to the app class's
# controller namespace exactly as Punk's router resolves route targets;
# '+Full::Class#method' escapes the namespace.
sub _resolve_target {
    my ($st, $target, $what) = @_;
    return $target if ref $target eq 'CODE';
    my ($cls, $method) = ($target // '') =~ /\A(.+)#(\w+)\z/
        or Carp::croak("Punk::Plugin::Queue: $what target '"
                     . ($target // 'undef')
                     . "' is neither a coderef nor 'Class#method'");
    unless ($cls =~ s/\A\+//) {
        $cls = $st->{app}->caller_class . '::Controller::' . $cls;
    }
    (my $file = "$cls.pm") =~ s{::}{/}g;
    eval { require $file } or do {
        Carp::croak("Punk::Plugin::Queue: cannot load $cls for $what '"
                  . "$target': $@") unless $cls->can($method);
    };
    my $code = $cls->can($method)
        or Carp::croak("Punk::Plugin::Queue: $cls has no method '$method' "
                     . "(from $what '$target')");
    return $code;
}

sub _compile {
    my ($st) = @_;
    my $q = $st->{queue};
    for my $t (@{ $st->{tasks} }) {
        $q->task($t->{name}, _resolve_target($st, $t->{target}, 'task'));
        $q->task_defaults($t->{name}, $t->{defaults}) if $t->{defaults};
    }
    for my $c (@{ $st->{crons} }) {
        # a cron whose target is a bare task name refers to a registered
        # task; anything else resolves like a route target and registers
        # under a derived name
        if (!ref $c->{target} && $c->{target} !~ /#/) {
            $c->{task} = $c->{target};
            Carp::croak("Punk::Plugin::Queue: cron '$c->{name}' names "
                      . "task '$c->{task}', which is not registered")
                unless $q->task($c->{task});
        }
        else {
            $c->{task} //= substr "cron.$c->{name}", 0, 64;
            $q->task($c->{task},
                     _resolve_target($st, $c->{target}, 'cron'));
        }
    }

    # reconcile the declarations into the cron store: upsert each (which
    # validates the expression - a bad cron croaks the boot), then retire
    # whatever this app no longer declares. upsert never touches an
    # operator's enabled flag, so a paused cron stays paused across
    # deploys; disable-not-delete keeps identity and history.
    for my $c (@{ $st->{crons} }) {
        $q->upsert_cron({
            name     => $c->{name},   expr     => $c->{expr},
            task     => $c->{task},   args     => $c->{args},
            queue    => $c->{queue},  priority => $c->{priority},
            attempts => $c->{attempts},
            tz       => $c->{tz},     catchup  => $c->{catchup},
        });
    }
    $q->disable_missing_crons([ map { $_->{name} } @{ $st->{crons} } ]);

    $st->{compiled} = 1;
    return;
}

# ---- admin ------------------------------------------------------------------

# Ordered, because it is also the nav: a template override that wants a
# different nav gets the same list as `nav` and can ignore it.
my @PAGES = (
    { path => '',        tmpl => 'overview', id => 'pq-overview', title => 'Overview' },
    { path => 'jobs',    tmpl => 'jobs',     id => 'pq-jobs',     title => 'Jobs' },
    { path => 'workers', tmpl => 'workers',  id => 'pq-workers',  title => 'Workers' },
    { path => 'locks',   tmpl => 'locks',    id => 'pq-locks',    title => 'Locks' },
    { path => 'crons',   tmpl => 'crons',    id => 'pq-crons',    title => 'Crons' },
);

# every template the admin UI renders: the pages, the job detail page and
# the layout they go into
my @TEMPLATES = ((map { $_->{tmpl} } @PAGES), 'job', 'layout');

sub _asset_dir {
    my $pm = $INC{'Punk/Plugin/Queue.pm'}
        or Carp::croak('Punk::Plugin::Queue: cannot self-locate');
    return File::Spec->catdir(File::Basename::dirname($pm),
                              'Queue', 'assets');
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or Carp::croak("Punk::Plugin::Queue: cannot read $path: $!");
    local $/;
    return scalar <$fh>;
}

# A list option that may be given as one value or several.
sub _list { my ($v) = @_; return !defined $v ? () : ref $v eq 'ARRAY' ? @$v : ($v) }

# The bundles: slurped ONCE at register, concatenated in lexical order -
# which IS the dependency order, the numeric prefixes exist for exactly
# this - and served from memory. No per-request file IO; after boot there
# is nothing on disk to misconfigure.
#
# An app's own sheets and scripts land at the END of the bundle they join,
# which is what makes them overrides: last declaration wins in CSS, and a
# script that runs after app.js sees everything it set up.
sub _build_assets {
    my ($st, $a) = @_;
    my $dir = _asset_dir();
    my (%bundle, @order);

    for my $kind (['js', 'funky.js'], ['css', 'funky.css']) {
        my ($sub, $name) = @$kind;
        my $d = File::Spec->catdir($dir, 'funky', $sub);
        opendir my $dh, $d
            or Carp::croak("Punk::Plugin::Queue: cannot read $d: $!");
        my @files = sort grep { /\.(?:js|css)\z/ } readdir $dh;
        closedir $dh;
        Carp::croak("Punk::Plugin::Queue: the vendored funky/$sub "
                  . "directory is empty") unless @files;
        $bundle{$name} = join "\n",
            map { _slurp(File::Spec->catfile($d, $_)) } @files;
        push @order, [$name, \@files];
    }
    $bundle{'funky.css'} .= "\n"
        . _slurp(File::Spec->catfile($dir, 'punk-queue.css'));
    $bundle{'app.js'} = _slurp(File::Spec->catfile($dir, 'app.js'));

    for my $ext ([css => 'funky.css'], [js => 'app.js']) {
        my ($opt, $name) = @$ext;
        for my $f (_list($a->{$opt})) {
            Carp::croak("Punk::Plugin::Queue: admin $opt override '$f' "
                      . "is not a readable file") unless -f $f && -r _;
            $bundle{$name} .= "\n/* $opt: $f */\n" . _slurp($f);
            push @{ $st->{overrides}{$opt} }, $f;
        }
    }

    $st->{assets} = \%bundle;
    $st->{asset_order} = \@order;
    # the ETag is over the bytes, not the version: two deploys of the same
    # release with different override files must not share a cache entry
    $st->{etags} = { map {
        $_ => sprintf '"pq-%s-%x-%x"', $VERSION, length $bundle{$_},
                      unpack '%32C*', $bundle{$_}
    } keys %bundle };
    return;
}

# The templates. Two roots at most - the app's, then ours - and a name
# resolves to the first root that has it, so an override directory holds
# only the templates it actually changes. Which root serves which name is
# decided HERE, at boot: a typo in an override directory is a boot croak,
# and the request path never stats anything.
sub _build_templates {
    my ($st, $a) = @_;
    eval { require Template::Stencil; 1 }
        or Carp::croak("Punk::Plugin::Queue: the admin UI renders through "
                     . "Template::Stencil, which is not installed: $@");

    my @dirs;
    if (defined(my $d = $a->{templates})) {
        Carp::croak("Punk::Plugin::Queue: admin templates => '$d' is not "
                  . "a directory") unless -d $d;
        push @dirs, $d;
    }
    push @dirs, File::Spec->catdir(_asset_dir(), 'templates');

    # stat_ttl => -1: never re-stat. The rendered pages are cached anyway
    # (below), so a template edit needs a restart either way - and this is
    # a Punk app, where everything is compiled at boot.
    my @engines = map {
        Template::Stencil->new(template_dir => $_, stat_ttl => -1)
    } @dirs;

    for my $name (@TEMPLATES) {
        my ($i) = grep { -f File::Spec->catfile($dirs[$_], "$name.tmpl") }
                       0 .. $#dirs;
        Carp::croak("Punk::Plugin::Queue: no template '$name.tmpl' in "
                  . join(' or ', @dirs)) unless defined $i;
        $st->{templates}{$name} = $engines[$i];
        $st->{template_dir}{$name} = $dirs[$i];
    }
    $st->{template_dirs} = \@dirs;
    return;
}

# Everything every page renders with. Built at register, so a custom
# layout sees the same names the shipped one does.
sub _template_data {
    my ($st) = @_;
    my $p = $st->{prefix};
    return {
        prefix  => $p,
        version => $VERSION,
        styles  => ["$p/assets/funky.css"],
        scripts => ["$p/assets/funky.js", "$p/assets/app.js"],
        nav     => [ map { { href => $p . ($_->{path} ? "/$_->{path}" : ''),
                             label => $_->{title}, id => $_->{id} } } @PAGES ],
    };
}

# A page, rendered lazily on first serve: the csrf cookie name is read off
# the app then, not at register, because `csrf` may legitimately run after
# `plugin` in the app class. Two renders - the page, then the layout with
# it as `content` - rather than Stencil's wrapper, because page and layout
# may come from different roots and a wrapper renders in one engine.
sub _page {
    my ($st, $name, $id, $title, %extra) = @_;
    my $key = "$name:" . join(',', map { "$_=$extra{$_}" } sort keys %extra);
    return $st->{page_cache}{$key} //= do {
        my $csrf = $st->{app}{csrf};
        my $data = {
            %{ $st->{tmpl_data} },
            page        => $id,
            title       => $title,
            csrf_cookie => $csrf ? ($csrf->{cookie} // 'csrf') : '',
            live        => $st->{live} ? 'true' : 'false',
            %extra,
        };
        $data->{content} = $st->{templates}{$name}->render($name, $data);
        $st->{templates}{layout}->render('layout', $data);
    };
}

sub _bytes {
    my ($c, $type, $body, $etag) = @_;
    if ($etag) {
        my $inm = $c->req->header('If-None-Match') // '';
        return [304, ['ETag' => $etag], []] if $inm eq $etag;
        return [200, ['Content-Type' => $type,
                      'Content-Length' => length $body,
                      'ETag' => $etag], [$body]];
    }
    return [200, ['Content-Type' => $type,
                  'Content-Length' => length $body], [$body]];
}

sub _register_admin {
    my ($st) = @_;
    my $app  = $st->{app};
    my $a    = $st->{opts}{admin};
    $a = {} unless ref $a;

    # A loud failure beats a silent hole: an admin UI that retries and
    # removes jobs without a guard is an unauthenticated control plane.
    Carp::croak("Punk::Plugin::Queue: admin needs a guard - "
              . "admin => { guard => sub {...} } (or set "
              . "PUNK_QUEUE_ADMIN_INSECURE to mean it)")
        unless $a->{guard} or $ENV{PUNK_QUEUE_ADMIN_INSECURE};

    my $prefix = $a->{prefix} // '/queue';
    $prefix =~ s{/\z}{};
    $st->{prefix} = $prefix;
    $st->{live} = 0;

    if ($a->{api}) {
        warn "Punk::Plugin::Queue: admin => { api => 1 } (Open::API "
           . "registration) is not implemented in this release; using "
           . "the native routes\n";
    }

    _build_assets($st, $a);
    _build_templates($st, $a);
    $st->{tmpl_data} = _template_data($st);

    my $gcode = ref $a->{guard} eq 'CODE' ? $a->{guard}
              : $a->{guard} ? _resolve_target($st, $a->{guard},
                                              'admin guard')
              : sub { return };            # PUNK_QUEUE_ADMIN_INSECURE
    my $s = $app->under($prefix => $gcode);
    my $q = $st->{queue};

    # ---- pages ----
    # A page GET touches $c->csrf_token when the app has csrf configured:
    # the mint writes the script-readable mirror cookie for this response,
    # which the layout's bridge copies into the cookie Funky hardcodes -
    # without the touch, the browser never holds a token to submit.
    my $mint = sub {
        my ($c) = @_;
        $c->csrf_token if $st->{app}{csrf};
        return;
    };
    for my $p (@PAGES) {
        $s->get(($p->{path} eq '' ? '/' : "/$p->{path}") => sub {
            my ($c) = @_;
            $mint->($c);
            return _bytes($c, 'text/html; charset=utf-8',
                _page($st, $p->{tmpl}, $p->{id}, $p->{title}));
        });
    }
    $s->get('/jobs/:id' => sub {
        my ($c) = @_;
        my $id = $c->param('id');
        return $c->not_found unless ($id // '') =~ /\A\d+\z/;
        $mint->($c);
        return _bytes($c, 'text/html; charset=utf-8',
            _page($st, 'job', 'pq-job', "Job $id", id => $id));
    });

    # ---- assets (memory-served, ETagged) ----
    for my $asset (['funky.js', 'application/javascript; charset=utf-8'],
                   ['funky.css', 'text/css; charset=utf-8'],
                   ['app.js', 'application/javascript; charset=utf-8']) {
        my ($name, $type) = @$asset;
        $s->get("/assets/$name" => sub {
            my ($c) = @_;
            return _bytes($c, $type, $st->{assets}{$name},
                          $st->{etags}{$name});
        });
    }

    # ---- the api ----
    my $json_err = sub {
        my ($c, $status, $msg) = @_;
        return $c->json({ error => $msg }, $status);
    };

    $s->get('/api/stats'   => sub { $_[0]->json($q->stats) });
    $s->get('/api/history' => sub { $_[0]->json($q->history) });

    # Funky.Table's server-side wire: draw/page/limit/search/sort(JSON
    # [{column,dir}]) + the filter vocabulary; response { data, total,
    # draw }. page/limit map onto phase 6's offset/limit; sortable
    # columns are whitelisted in C exactly as filterable ones are.
    my $table = sub {
        my ($c, $lister, $key) = @_;
        my $page  = int($c->param('page')  // 1);  $page  = 1  if $page < 1;
        my $limit = int($c->param('limit') // 25);
        $limit = 25 if $limit < 1; $limit = 100 if $limit > 100;

        my %f;
        for my $k (qw(state queue task worker search)) {
            my $v = $c->param($k);
            $f{$k} = $v if defined $v && length $v;
        }
        my ($sc, $sd);
        if (my $sort = $c->param('sort')) {
            my $list = eval {
                File::Raw::JSON::file_json_decode($sort) };
            if (ref $list eq 'ARRAY' && @$list) {
                $sc = $list->[0]{column};
                $sd = ($list->[0]{dir} // '') eq 'asc' ? 'asc' : 'desc';
            }
        }
        my $r = eval { $lister->($page, $limit, \%f, $sc, $sd) };
        return $json_err->($c, 400, "$@" =~ s/ at .*//rs) if $@;
        return $c->json({
            data  => $r->{$key},
            total => $r->{total},
            draw  => int($c->param('draw') // 0),
        });
    };

    $s->get('/api/jobs' => sub {
        my ($c) = @_;
        return $table->($c, sub {
            my ($page, $limit, $f, $sc, $sd) = @_;
            $q->list_jobs(($page - 1) * $limit, $limit, $f, $sc, $sd);
        }, 'jobs');
    });
    $s->get('/api/workers' => sub {
        my ($c) = @_;
        return $table->($c, sub {
            my ($page, $limit, $f) = @_;
            $q->list_workers(($page - 1) * $limit, $limit, $f);
        }, 'workers');
    });
    $s->get('/api/locks' => sub {
        my ($c) = @_;
        return $table->($c, sub {
            my ($page, $limit, $f) = @_;
            $q->list_locks(($page - 1) * $limit, $limit, $f);
        }, 'locks');
    });
    $s->get('/api/crons' => sub {
        my ($c) = @_;
        my $page  = int($c->param('page')  // 1);  $page = 1 if $page < 1;
        my $limit = int($c->param('limit') // 25);
        $limit = 25 if $limit < 1; $limit = 100 if $limit > 100;
        # crons are declarations - dozens, not millions - so search here
        # greps the full set in Perl instead of growing the C lister,
        # and paging slices afterwards so page 2 of a search is right
        my $rows = $q->list_crons->{crons};
        my $term = $c->param('search');
        if (defined $term and length $term) {
            my $t = lc $term;
            $rows = [ grep {
                index(lc $_->{name}, $t) >= 0
                    || index(lc $_->{task}, $t) >= 0
                    || index(lc $_->{expr}, $t) >= 0
            } @$rows ];
        }
        my $total = @$rows;
        my $off = ($page - 1) * $limit;
        $rows = $off < $total
            ? [ @{$rows}[$off .. ($off + $limit - 1 > $#$rows
                                      ? $#$rows : $off + $limit - 1)] ]
            : [];
        # Funky selection/update keys off row.id; the name IS the identity
        my @rows = map { { %$_, id => $_->{name} } } @$rows;
        return $c->json({ data => \@rows, total => $total,
                          draw => int($c->param('draw') // 0) });
    });

    $s->get('/api/jobs/:id' => sub {
        my ($c) = @_;
        my $j = $q->job_info(int($c->param('id')));
        return $json_err->($c, 404, 'no such job') unless $j;
        return $c->json($j);
    });
    # the job's log, oldest first - lifecycle rows plus whatever the
    # task wrote through $job->log
    $s->get('/api/jobs/:id/log' => sub {
        my ($c) = @_;
        my $id = int($c->param('id'));
        return $json_err->($c, 404, 'no such job')
            unless $q->job_info($id);
        my $log = $q->job_log($id);
        return $c->json({ log => $log, total => scalar @$log });
    });
    $s->post('/api/jobs/:id/retry' => sub {
        my ($c) = @_;
        my $id = int($c->param('id'));
        my $j = $q->job_info($id)
            or return $json_err->($c, 404, 'no such job');
        my $ok = $q->retry_job($id, $j->{retries});
        _live_push($st, job => update => $id) if $ok;
        return $ok ? $c->json({ ok => 1 })
                   : $json_err->($c, 409, 'job changed underneath; reload');
    });
    $s->post('/api/jobs/:id/remove' => sub {
        my ($c) = @_;
        my $id = int($c->param('id'));
        my $j = $q->job_info($id)
            or return $json_err->($c, 404, 'no such job');
        my $ok = $q->remove_job($id);
        _live_push($st, job => delete => $id) if $ok;
        return $ok ? $c->json({ ok => 1 })
                   : $json_err->($c, 409,
                       'an active job is refused; retry it first');
    });

    # Bulk: SELECTION-ONLY, never filter-wide. Explicit ids, a hard cap,
    # and a filter expression in the payload is rejected outright - the
    # operator has looked at every row they are acting on, and "retry
    # everything matching" remains excluded on purpose.
    $s->post('/api/jobs/bulk' => sub {
        my ($c) = @_;
        my $body = eval { $c->req->json } // {};
        return $json_err->($c, 400, 'filter payloads are rejected: bulk '
                         . 'is selection-only, send explicit ids')
            if exists $body->{filter} || exists $body->{query}
            || exists $body->{where};
        my $action = $body->{action} // '';
        return $json_err->($c, 400, "unknown bulk action '$action'")
            unless $action =~ /\A(?:retry|remove)\z/;
        my $ids = $body->{ids};
        return $json_err->($c, 400, 'ids must be a non-empty array')
            unless ref $ids eq 'ARRAY' && @$ids;
        return $json_err->($c, 400, 'bulk is capped at 500 ids')
            if @$ids > 500;

        my (%out, $ok, $no);
        for my $id (@$ids) {
            next unless ($id // '') =~ /\A\d+\z/;
            my $did = 0;
            if ($action eq 'retry') {
                my $j = $q->job_info($id);
                $did = $j ? $q->retry_job($id, $j->{retries}) : 0;
            }
            else { $did = $q->remove_job($id) }
            $out{$id} = $did ? 'ok' : 'skipped';
            $did ? $ok++ : $no++;
        }
        _live_push($st, job => refresh => 0);
        return $c->json({ succeeded => $ok // 0, failed => $no // 0,
                          results => \%out });
    });

    $s->post('/api/workers/:id/stop' => sub {
        my ($c) = @_;
        my $id = int($c->param('id'));
        my $n = $q->broadcast('stop', [], [$id]);
        _live_push($st, worker => update => $id) if $n;
        return $n ? $c->json({ ok => 1 })
                  : $json_err->($c, 404, 'no such worker');
    });
    # run now: enqueue the cron's job immediately, ignoring the schedule
    # and NOT advancing next_run - the "fire it while I watch" button
    $s->post('/api/crons/:id/run' => sub {
        my ($c) = @_;
        my $cron = $q->cron_info($c->param('id'))
            or return $json_err->($c, 404, 'no such cron');
        my $id = $q->enqueue($cron->{task}, $cron->{args},
                             queue    => $cron->{queue},
                             priority => $cron->{priority},
                             attempts => $cron->{attempts});
        _live_push($st, job => create => $id);
        return $c->json({ ok => 1, id => $id });
    });
    # the operational pause. Boot reconciliation never resets enabled, so
    # a disable made here survives every deploy; re-enabling recomputes
    # next_run from now (the disabled window behaves as catchup skip).
    for my $flip (['enable', 1], ['disable', 0]) {
        my ($verb, $on) = @$flip;
        $s->post("/api/crons/:id/$verb" => sub {
            my ($c) = @_;
            my $name = $c->param('id');
            return $json_err->($c, 404, 'no such cron')
                unless $q->cron_info($name);
            my $took = $q->enable_cron($name, $on);
            _live_push($st, cron => update => 0) if $took;
            return $c->json({ ok => $took ? 1 : 0 });
        });
    }

    _register_live($st, $s) if $a->{live};
    return;
}

# ---- live mode --------------------------------------------------------------

sub _register_live {
    my ($st, $s) = @_;

    # a websocket route without the Hyperman detach path would croak the
    # whole app at to_app; degrade to polling instead - the UI already
    # treats live as an enhancement
    require Punk::WebSocket;
    unless (Punk::WebSocket::_hm_available()) {
        warn "Punk::Plugin::Queue: admin live mode needs Hyperman's "
           . "detach path; staying on polling\n";
        return;
    }
    $st->{live} = 1;
    $st->{live_conns} = [];

    $s->websocket('/ws' => sub {
        my ($c, $ws) = @_;
        push @{ $st->{live_conns} }, $ws;
        $ws->send(_encode_json({ type => 'connected' }));
        $ws->on(message => sub {
            my ($conn, $text) = @_;
            my $m = eval { File::Raw::JSON::file_json_decode($text) };
            return unless ref $m eq 'HASH';
            $conn->send(_encode_json({ type => 'pong' }))
                if ($m->{type} // '') eq 'ping';
        });
        $ws->on(close => sub {
            my ($conn) = @_;
            @{ $st->{live_conns} } =
                grep { $_ != $conn } @{ $st->{live_conns} };
        });
    });
    return;
}

sub _encode_json {
    require File::Raw::JSON;
    return File::Raw::JSON::file_json_encode($_[0]);
}

# The entity envelope: { type: 'entity_change', entity, action, id }.
# Funky documents Pages.handleDataChange but ships no caller; app.js
# bridges this envelope into it. Actions performed through this app push
# immediately; external changes surface via the 5s stats poll (the boring
# path stays the fallback).
sub _entity_envelope {
    my ($entity, $action, $id) = @_;
    return { type => 'entity_change', entity => $entity,
             action => $action, id => $id };
}

sub _live_push {
    my ($st, $entity, $action, $id) = @_;
    return unless $st->{live} && @{ $st->{live_conns} // [] };
    my $msg = _encode_json(_entity_envelope($entity, $action, $id));
    my @alive;
    for my $ws (@{ $st->{live_conns} }) {
        push @alive, $ws if eval { $ws->send($msg); 1 };
    }
    $st->{live_conns} = \@alive;
    return;
}

# ---- in-server mode ---------------------------------------------------------

sub _register_inserver {
    my ($st) = @_;
    my $is = $st->{opts}{in_server};
    $is = {} unless ref $is;

    # rail 2: a task allowlist, never "all tasks" - boot croak
    Carp::croak("Punk::Plugin::Queue: in_server needs an explicit task "
              . "allowlist - in_server => { tasks => [...] }")
        unless ref $is->{tasks} eq 'ARRAY' && @{ $is->{tasks} };

    my $q = $st->{queue};
    my $attached = 0;

    # to_app runs in the Hyperman parent, before the fork, so there is no
    # loop yet and hm_abi has no post-fork hook: attach lazily, one
    # predictable branch per request
    $st->{app}->hook(before_dispatch => sub {
        return if $attached;
        $attached = 1;
        Punk::Queue::_inserver_attach($q, {
            tasks    => $is->{tasks},
            queues   => $is->{queues} // ['default'],
            interval => $is->{interval} // 1,
            cap      => $is->{cap} // 5,
        }) or warn "Punk::Plugin::Queue: in_server could not attach "
                 . "(no Hyperman loop); jobs will not run in-server\n";
        return;
    });
    return;
}

1;

__END__

=head1 NAME

Punk::Plugin::Queue - Punk::Queue for Punk applications

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::Queue;             # compile time: the keywords

    plugin 'Queue' => {                  # runtime: the configuration
        dsn   => 'dbi:Pg:dbname=myapp',
        admin => { prefix => '/queue', guard => 'Web::Auth#admin' },
    };

    queue 'mail' => { attempts => 5, timeout => 30 };

    task 'mail.send'    => 'Job::Mail#send';
    task 'report.build' => sub {
        my ($job, $year) = @_;
        return { pages => 3 };
    };

    cron '0 3 * * *' => 'Reports#nightly';

    post '/reports' => sub {
        my ($c) = @_;
        return $c->json({ job => $c->enqueue('report.build' => [2026]) });
    };

=head1 DESCRIPTION

One class, two entry points. C<use Punk::Plugin::Queue> at compile time
installs the C<queue>, C<task> and C<cron> keywords into the caller;
C<plugin 'Queue'> at runtime configures the queue, installs the
C<< $c->queue >>, C<< $c->enqueue >> and C<< $c->job >> helpers, and
optionally mounts the admin UI and an in-server worker. C<import> never
registers and never takes configuration, so configuration lives in
exactly one place. C<plugin 'Queue'> also installs the keywords, so
putting the plugin line first works too - but only for
parenthesised calls (C<task(...)>): C<plugin> runs at runtime, so the
bare keyword syntax on later lines still needs the compile-time C<use>.
The SYNOPSIS form is the one to teach.

The keywords are installed through Punk's registrar
(C<< $app->install_kw >>, Punk 0.04), so they are magic CVs in the
application class beside C<get> and C<helper>, and this plugin never
touches its symbol table. C<use Punk> has to come first for that reason:
a class that is not a Punk application has no registrar to install into,
and says so.

Targets resolve like route targets: C<'Job::Mail#send'> is
C<MyApp::Controller::Job::Mail::send>, C<'+Full::Class#method'> escapes
the namespace, and a typo croaks at C<to_app>, not at first dispatch.

=head1 THE ADMIN UI

    plugin 'Queue' => { dsn => ..., admin => {
        prefix    => '/queue',            # default
        guard     => 'Web::Auth#admin',   # REQUIRED
        live      => 1,                   # optional websocket updates
        templates => 'root/queue',        # optional template overrides
        css       => 'root/queue.css',    # optional, appended
        js        => ['root/queue.js'],   # optional, appended
    } };

Native routes under an C<under> scope - never C<mount>, which bypasses
guards, CSRF and hooks. Registration croaks without a guard (set
C<PUNK_QUEUE_ADMIN_INSECURE> to run naked deliberately). With the app's
C<csrf> configured, every admin POST is CSRF-protected; the layout
mirrors the app's csrf cookie into the C<csrf_token> cookie Funky
hardcodes - a script-readable double-submit cookie, so the mirror leaks
nothing.

=head2 How the pages stay current

A 5-second poll, and that is the load-bearing part: every page re-reads
the stats and its own view - its table, or the job it is showing. It has
to be, because a job changes state inside a B<worker> process, which has
no way to reach a socket held by a web process.

C<< live => 1 >> is the enhancement on top. It pushes what this web
process itself did - an enqueue through C<< $c->enqueue >>, a retry, a
remove, a bulk action, a worker stop, a cron run - so those land
immediately instead of on the next tick. Two things it is not: it does
not carry worker-driven transitions (a claim, a finish, a failure, a
backoff coming due, the scheduler firing), and its connection list is
per web-worker process, so with several web workers a push reaches the
browsers connected to that one. The poll covers both, for every client,
which is why it runs whether live mode is on or not.

The UI is built on Funky (our zero-dependency, no-build framework), a
pinned subset vendored under C<assets/> and served from memory -
provenance and the re-vendor procedure live in C<assets/VENDORED.md>.
FontAwesome and Bootstrap are deliberately NOT vendored; a small
override sheet supplies unicode glyphs and minimal structural styles.

=head2 Making it yours

Every page is a L<Template::Stencil> template under
C<assets/templates/>: C<layout.tmpl>, one per page (C<overview>,
C<jobs>, C<job>, C<workers>, C<locks>, C<crons>). Point C<templates> at
a directory of your own and a name is looked up there first, ours
second - so that directory holds only the templates you actually
changed, and the rest keep working across upgrades. Which root serves
which name is decided at registration: a template you meant to override
but misspelled is a boot croak, not a page that silently stays ours.

Every template renders with:

    prefix       where the UI is mounted, e.g. '/queue'
    title        the page title             page      its DOM id
    version      Punk::Queue's version      live      'true' / 'false'
    csrf_cookie  the app's csrf cookie name, or ''
    nav          [ { href, label, id }, ... ] - the pages, in order
    styles       stylesheet URLs to link    scripts   script URLs to load
    id           the job id (the `job` template only)

and the layout additionally gets C<content>, the rendered page, which it
places with C<< {% raw content %} >>. Because C<styles> and C<scripts>
are data, a replacement layout needs no knowledge of where the bundles
live.

C<css> and C<js> take a file or an arrayref of files and append them to
the served C<funky.css> and C<app.js> - at the end, which is what makes
them overrides: the last CSS declaration wins, and a script that runs
after C<app.js> can build on it. They are read once, at registration,
like everything else the UI serves, and they change the bundle's ETag,
so no client can be left holding a cache entry from before the override.

Templates and override files are read at boot. That is the same promise
the rest of a Punk app makes - everything wrong croaks at C<to_app>, and
nothing on the request path touches the disk - and it means a template
edit needs a restart.

Bulk actions are selection-only, by explicit ids, capped at 500; a
filter expression in the payload is rejected. "Retry everything
matching" stays excluded on purpose - the CLI can loop if you mean it.

=head1 IN-SERVER MODE

    plugin 'Queue' => { dsn => ..., in_server => {
        tasks    => ['mail.send'],     # REQUIRED allowlist
        queues   => ['default'],
        interval => 1,
        cap      => 5,
    } };

Runs jobs on the Hyperman web workers' own loops. For low-volume,
IO-bound, latency-tolerant work; run C<punk-queue worker> for anything
real. Off by default and railed: a required task allowlist, one job in
flight per web worker, claims only from a timer (never the request
path), a wall-clock cap (default 5s) enforced by a loop timer failing a
returned future, and two cap breaches disable the mode in that process
with an error log. Claims attach lazily on the first request of each
worker process - C<to_app> runs before the fork, and hm_abi has no
post-fork hook (an C<on_worker_start> entry would be cleaner, and is
explicitly not required).

=head1 METHODS

=head2 import

Installs the keywords into the caller. Nothing else.

=head2 new / register($app, \%opts)

The L<Punk> plugin contract. Options: C<dsn>/C<user>/C<password> (or the
app's C<database> keyword), C<auto_migrate>, C<admin>, C<in_server>,
plus the queue tuning knobs (C<attempts_delay>, C<max_backoff>,
C<missing_after>, C<remove_after>).

=head2 state_for($class)

The plugin's recorded state for an app class. Introspection and tests.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
